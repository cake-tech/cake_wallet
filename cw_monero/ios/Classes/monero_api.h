#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include "CwWalletListener.h"

#ifdef __cplusplus
extern "C" {
#endif

bool create_wallet(char *path, char *password, char *language, int32_t networkType, char *error);
bool restore_wallet_from_seed(char *path, char *password, char *seed, int32_t networkType, uint64_t restoreHeight, char *error);
bool restore_wallet_from_keys(char *path, char *password, char *language, char *address, char *viewKey, char *spendKey, int32_t networkType, uint64_t restoreHeight, char *error);
void load_wallet(char *path, char *password, int32_t nettype);
bool is_wallet_exist(char *path);

char *get_filename();
const char *seed();
char *get_address(uint32_t account_index, uint32_t address_index);
uint64_t get_full_balance(uint32_t account_index);
uint64_t get_unlocked_balance(uint32_t account_index);
uint64_t get_current_height();
uint64_t get_node_height();

bool is_connected();

bool setup_node(char *address, char *login, char *password, bool use_ssl, bool is_light_wallet, char *error);
bool connect_to_node(char *error);
void start_refresh();
void set_refresh_from_block_height(uint64_t height);
void set_recovering_from_seed(bool is_recovery);
void store(char *path);

#ifdef __cplusplus
}
#endif