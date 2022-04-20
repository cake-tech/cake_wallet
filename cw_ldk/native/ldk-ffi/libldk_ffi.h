#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

char *test_ldk_block(const char *path, void (*func)(char*));

int32_t test_ldk_async(int64_t isolate_port, const char *rpc_info, const char *ldk_storage_path);

int32_t last_error_length(void);

int32_t error_message_utf8(char *buf, int32_t length);

void ldk_channels(void (*func)(char*));

void ffi_channels(void (*func)(char*));

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus
