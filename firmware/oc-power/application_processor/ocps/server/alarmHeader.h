/*
 * alarmHeader.h
 *
 *  Created on: Aug 3, 2018
 *      Author: vthakur
 */

#ifndef alarm_header
#define alarm_header
//#include "alert_enum.pb.h"
#define MAX_ALERT_BYTES 12
typedef enum {
	unknown = 0,
	pvOverVoltageWarning = 1,
	pvUnderVoltageWarning = 2,
	pvOverVoltageFault = 3,
	pvUnderVoltageFault = 4,
	adapterOverVoltageWarning = 5,
	adapterUnderVoltageWarning = 6,
	adapterOverCurrentWarning = 7,
	adapterOverVoltageFault = 8,
	adapterUnderVoltageFault = 9,
	adapterOverCurrentFault = 10,
	batteryOverVoltageWarning = 11,
	batteryUnderVoltageWarning = 12,
	batteryOverCurrentWarning = 13,
	batteryOverPowerWarning = 14,
	batteryOverVoltageFault = 15,
	batteryUnderVoltageFault = 16,
	batteryOverCurrentFault = 17,
	batteryOverPowerFault = 18,
	outputVoltage24vOverVoltageWarning = 19,
	outputVoltage24vUnderVoltageWarning = 20,
	outputVoltage24vOverCurrentWarning = 21,
	outputVoltage24vOverVoltageFault = 22,
	outputVoltage24vUnderVoltageFault = 23,
	outputVoltage24vOverCurrentFault = 24,
	outputVoltage24vShortCircuitFault = 25,
	outputVoltage12vOverVoltageWarning = 26,
	outputVoltage12vUnderVoltageWarning = 27,
	outputVoltage12vOverCurrentWarning = 28,
	outputVoltage12vOverVoltageFault = 29,
	outputVoltage12vUnderVoltageFault = 30,
	outputVoltage12vOverCurrentFault = 31,
	outputVoltage12vShortCircuitFault = 32,
	primaryOverTempWarning = 33,
	primaryOverTempFault = 34,
	ambientTempOverTempWarning = 35,
	ambientTempOverTempFault = 36,
	battChargeWarning = 37,
	battDischargeWarning = 38,
	battOverChargingCurrentWarning = 39,
	battOverDischargeCurrentWarning	= 40,
	battUnderVoltageWarning = 41,
	battRemainingCapacityWarning = 42,
	battCellOverVoltageWarning = 43,
	battCellUnbalanceWarning = 44,
	battCellOverTempForChargeWarning = 45,
	battCellUnderTempForChargeWarning = 46,
	battCellOverTempForDischargeWarning = 47,
	battCellUnderTempForDischargeWarning = 48,
	battFETOverHeatWarning = 49,
	battPCBOverHeatWarning = 50,
	battTerminateChargeProtection = 51,
	battTerminateDischargeProtection = 52,
	battCellOverVoltageProtection = 53,
	battOverTotalVoltageProtection = 54,
	battUnderTotalVoltageProtection = 55,
	battDischargeCutOffProtection = 56,
	battOverChargeCurrentSwProtection = 57,
	battOverDischargeCurrentSwProtection = 58,
	battOverDischargeCurrentHwProtection = 59,
	battCellOverTempChargeProtection = 60,
	battCellUnderTempChargeProtection = 61,
	battCellOverTempDischargeProtection = 62,
	battCellUnderTempDischargeProtection = 63,
	battFETOverHeatProtection = 64,
	battPCBOverHeatProtection = 65,
	battOverVoltageSwError = 66,
	battOverVoltageHwError = 67,
	battLowVoltageError = 68,
	battCellUnbalanceError = 69,
	battChargeFETError = 70,
	battDischargeFETError = 71,
	battCurrentFuseError = 72,
	battShortCircuitError = 73,
	battCellOverHeatError = 74,
	battThermistorError = 75,
	battAFECommunicationError = 76,
	battCalibrationDataError = 77,
	battFirmwareChecksumError = 78,
	battPCBSystemError = 79,
	battCellPermanentFailure = 80,
	battPermanentFailure = 81,
    MAX_NUMBER_ALERTS = 82 /*make sure this is last enum*/
} AlertId;

//typedef Alert AlertId;

typedef struct {
	uint8_t bit1 : 1;
	uint8_t bit2 : 1;
	uint8_t bit3 : 1;
	uint8_t bit4 : 1;
	uint8_t bit5 : 1;
	uint8_t bit6 : 1;
	uint8_t bit7 : 1;
	uint8_t bit8 : 1;
} Bits;

typedef union {
	Bits bits;
	uint8_t alarmWord;
}AlarmData;

#endif