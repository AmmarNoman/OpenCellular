#!/bin/bash

# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

. "$(dirname "$0")/common.sh"

set -e

# Print usage string
usage() {
  cat <<EOF
Usage: $PROG /path/to/cros_root_fs/dir /path/to/keys/dir

Re-sign framework apks in an Android system image.  The image itself does not
need to be signed since it is shipped with Chrome OS image, which is already
signed.

Android has many "framework apks" that are signed with 4 different framework
keys, depends on the purpose of the apk.  During development, apks are signed
with the debug one.  This script is to re-sign those apks with corresponding
release key.  It also handles some of the consequences of the key changes, such
as sepolicy update.

EOF
  if [[ $# -gt 0 ]]; then
    error "$*"
    exit 1
  fi
  exit 0
}

# Return name according to the current signing debug key.  The name is used to
# select key files.
choose_key() {
  local apk="$1"

  local sha1=$(unzip -p "${apk}" META-INF/CERT.RSA | \
      keytool -printcert | awk '/^\s*SHA1:/ {print $2}')

  # Fingerprints below are generated by:
  # $ keytool -file vendor/google/certs/cheetskeys/$NAME.x509.pem -printcert \
  #     | grep SHA1:
  case "${sha1}" in
    "AA:04:E0:5F:82:9C:7E:D1:B9:F8:FC:99:6C:5A:54:43:83:D9:F5:BC")
      echo "platform"
      ;;
    "D4:C4:2D:E0:B9:1B:15:72:FA:7D:A7:21:E0:A6:09:94:B4:4C:B5:AE")
      echo "media"
      ;;
    "38:B6:2C:E1:75:98:E3:E1:1C:CC:F6:6B:83:BB:97:0E:2D:40:6C:AE")
      echo "shared"
      ;;
    "EC:63:36:20:23:B7:CB:66:18:70:D3:39:3C:A9:AE:7E:EF:A9:32:42")
      # The above fingerprint is from devkey.  Translate to releasekey.
      echo "releasekey"
      ;;
    *)
      # Not a framework apk.  Do not re-sign.
      echo ""
      ;;
  esac
}

# Re-sign framework apks with the corresponding release keys.  Only apk with
# known key fingerprint are re-signed.  We should not re-sign non-framework
# apks.
sign_framework_apks() {
  local system_mnt="$1"
  local key_dir="$2"

  info "Start signing framework apks"

  # Counters for sanity check.
  local counter_platform=0
  local counter_media=0
  local counter_shared=0
  local counter_releasekey=0
  local counter_total=0

  local apk
  while read -d $'\0' -r apk; do
    local keyname=$(choose_key "${apk}")
    if [[ -z "${keyname}" ]]; then
      continue
    fi

    info "Re-signing (${keyname}) ${apk}"

    local temp_dir="$(make_temp_dir)"
    local temp_apk="${temp_dir}/temp.apk"
    local signed_apk="${temp_dir}/signed.apk"
    local aligned_apk="${temp_dir}/aligned.apk"

    # Follow the standard manual signing process.  See
    # https://developer.android.com/studio/publish/app-signing.html.
    cp -a "${apk}" "${temp_apk}"
    # Explicitly remove existing signature.
    zip -q "${temp_apk}" -d "META-INF/*"
    signapk "${key_dir}/$keyname.x509.pem" "${key_dir}/$keyname.pk8" \
        "${temp_apk}" "${signed_apk}" > /dev/null
    zipalign 4 "${signed_apk}" "${aligned_apk}"

    # Copy the content instead of mv to avoid owner/mode changes.
    sudo cp "${aligned_apk}" "${apk}" && rm -f "${aligned_apk}"

    : $(( counter_${keyname} += 1 ))
    : $(( counter_total += 1 ))
  done < <(find "${system_mnt}/system" -type f -name '*.apk' -print0)

  # Sanity check.
  if [[ ${counter_platform} -lt 2 || ${counter_media} -lt 2 ||
        ${counter_shared} -lt 2 || ${counter_releasekey} -lt 2 ||
        ${counter_total} -lt 25 ]]; then
    die "Number of re-signed package seems to be wrong"
  fi
}

