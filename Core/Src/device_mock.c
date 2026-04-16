/*
 * device_mock.c
 *
 *  Created on: Dec 31, 2025
 *      Author: AI Assistant
 *
 *  Mock device implementation for testing
 *  - Only compiled when USE_MOCK_DEVICE is enabled
 *  - Returns simulated data for all App_* operations
 *  - Uses same App_* interface as device_real.c
 */

#include "main.h"

#ifdef USE_MOCK_DEVICE

#include "device_hal.h"
#include <string.h>
#include <stdio.h>

/*******************************************************************************
 * Mock File System Data (with tree structure)
 ******************************************************************************/

/**
 * Mock file entries with tree structure.
 * - depth: 0 = root, 1 = first level subfolder, 2 = second level
 * - parent_index: index of parent folder, -1 for root items
 *
 * IMPORTANT: Parents must appear before their children in the array!
 */
static const struct {
    const char *name;
    const char *path;
    bool is_directory;
    uint32_t size;
    uint8_t depth;
    int16_t parent_index;
} mock_files[] = {
    {"Error", "Error", true, 0, 0, -1},
    {"err_lv.ini", "Error/err_lv.ini", false, 20, 1, 0},
    {"ERR_LVF.TXT", "Error/ERR_LVF.TXT", false, 28, 1, 0},
    {"note.ini", "Error/note.ini", false, 18, 1, 0},

    {"Log", "Log", true, 0, 0, -1},
    {"BOOT.TXT", "Log/BOOT.TXT", false, 11, 1, 4},
    {"ERROR.TXT", "Log/ERROR.TXT", false, 12, 1, 4},
    {"INSP.TXT", "Log/INSP.TXT", false, 17, 1, 4},
    {"SENSOR.TXT", "Log/SENSOR.TXT", false, 13, 1, 4},

    {"Media", "Media", true, 0, 0, -1},
    {"MT_2.CSV", "Media/MT_2.CSV", false, 20, 1, 9},
    {"MT_3.CSV", "Media/MT_3.CSV", false, 20, 1, 9},
    {"MT_4.CSV", "Media/MT_4.CSV", false, 20, 1, 9},
    {"MT_5.CSV", "Media/MT_5.CSV", false, 20, 1, 9},
    {"MT_6.CSV", "Media/MT_6.CSV", false, 20, 1, 9},
    {"MT_ALL.CSV", "Media/MT_ALL.CSV", false, 20, 1, 9},

    {"Midi", "Midi", true, 0, 0, -1},
    {"motor", "Midi/motor", true, 0, 1, 16},
    {"placeholder.txt", "Midi/motor/placeholder.txt", false, 0, 2, 17},
    {"page", "Midi/page", true, 0, 1, 16},
    {"placeholder.txt", "Midi/page/placeholder.txt", false, 0, 2, 19},

    {"Setting", "Setting", true, 0, 0, -1},
    {"DI_ID.TXT", "Setting/DI_ID.TXT", false, 10, 1, 21},
    {"MT_AT.TXT", "Setting/MT_AT.TXT", false, 9, 1, 21},
    {"MT_ATT.TXT", "Setting/MT_ATT.TXT", false, 9, 1, 21},
    {"MT_CT.TXT", "Setting/MT_CT.TXT", false, 9, 1, 21},
    {"MT_EL.TXT", "Setting/MT_EL.TXT", false, 9, 1, 21},
    {"MT_LI.TXT", "Setting/MT_LI.TXT", false, 9, 1, 21},
    {"MT_LK.TXT", "Setting/MT_LK.TXT", false, 9, 1, 21},
    {"MT_MD.TXT", "Setting/MT_MD.TXT", false, 9, 1, 21},
    {"MT_MS.TXT", "Setting/MT_MS.TXT", false, 9, 1, 21},
    {"MT_PL.TXT", "Setting/MT_PL.TXT", false, 9, 1, 21},
    {"MT_RP.TXT", "Setting/MT_RP.TXT", false, 10, 1, 21},
    {"MT_ST.TXT", "Setting/MT_ST.TXT", false, 10, 1, 21},
    {"RE_TI.TXT", "Setting/RE_TI.TXT", false, 10, 1, 21},
};

#define MOCK_FILE_COUNT (sizeof(mock_files) / sizeof(mock_files[0]))

/*******************************************************************************
 * Mock Motor Data
 ******************************************************************************/

static struct {
    uint8_t id;
    uint8_t group_id;
    uint8_t sub_id;
    AppMotorType type;
    AppMotorStatus status;
    int32_t position;
    float velocity;
    float min_angle;
    float max_angle;
    int32_t min_raw;
    int32_t max_raw;
} mock_motors[] = {
    {1, 1, 1, APP_MOTOR_TYPE_SERVO, APP_MOTOR_STATUS_NORMAL, 2048, 0.5f, 0.0f, 180.0f, 0, 3072},
    {2, 1, 2, APP_MOTOR_TYPE_DC, APP_MOTOR_STATUS_ERROR, 1536, 1.0f, -90.0f, 90.0f, 0, 4095},
    {3, 2, 1, APP_MOTOR_TYPE_STEPPER, APP_MOTOR_STATUS_NORMAL, 1024, 0.2f, 0.0f, 360.0f, 0, 4095},
};

