/*
 * This file is part of the coreboot project.
 *
 * Copyright (C) 2014 Google, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */
#ifndef VBOOT_COMMON_H
#define VBOOT_COMMON_H

#include <commonlib/region.h>
#include <stdint.h>
#include <vboot_api.h>
#include <vboot_struct.h>

#include "chromeos.h"

/* Locate vboot area by name. Returns 0 on success and -1 on error. */
int vboot_named_region_device(const char *name, struct region_device *rdev);

/* ========================== VBOOT HANDOFF APIs =========================== */
/*
 * The vboot_handoff structure contains the data to be consumed by downstream
 * firmware after firmware selection has been completed. Namely it provides
 * vboot shared data as well as the flags from VbInit.
 */
struct vboot_handoff {
	VbInitParams init_params;
	uint32_t selected_firmware;
	char shared_data[VB_SHARED_DATA_MIN_SIZE];
} __attribute__((packed));

/*
 * vboot_get_handoff_info returns pointer to the vboot_handoff structure if
 * available. vboot_handoff is available only after CBMEM comes online. If size
 * is not NULL, size of the vboot_handoff structure is returned in it.
 * Returns 0 on success and -1 on error.
 */
int vboot_get_handoff_info(void **addr, uint32_t *size);

/*
 * The following functions read vboot_handoff structure to obtain requested
 * information. If vboot handoff is not available, 0 is returned by default.
 * If vboot handoff is available:
 * Returns 1 for flag if true
 * Returns 0 for flag if false
 * Returns value read for other fields
 */
int vboot_handoff_skip_display_init(void);
int vboot_handoff_check_recovery_flag(void);
int vboot_handoff_check_developer_flag(void);
int vboot_handoff_get_recovery_reason(void);

/* ============================ VBOOT REBOOT ============================== */
/*
 * vboot_reboot handles the reboot requests made by vboot_reference library. It
 * allows the platform to run any preparation steps before the reboot and then
 * does a hard reset.
 */
void vboot_reboot(void);

/* Allow the platform to do any clean up work when vboot requests a reboot. */
void vboot_platform_prepare_reboot(void);

/* ============================ VBOOT RESUME ============================== */
/*
 * Save the provided hash digest to a secure location to check against in
 * the resume path. Returns 0 on success, < 0 on error.
 */
int vboot_save_hash(void *digest, size_t digest_size);

/*
 * Retrieve the previously saved hash digest.  Returns 0 on success,
 * < 0 on error.
 */
int vboot_retrieve_hash(void *digest, size_t digest_size);

/*
 * Determine if the platform is resuming from suspend. Returns 0 when
 * not resuming, > 0 if resuming, and < 0 on error.
 */
int vboot_platform_is_resuming(void);

/* ============================= VERSTAGE ================================== */
/*
 * Main logic for verified boot. verstage() is the stage entry point
 * while the verstage_main() is just the core logic.
 */
void verstage_main(void);
void verstage(void);
void verstage_mainboard_init(void);

#endif /* VBOOT_COMMON_H */