# Platform key is part of the SELinux policy.  Since we are re-signing framework
# apks, we need to replace the key in the policy as well.
update_sepolicy() {
  local system_mnt=$1
  local key_dir=$2

  # Only platform is used at this time.
  local public_platform_key="${key_dir}/platform.x509.pem"

  info "Start updating sepolicy"

  local new_cert=$(sed -E '/(BEGIN|END) CERTIFICATE/d' \
    "${public_platform_key}" | tr -d '\n' \
    | base64 --decode | hexdump -v -e '/1 "%02x"')

  if [[ -z "${new_cert}" ]]; then
    die "Unable to get the public platform key"
  fi

  local orig=$(make_temp_file)
  local xml="${system_mnt}/system/etc/security/mac_permissions.xml"
  local pattern='(<signer signature=")\w+("><seinfo value="platform)'
  cp "${xml}" "${orig}"
  sudo sed -i -E "s/${pattern}/\1${new_cert}"'\2/g' "${xml}"

  # Sanity check.
  if cmp "${xml}" "${orig}"; then
    die "Failed to replace SELinux policy cert"
  fi
}

# Replace the debug key in OTA cert with release key.
replace_ota_cert() {
  local system_mnt=$1
  local release_cert=$2
  local ota_zip="${system_mnt}/system/etc/security/otacerts.zip"

  info "Replacing OTA cert"

  local temp_dir=$(make_temp_dir)
  pushd "${temp_dir}" > /dev/null
  cp "${release_cert}" .
  local temp_zip=$(make_temp_file)
  zip -q -r "${temp_zip}.zip" .
  # Copy the content instead of mv to avoid owner/mode changes.
  sudo cp "${temp_zip}.zip" "${ota_zip}"
  popd > /dev/null
}

# Restore SELinux context.  This has to run after all file changes, before
# creating the new squashfs image.
reapply_file_security_context() {
  local system_mnt=$1
  local root_fs_dir=$2

  info "Reapplying file security context"

  sudo /sbin/setfiles -v -r "${system_mnt}" \
      "${root_fs_dir}/etc/selinux/arc/contexts/files/android_file_contexts" \
      "${system_mnt}"
}

# Snapshot file properties in a directory recursively.
snapshot_file_properties() {
  local dir=$1
  sudo find "${dir}" -exec stat -c '%n:%u:%g:%a:%C' {} + | sort
}

main() {
  local root_fs_dir=$1
  local key_dir=$2
  local android_dir="${root_fs_dir}/opt/google/containers/android"
  local system_img="${android_dir}/system.raw.img"

  if [[ $# -ne 2 ]]; then
    usage "command takes exactly 2 args"
  fi

  if [[ ! -f "${system_img}" ]]; then
    die "System image does not exist: ${system_img}"
  fi

  local working_dir=$(make_temp_dir)
  local system_mnt="${working_dir}/mnt"

  info "Unpacking sqaushfs image to ${system_img}"
  sudo unsquashfs -f -no-progress -d "${system_mnt}" "${system_img}"

  snapshot_file_properties "${system_mnt}" > "${working_dir}/properties.orig"

  sign_framework_apks "${system_mnt}" "${key_dir}"
  update_sepolicy "${system_mnt}" "${key_dir}"
  replace_ota_cert "${system_mnt}" "${key_dir}/releasekey.x509.pem"
  reapply_file_security_context "${system_mnt}" "${root_fs_dir}"

  # Sanity check.
  snapshot_file_properties "${system_mnt}" > "${working_dir}/properties.new"
  local d
  if ! d=$(diff "${working_dir}"/properties.{orig,new}); then
    die "Unexpected change of file property, diff\n${d}"
  fi

  info "Repacking sqaushfs image"
  local old_size=$(stat -c '%s' "${system_img}")
  # Overwrite the original image.
  sudo mksquashfs "${system_mnt}" "${system_img}" -no-progress -comp lzo -noappend
  local new_size=$(stat -c '%s' "${system_img}")
  info "Android system image size change: ${old_size} -> ${new_size}"
}

main "$@"