#define MOCK_MOTOR_COUNT (sizeof(mock_motors) / sizeof(mock_motors[0]))

static uint32_t mock_state_counter = 0;

/*******************************************************************************
 * Mock App_* Implementations
 ******************************************************************************/

bool App_Ping(void) {
    return true;
}

bool App_Move(uint8_t motor_id, int32_t raw_pos) {
    for (size_t i = 0; i < MOCK_MOTOR_COUNT; i++) {
        if (mock_motors[i].id != motor_id) {
            continue;
        }

        if (raw_pos < mock_motors[i].min_raw || raw_pos > mock_motors[i].max_raw) {
            return false;
        }

        mock_motors[i].position = raw_pos;
        return true;
    }

    return false;
}

bool App_MotionPlay(uint8_t device_id) {
    (void)device_id;
    return true;
}

bool App_MotionStop(uint8_t device_id) {
    (void)device_id;
    return true;
}

bool App_MotionPause(uint8_t device_id) {
    (void)device_id;
    return true;
}

bool App_MotionSeek(uint8_t device_id, uint32_t time_ms) {
    (void)device_id;
    (void)time_ms;
    return true;
}

int App_GetFiles(AppFileInfo *out_files, uint16_t max_count) {
    if (out_files == NULL) {
        return -1;
    }

    uint16_t count = 0;
    for (size_t i = 0; i < MOCK_FILE_COUNT && count < max_count; i++) {
        strncpy(out_files[count].name, mock_files[i].name, APP_NAME_MAX_LEN - 1);
        out_files[count].name[APP_NAME_MAX_LEN - 1] = '\0';

        strncpy(out_files[count].path, mock_files[i].path, APP_PATH_MAX_LEN - 1);
        out_files[count].path[APP_PATH_MAX_LEN - 1] = '\0';

        out_files[count].is_directory = mock_files[i].is_directory;
        out_files[count].size = mock_files[i].size;
        out_files[count].depth = mock_files[i].depth;
        out_files[count].parent_index = mock_files[i].parent_index;
        count++;
    }

    return (int)count;
}

bool App_GetFile(const char *path, char *out_content, uint16_t max_len) {
    if (path == NULL || out_content == NULL || max_len == 0) {
        return false;
    }

    snprintf(out_content, max_len, "Mock content for file: %s", path);
    return true;
}

bool App_SaveFile(const char *path, const char *content) {
    if (path == NULL || content == NULL) {
        return false;
    }

    (void)path;
    (void)content;
    return true;
}

bool App_VerifyFile(const char *path, const char *content, bool *out_match) {
    if (path == NULL || content == NULL || out_match == NULL) {
        return false;
    }

    *out_match = true;
    return true;
}

int App_GetMotors(AppMotorInfo *out_motors, uint16_t max_count) {
    if (out_motors == NULL) {
        return -1;
    }

    uint16_t count = 0;
    for (size_t i = 0; i < MOCK_MOTOR_COUNT && count < max_count; i++) {
        out_motors[count].id = mock_motors[i].id;
        out_motors[count].group_id = mock_motors[i].group_id;
        out_motors[count].sub_id = mock_motors[i].sub_id;
        out_motors[count].type = mock_motors[i].type;
        out_motors[count].status = mock_motors[i].status;
        out_motors[count].position = mock_motors[i].position;
        out_motors[count].velocity = mock_motors[i].velocity;
        out_motors[count].min_angle = mock_motors[i].min_angle;
        out_motors[count].max_angle = mock_motors[i].max_angle;
        out_motors[count].min_raw = mock_motors[i].min_raw;
        out_motors[count].max_raw = mock_motors[i].max_raw;
        count++;
    }

    return (int)count;
}

int App_GetMotorState(AppMotorState *out_states, uint16_t max_count) {
    if (out_states == NULL) {
        return -1;
    }

    mock_state_counter++;

    uint16_t count = 0;
    for (size_t i = 0; i < MOCK_MOTOR_COUNT && count < max_count; i++) {
        int32_t offset = (int32_t)((mock_state_counter + i * 7U) % 11U) - 5;
        int32_t next_position = mock_motors[i].position + offset;

        if (next_position < mock_motors[i].min_raw) {
            next_position = mock_motors[i].min_raw;
        } else if (next_position > mock_motors[i].max_raw) {
            next_position = mock_motors[i].max_raw;
        }

        out_states[count].id = mock_motors[i].id;
        out_states[count].status = mock_motors[i].status;
        out_states[count].position = next_position;
        out_states[count].velocity = mock_motors[i].velocity
                                   + (float)((mock_state_counter + i * 3U) % 5U) * 0.1f;
        count++;
    }

    return (int)count;
}

#endif /* USE_MOCK_DEVICE */
