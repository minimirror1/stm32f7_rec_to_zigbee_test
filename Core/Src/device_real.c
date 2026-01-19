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
 *
 *  ============================================================================
 *  DESIGN PRINCIPLE:
 *  ============================================================================
 *  - App_* functions handle PURE APPLICATION LOGIC only
 *  - NO communication parsing or response formatting in App_* functions
 *  - Communication layer (json_com.c) handles all JSON parsing/response building
 *  ============================================================================
 */

#include "device_hal.h"
#include <stdbool.h>
#include <string.h>

/*******************************************************************************
 * Basic Commands
 ******************************************************************************/

/**
 * @brief Ping check - verify device is responsive
 * @return true if device is ready, false otherwise
 *
 * Default implementation: Always returns true (device is alive)
 *
 * @example Override in your code:
 *   bool App_Ping(void) {
 *       // Check system health, sensors, etc.
 *       return System_IsHealthy();
 *   }
 */
bool __attribute__((weak)) App_Ping(void) {
    return true;  // Device is alive
}

/**
 * @brief Execute move command
 * @param device_id Target device ID
 * @return true on success, false on failure
 *
 * Default implementation: Not implemented (returns false)
 *
 * @example Override in your code:
 *   bool App_Move(uint8_t device_id) {
 *       Motor_MoveToPosition(device_id, 100);
 *       return true;
 *   }
 */
bool __attribute__((weak)) App_Move(uint8_t device_id) {
    (void)device_id;  // Suppress unused parameter warning
    return false;  // Not implemented
}

/*******************************************************************************
 * Motion Control Commands
 ******************************************************************************/

/**
 * @brief Start motion sequence
 * @param device_id Target device ID
 * @return true on success, false on failure
 *
 * Default implementation: Not implemented (returns false)
 */
bool __attribute__((weak)) App_MotionStart(uint8_t device_id) {
    (void)device_id;
    return false;  // Not implemented
}

/**
 * @brief Stop motion sequence
 * @param device_id Target device ID
 * @return true on success, false on failure
 *
 * Default implementation: Not implemented (returns false)
 */
bool __attribute__((weak)) App_MotionStop(uint8_t device_id) {
    (void)device_id;
    return false;  // Not implemented
}

/**
 * @brief Pause motion sequence
 * @param device_id Target device ID
 * @return true on success, false on failure
 *
 * Default implementation: Not implemented (returns false)
 */
bool __attribute__((weak)) App_MotionPause(uint8_t device_id) {
    (void)device_id;
    return false;  // Not implemented
}

/*******************************************************************************
 * File System Commands
 ******************************************************************************/

/**
 * @brief Get file/folder list from storage
 * @param out_files Output array of file info structures
 * @param max_count Maximum number of files to return
 * @return Number of files (>= 0) on success, -1 on failure
 *
 * Default implementation: Returns 0 (empty list)
 *
 * @example Override in your code:
 *   int App_GetFiles(AppFileInfo *out_files, uint16_t max_count) {
 *       int count = 0;
 *       // Read SD card directory...
 *       strcpy(out_files[count].name, "config.txt");
 *       strcpy(out_files[count].path, "Setting/config.txt");
 *       out_files[count].is_directory = false;
 *       out_files[count].size = 128;
 *       out_files[count].depth = 1;
 *       out_files[count].parent_index = 0;  // Parent is "Setting" folder
 *       count++;
 *       return count;
 *   }
 */
int __attribute__((weak)) App_GetFiles(AppFileInfo *out_files, uint16_t max_count) {
    (void)out_files;
    (void)max_count;
    return 0;  // Empty list (not implemented)
}

/**
 * @brief Read file content
 * @param path File path to read
 * @param out_content Output buffer for file content
 * @param max_len Maximum buffer size
 * @return true on success, false on failure
 *
 * Default implementation: Not implemented (returns false)
 *
 * @example Override in your code:
 *   bool App_GetFile(const char *path, char *out_content, uint16_t max_len) {
 *       return SD_ReadFile(path, out_content, max_len) == 0;
 *   }
 */
