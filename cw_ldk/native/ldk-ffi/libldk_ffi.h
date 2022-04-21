#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/**
 * remove later.
 * for testing code that is blocking.
 */
char *test_ldk_block(const char *path, void (*func)(char*));

/**
 * Run LDK asynchronous
 */
int32_t test_ldk_async(int64_t isolate_port, const char *rpc_info, const char *ldk_storage_path);

int32_t last_error_length(void);

int32_t error_message_utf8(char *buf, int32_t length);

/**
 * remove later.
 * test to see if channels work on phone.
 */
void ldk_channels(void (*func)(char*));

/**
 * remove later.
 * another test for channels.
 */
void ffi_channels(void (*func)(char*));

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus
