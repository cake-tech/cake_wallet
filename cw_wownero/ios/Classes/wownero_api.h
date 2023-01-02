#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include "CwWalletListener.h"

#ifdef __cplusplus
extern "C" {
#endif

//bool create_wallet(char *path, char *password, char *language, int32_t networkType, char *error);
bool wow_restore_wallet_from_14_word_seed(char *path, char *password, char *seed, int32_t networkType, char *error);
bool wow_restore_wallet_from_25_word_seed(char *path, char *password, char *seed, int32_t networkType, uint64_t restoreHeight, char *error);
bool wow_restore_wallet_from_keys(char *path, char *password, char *language, char *address, char *viewKey, char *spendKey, int32_t networkType, uint64_t restoreHeight, char *error);
void wow_load_wallet(char *path, char *password, int32_t nettype);
bool wow_is_wallet_exist(char *path);

char *wow_get_filename();
const char *wow_seed();
char *wow_get_address(uint32_t account_index, uint32_t address_index);
uint64_t wow_get_full_balance(uint32_t account_index);
uint64_t wow_get_unlocked_balance(uint32_t account_index);
uint64_t wow_get_current_height();
uint64_t wow_get_node_height();
uint64_t wow_get_seed_height(char *seed);

bool wow_is_connected();

bool wow_setup_node(char *address, char *login, char *password, bool use_ssl, bool is_light_wallet, char *error);
bool wow_connect_to_node(char *error);
void wow_start_refresh();
void wow_set_refresh_from_block_height(uint64_t height);
void wow_set_recovering_from_seed(bool is_recovery);
void wow_store(char *path);

bool wow_validate_address(char *address);

#ifdef __cplusplus
}
#endif