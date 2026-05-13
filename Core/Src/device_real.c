/*
 * device_real.c
 *
 *  Created on: 2026
 *      Author: Generated
 *
 *  Application Hardware Abstraction Layer - Real Implementation Stubs
 *  - All App_* functions are declared as __weak so they can be overridden
 *  - These are default implementations that return safe values
 *  - Developers should override these functions in their own files
 */

#include "device_hal.h"
#include "main.h"

#define POWER_ACTION_OFF_VALUE     0x00u
#define POWER_ACTION_ON_VALUE      0x01u
#define POWER_ACTION_REBOOT_VALUE  0x02u
#define POWER_REBOOT_DELAY_MS      500u

static uint8_t g_power_status = POWER_ACTION_OFF_VALUE;

/*******************************************************************************
 * Basic Commands
 ******************************************************************************/

bool __attribute__((weak)) App_Ping(void) {
    return true;
}

bool __attribute__((weak)) App_SetHostDateTime(const AppHostDateTime *host_time) {
    (void)host_time;
    return true;
}

bool __attribute__((weak)) App_GetPingStatus(AppPingStatus *out_status) {
    if (out_status == NULL) {
        return false;
    }

    out_status->state = APP_PING_STATE_STOPPED;
    out_status->init_state = 0u;
    out_status->current_ms = 0u;
    out_status->total_ms = 0u;
    out_status->power_status = g_power_status;
    return true;
}

bool __attribute__((weak)) App_Move(uint8_t motor_id, int32_t raw_pos) {
    (void)motor_id;
    (void)raw_pos;
    return false;
}

/*******************************************************************************
 * Motion Control Commands
 ******************************************************************************/

bool __attribute__((weak)) App_MotionPlay(uint8_t device_id) {
    (void)device_id;
    return false;
}

bool __attribute__((weak)) App_MotionStop(uint8_t device_id) {
    (void)device_id;
    return false;
}

bool __attribute__((weak)) App_MotionPause(uint8_t device_id) {
    (void)device_id;
    return false;
}

bool __attribute__((weak)) App_MotionSeek(uint8_t device_id, uint32_t time_ms) {
    (void)device_id;
    (void)time_ms;
    return false;
}

/*******************************************************************************
 * Power Control Commands
 ******************************************************************************/

void __attribute__((weak)) power_output_off(void) {
    HAL_GPIO_WritePin(LD_PWERCTR_GPIO_Port, LD_PWERCTR_Pin, GPIO_PIN_RESET);
    g_power_status = POWER_ACTION_OFF_VALUE;
}

void __attribute__((weak)) power_output_on(void) {
    HAL_GPIO_WritePin(LD_PWERCTR_GPIO_Port, LD_PWERCTR_Pin, GPIO_PIN_SET);
    g_power_status = POWER_ACTION_ON_VALUE;
}

bool __attribute__((weak)) App_PowerControl(uint8_t action) {
    switch (action) {
        case POWER_ACTION_OFF_VALUE:
            power_output_off();
            return true;

        case POWER_ACTION_ON_VALUE:
            power_output_on();
            return true;

        case POWER_ACTION_REBOOT_VALUE:
            power_output_off();
            HAL_Delay(POWER_REBOOT_DELAY_MS);
            power_output_on();
            return true;

        default:
            return false;
    }
}

/*******************************************************************************
 * File System Commands
 ******************************************************************************/

int __attribute__((weak)) App_GetFiles(AppFileInfo *out_files, uint16_t max_count) {
    (void)out_files;
    (void)max_count;
    return 0;
}

bool __attribute__((weak)) App_GetFile(const char *path, char *out_content, uint16_t max_len) {
    (void)path;
    (void)out_content;
    (void)max_len;
    return false;
}

bool __attribute__((weak)) App_SaveFile(const char *path, const char *content) {
    (void)path;
    (void)content;
    return false;
}

bool __attribute__((weak)) App_VerifyFile(const char *path, const char *content, bool *out_match) {
    (void)path;
    (void)content;
    (void)out_match;
    return false;
}

/*******************************************************************************
 * Motor Commands
 ******************************************************************************/

int __attribute__((weak)) App_GetMotors(AppMotorInfo *out_motors, uint16_t max_count) {
    (void)out_motors;
    (void)max_count;
    return 0;
}

int __attribute__((weak)) App_GetMotorState(AppMotorState *out_states, uint16_t max_count) {
    (void)out_states;
    (void)max_count;
    return 0;
}