bool __attribute__((weak)) App_GetFile(const char *path, char *out_content, uint16_t max_len) {
    (void)path;
    (void)out_content;
    (void)max_len;
    return false;  // Not implemented
}

/**
 * @brief Save content to file
 * @param path File path to write
 * @param content Content to write
 * @return true on success, false on failure
 *
 * Default implementation: Not implemented (returns false)
 *
 * @example Override in your code:
 *   bool App_SaveFile(const char *path, const char *content) {
 *       return SD_WriteFile(path, content) == 0;
 *   }
 */
bool __attribute__((weak)) App_SaveFile(const char *path, const char *content) {
    (void)path;
    (void)content;
    return false;  // Not implemented
}

/**
 * @brief Verify file content matches expected content
 * @param path File path to verify
 * @param content Expected content
 * @param out_match Output: true if content matches, false otherwise
 * @return true on success (verification performed), false on failure (couldn't read file)
 *
 * Default implementation: Not implemented (returns false)
 *
 * @example Override in your code:
 *   bool App_VerifyFile(const char *path, const char *content, bool *out_match) {
 *       char buffer[512];
 *       if (SD_ReadFile(path, buffer, sizeof(buffer)) != 0) {
 *           return false;  // Couldn't read file
 *       }
 *       *out_match = (strcmp(buffer, content) == 0);
 *       return true;
 *   }
 */
bool __attribute__((weak)) App_VerifyFile(const char *path, const char *content, bool *out_match) {
    (void)path;
    (void)content;
    (void)out_match;
    return false;  // Not implemented
}

/*******************************************************************************
 * Motor Commands
 ******************************************************************************/

/**
 * @brief Get list of all motors with full information
 * @param out_motors Output array of motor info structures
 * @param max_count Maximum number of motors to return
 * @return Number of motors (>= 0) on success, -1 on failure
 *
 * Default implementation: Returns 0 (no motors)
 *
 * @example Override in your code:
 *   int App_GetMotors(AppMotorInfo *out_motors, uint16_t max_count) {
 *       int idx = 0;
 *       if (idx < max_count) {
 *           out_motors[idx].id = 1;
 *           out_motors[idx].group_id = 1;
 *           out_motors[idx].sub_id = 1;
 *           strcpy(out_motors[idx].type, "Servo");
 *           strcpy(out_motors[idx].status, "Normal");
 *           out_motors[idx].position = 90.0f;
 *           out_motors[idx].velocity = 0.5f;
 *           idx++;
 *       }
 *       return idx;
 *   }
 */
int __attribute__((weak)) App_GetMotors(AppMotorInfo *out_motors, uint16_t max_count) {
    (void)out_motors;
    (void)max_count;
    return 0;  // No motors (not implemented)
}

/**
 * @brief Get current state of all motors (for polling)
 * @param out_states Output array of motor state structures
 * @param max_count Maximum number of motors to return
 * @return Number of motors (>= 0) on success, -1 on failure
 *
 * Default implementation: Returns 0 (no motors)
 *
 * @note This function is called periodically for state updates.
 *       Only id, status, position, and velocity are returned.
 *
 * @example Override in your code:
 *   int App_GetMotorState(AppMotorState *out_states, uint16_t max_count) {
 *       int idx = 0;
 *       if (idx < max_count) {
 *           out_states[idx].id = 1;
 *           strcpy(out_states[idx].status, "Normal");
 *           out_states[idx].position = Motor_GetPosition(1);
 *           out_states[idx].velocity = Motor_GetVelocity(1);
 *           idx++;
 *       }
 *       return idx;
 *   }
 */
int __attribute__((weak)) App_GetMotorState(AppMotorState *out_states, uint16_t max_count) {
    (void)out_states;
    (void)max_count;
    return 0;  // No motors (not implemented)
}
