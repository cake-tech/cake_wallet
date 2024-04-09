#include <stdint.h>
#include "cstdlib"
#include <chrono>
#include <functional>
#include <iostream>
#include <unistd.h>
#include <mutex>
#include "thread"
#if __APPLE__
// Fix for randomx on ios
void __clear_cache(void* start, void* end) { }
#include "../External/ios/include/wallet2_api.h"
#else
#include "../External/android/include/wallet2_api.h"
#endif

#include "plain_wallet_api.h"
//#include "plain_wallet_api_ex.h"



//using namespace std::chrono_literals;

#ifdef __cplusplus
extern "C"
{
#endif
    //const uint64_t MONERO_BLOCK_SIZE = 1000;

    struct Utf8Box
    {
        char *value;

        Utf8Box(char *_value)
        {
            value = _value;
        }
    };


    struct SubaddressRow
    {
        uint64_t id;
        char *address;
        char *label;

        SubaddressRow(std::size_t _id, char *_address, char *_label)
        {
            id = static_cast<uint64_t>(_id);
            address = _address;
            label = _label;
        }
    };

    struct AccountRow
    {
        uint64_t id;
        char *label;

        AccountRow(std::size_t _id, char *_label)
        {
            id = static_cast<uint64_t>(_id);
            label = _label;
        }
    };

    struct ZanoBalance
    {
        uint64_t amount;
        char *assetType;

        ZanoBalance(char *_assetType, uint64_t _amount)
        {
            amount = _amount;
            assetType = _assetType;
        }
    };

    struct ZanoRate
    {
        uint64_t rate;
        char *assetType;

        ZanoRate(char *_assetType, uint64_t _rate)
        {
            rate = _rate;
            assetType = _assetType;
        }
    };

    /*struct MoneroWalletListener : Monero::WalletListener
    {
        uint64_t m_height;
        bool m_need_to_refresh;
        bool m_new_transaction;

        MoneroWalletListener()
        {
            m_height = 0;
            m_need_to_refresh = false;
            m_new_transaction = false;
        }

        void moneySpent(const std::string &txId, uint64_t amount, std::string assetType)
        {
            m_new_transaction = true;
        }

        void moneyReceived(const std::string &txId, uint64_t amount, std::string assetType)
        {
            m_new_transaction = true;
        }

        void unconfirmedMoneyReceived(const std::string &txId, uint64_t amount)
        {
            m_new_transaction = true;
        }

        void newBlock(uint64_t height)
        {
            m_height = height;
        }

        void updated()
        {
            m_new_transaction = true;
        }

        void refreshed()
        {
            m_need_to_refresh = true;
        }

        void resetNeedToRefresh()
        {
            m_need_to_refresh = false;
        }

        bool isNeedToRefresh()
        {
            return m_need_to_refresh;
        }

        bool isNewTransactionExist()
        {
            return m_new_transaction;
        }

        void resetIsNewTransactionExist()
        {
            m_new_transaction = false;
        }

        uint64_t height()
        {
            return m_height;
        }
    };
    */

    struct TransactionInfoRow
    {
        uint64_t amount;
        uint64_t fee;
        uint64_t blockHeight;
        uint64_t confirmations;
        uint32_t subaddrAccount;
        int8_t direction;
        int8_t isPending;
        uint32_t subaddrIndex;
        
        char *hash;
        char *paymentId;
        char *assetType;

        int64_t datetime;

        TransactionInfoRow(/*wallet_public::wallet_transfer_info& wti*/)
        {       
            /*     
            amount = wti.subtransfers.
            fee = transaction->fee();
            blockHeight = transaction->blockHeight();
            subaddrAccount = transaction->subaddrAccount();
            std::set<uint32_t>::iterator it = transaction->subaddrIndex().begin();
            subaddrIndex = *it;
            confirmations = transaction->confirmations();
            datetime = static_cast<int64_t>(transaction->timestamp());            
            direction = transaction->direction();
            isPending = static_cast<int8_t>(transaction->isPending());
            std::string *hash_str = new std::string(transaction->hash());
            hash = strdup(hash_str->c_str());
            paymentId = strdup(transaction->paymentId().c_str());
            assetType = strdup(transaction->assetType().c_str());
            */
        }
    };

    /*
    Monero::Wallet *m_wallet;
    Monero::TransactionHistory *m_transaction_history;
    MoneroWalletListener *m_listener;
    Monero::Subaddress *m_subaddress;
    Monero::SubaddressAccount *m_account;
    uint64_t m_last_known_wallet_height;
    uint64_t m_cached_syncing_blockchain_height = 0;
    std::mutex store_lock;
    bool is_storing = false;
    */
    //void change_current_wallet(Monero::Wallet *wallet)
    //{
        /*
        m_wallet = wallet;
        m_listener = nullptr;
        

        if (wallet != nullptr)
        {
            m_transaction_history = wallet->history();
        }
        else
        {
            m_transaction_history = nullptr;
        }

        if (wallet != nullptr)
        {
            m_account = wallet->subaddressAccount();
        }
        else
        {
            m_account = nullptr;
        }

        if (wallet != nullptr)
        {
            m_subaddress = wallet->subaddress();
        }
        else
        {
            m_subaddress = nullptr;
        }
        */
    //}

    //Monero::Wallet *get_current_wallet()
    //{

    //    return nullptr;//return m_wallet;
    //}

    char * create_wallet(char *path, char *password, char *language, int32_t networkType, char *error)
    {
        return  strdup(plain_wallet::generate(path, password).c_str());
    }

    char * restore_wallet_from_seed(char *path, char *password, char *seed, int32_t networkType, uint64_t restoreHeight, char *error)
    {
        return  strdup(plain_wallet::restore(seed, path,  password, "").c_str());
    }

    bool restore_wallet_from_keys(char *path, char *password, char *language, char *address, char *viewKey, char *spendKey, int32_t networkType, uint64_t restoreHeight, char *error)
    {
        /*
        Monero::NetworkType _networkType = static_cast<Monero::NetworkType>(networkType);
        Monero::Wallet *wallet = Monero::WalletManagerFactory::getWalletManager()->createWalletFromKeys(
            std::string(path),
            std::string(password),
            std::string(language),
            _networkType,
            (uint64_t)restoreHeight,
            std::string(address),
            std::string(viewKey),
            std::string(spendKey));

        int status;
        std::string errorString;

        wallet->statusWithErrorString(status, errorString);

        if (status != Monero::Wallet::Status_Ok || !errorString.empty())
        {
            error = strdup(errorString.c_str());
            return false;
        }

        change_current_wallet(wallet);
        */
        return false;
    }

    char * load_wallet(char *path, char *password, int32_t nettype)
    {
        return strdup(plain_wallet::open(path, password).c_str());
    }

    char *error_string() {
        return strdup("");//strdup(get_current_wallet()->errorString().c_str());
    }


    bool is_wallet_exist(char *path)
    {
        return plain_wallet::is_wallet_exist(path);
    }

    char *close_wallet(uint64_t hwallet)
    {
        return strdup(plain_wallet::close_wallet(hwallet).c_str());
    }


    char *get_wallet_info(uint64_t hwallet) {
        return strdup(plain_wallet::get_wallet_info(hwallet).c_str());
    }

    /*
     get_filename(): -> get_wallet_info(h).wi.path
     secret_view_key(): -> get_wallet_info(h).wi_extended.view_private_key
     public_view_key(): -> get_wallet_info(h).wi_extended.view_public_key
     secret_spend_key(): -> get_wallet_info(h).wi_extended.spend_private_key
     public_spend_key(): -> get_wallet_info(h).wi_extended.spend_public_key
     get_address(): -> get_wallet_info(h).wi.address
     seed(): -> get_wallet_info(h).wi_extended.seed
     get_current_height(): -> get_wallet_status(h).current_wallet_height
     get_node_height(): -> get_wallet_status(h).current_daemon_height

     get_syncing_height() ??? how it's different from get_current_height??=
     start_refresh() ???
     set_refresh_from_block_height ???
     set_recovering_from_seed ???
     get_node_height_or_update ???
     is_needed_to_refresh ???
     is_new_transaction_exist ???
     set_listener ???
     transactions_refresh() ???
     on_startup() ???
     rescan_blockchain() ???
     set_trusted_daemon()/trusted_daemon() ???

    
    asset_types_size()/asset_types() dedicated from balance
    
    update_rate()/get_rate()/size_of_rate() - need to fetch Zano price from coinmarketcap API, other assets ???
     
     subaddrress_size()/subaddrress_get_all() - no subaddresses, only one address, available via get_wallet_info(h).wi.address

     connect_to_node()/is_connected(): -> get_connectivity_status(): {
                                                        "is_online": true,
                                                        "last_daemon_is_disconnected": false,
                                                        "is_server_busy": false,
                                                        "last_proxy_communicate_timestamp": 12121212
                                                        }
                                                        
     }
     
     get_full_balance/get_unlocked_balance(): -> async_call("invoke", hwallet, "{method: 'get_recent_txs_and_info', params: {offset: 0,count: 30,update_provision_info: true}}") 
                                    return list of last transactions + balances

     store(): -> async_call("invoke", hwallet, "{method: 'store', params: {}}")  

     set_password() return "OK" if succeded
    
     transaction_create/transaction_commit () replaced with method 'transfer' that receive following argument in JSON: 
             async_call("invoke", hwallet, "
             {
                "method": "transfer",
                "params": {
                    "destinations": [
                    {
                        "amount": "0.222",
                        "address": "iZ2GHyPD7g28hgBfboZeCENaYrHSYZ1bLFi5cgWvn4WJLaxfgs4kqG6cJi9ai2zrXWSCpsvRXit14gKjeijx6YPCLJEv6Fx4rVm1hdAGQFiv", 
                        "asset_id" "bec034f4f158f97cfc4933c3e387b098f69870e955a49061f9ce956212729534"
                    }
                    ],
                    "fee": 10000000000,
                    "mixin": 10,
                    "payment_id": "",
                    "comment": "haha",
                    "push_payer": false,
                    "hide_receiver": true
                }
            }
             ") 

        after transaction_create() event happened you need to call API get_current_tx_fee(priority_raw), get fee from it and use it to 
        show to dialog in UI, and then if confirmed when transaction_commit() need to actually call  async_call(...) that do actual transfer

        subaddress doesn't exist in Zano so following api is not present: 
        subaddress_add_row/subaddress_set_label/subaddress_refresh/account_size/account_get_all/account_add_row/account_set_label_row/account_refresh

        transactions_get_all()  -> 
                async_call("invoke", hwallet, "
            {
                "method": "get_recent_txs_and_info",
                "params": {
                    "offset": 0,
                    "count": 30,
                    "update_provision_info": true
                }
            }
            ")
        
        transactions_count() -> invoke: get_recent_txs_and_info 




    */

    uint64_t get_current_tx_fee(uint64_t priority)
    {
        return plain_wallet::get_current_tx_fee(priority);
    }


    char* get_wallet_status(uint64_t hwallet)
    {
        return strdup(plain_wallet::get_wallet_status(hwallet).c_str());
    }

    char* get_address_info(char* address)
    {
        return strdup(plain_wallet::get_address_info(address).c_str());
    }


    char* async_call(char* method_name, uint64_t instance_id, char* params)
    {
        return strdup(plain_wallet::async_call(method_name, instance_id,  params).c_str());
    }
    char* try_pull_result(uint64_t job_id)
    {
        return strdup(plain_wallet::try_pull_result(job_id).c_str());
    }

    char* sync_call(const std::string& method_name, uint64_t instance_id, const std::string& params)    
    {
        return strdup(plain_wallet::sync_call(method_name, instance_id,  params).c_str());
    }

    char*  get_connectivity_status()
    {
        return strdup(plain_wallet::get_connectivity_status().c_str());
    }

    bool setup_node(char *address, char *login, char *password, bool use_ssl, bool is_light_wallet, char *error)
    {
        nice(19);
        if(use_ssl)
        {
            //LOG_ERROR("SSL is not supported yet for Zano");
            return false;
        }

        std::string res = plain_wallet::init(address, "", 0);
        if(API_RETURN_CODE_OK != res)
        {
            //LOG_ERROR("Failed init wallet");
            return false;
        }

        return true;
    }

    //void start_refresh()
    //{
        //get_current_wallet()->refreshAsync();
        //get_current_wallet()->startRefresh();
    //}

    //void set_refresh_from_block_height(uint64_t height)
    //{
        //get_current_wallet()->setRefreshFromBlockHeight(height);
    //}

    //void set_recovering_from_seed(bool is_recovery)
    //{
        //get_current_wallet()->setRecoveringFromSeed(is_recovery);
    //}

    char* set_password(uint64_t hwallet, char *password, Utf8Box &error) 
    {
       return strdup(plain_wallet::reset_wallet_password(hwallet, password).c_str());
    }


    /*
    bool transaction_create(char *address, char *asset_type, char *payment_id, char *amount,
                                              uint8_t priority_raw, uint32_t subaddr_account, Utf8Box &error, PendingTransactionRaw &pendingTransaction)
    {
        pendingTransaction.fee = plain_wallet::get_current_tx_fee(priority_raw);
        pendingTransaction.amount = strdup(amount);
        pendingTransaction.address = strdup(address); 
        pendingTransaction.asset_type = strdup(asset_type);
        pendingTransaction.payment_id = strdup(payment_id);
        pendingTransaction.priority_raw = priority_raw;
        pendingTransaction.subaddr_account = 0;
        return true;
    }*/

    //bool transaction_create_mult_dest(char **addresses, char *asset_type, char *payment_id, char **amounts, uint32_t size,
    //                                              uint8_t priority_raw, uint32_t subaddr_account, Utf8Box &error, PendingTransactionRaw &pendingTransaction)
    //{
        /*
        nice(19);

        std::vector<std::string> _addresses;
        std::vector<uint64_t> _amounts;

        for (int i = 0; i < size; i++) {
            _addresses.push_back(std::string(*addresses));
            _amounts.push_back(Monero::Wallet::amountFromString(std::string(*amounts)));
            addresses++;
            amounts++;
        }

        auto priority = static_cast<Monero::PendingTransaction::Priority>(priority_raw);
        std::string _payment_id;
        Monero::PendingTransaction *transaction;

        if (payment_id != nullptr)
        {
            _payment_id = std::string(payment_id);
        }

        transaction = m_wallet->createTransactionMultDest(_addresses, _payment_id, _amounts,
        std::string(asset_type), std::string(asset_type), m_wallet->defaultMixin(), priority, subaddr_account,{});

        int status = transaction->status();

        if (status == Monero::PendingTransaction::Status::Status_Error || status == Monero::PendingTransaction::Status::Status_Critical)
        {
            error = Utf8Box(strdup(transaction->errorString().c_str()));
            return false;
        }

        if (m_listener != nullptr) {
            m_listener->m_new_transaction = true;
        }

        pendingTransaction = PendingTransactionRaw(transaction);
        return true;
        */
    //   return false;
    //}

    //bool transaction_commit(PendingTransactionRaw *transaction, Utf8Box &error)
    //{
        /*
        bool committed = transaction->transaction->commit();

        if (!committed)
        {
            error = Utf8Box(strdup(transaction->transaction->errorString().c_str()));
        } else if (m_listener != nullptr) {
            m_listener->m_new_transaction = true;
        }

        return committed;
        */
    //   return false;
    //}

    //uint64_t get_node_height_or_update(uint64_t base_eight)
    //{
        /*
        if (m_cached_syncing_blockchain_height < base_eight) {
            m_cached_syncing_blockchain_height = base_eight;
        }

        return m_cached_syncing_blockchain_height;
        */
    //   return 0;
    //}

    //uint64_t get_syncing_height(uint64_t hwallet)
    //{
        /*
        if (m_listener == nullptr) {
            return 0;
        }

        uint64_t height = m_listener->height();

        if (height <= 1) {
            return 0;
        }

        if (height != m_last_known_wallet_height)
        {
            m_last_known_wallet_height = height;
        }

        return height;
        */
    //   return 0;
    //}

    //uint64_t is_needed_to_refresh()
    //{
    //    return 0;
        /*
        if (m_listener == nullptr) {
            return false;
        }

        bool should_refresh = m_listener->isNeedToRefresh();

        if (should_refresh) {
            m_listener->resetNeedToRefresh();
        }

        return should_refresh;
        */
    //}

    //uint8_t is_new_transaction_exist()
    //{
        /*
        if (m_listener == nullptr) {
            return false;
        }

        bool is_new_transaction_exist = m_listener->isNewTransactionExist();

        if (is_new_transaction_exist)
        {
            m_listener->resetIsNewTransactionExist();
        }

        return is_new_transaction_exist;
        */
    //   return 0;
    //}

    //void set_listener()
    //{
        /*
        m_last_known_wallet_height = 0;

        if (m_listener != nullptr)
        {
             free(m_listener);
        }

        m_listener = new MoneroWalletListener();
        get_current_wallet()->setListener(m_listener);
        */
    //}

    //int64_t *subaddrress_get_all()
    //{
        /*
        std::vector<Monero::SubaddressRow *> _subaddresses = m_subaddress->getAll();
        size_t size = _subaddresses.size();
        int64_t *subaddresses = (int64_t *)malloc(size * sizeof(int64_t));

        for (int i = 0; i < size; i++)
        {
            Monero::SubaddressRow *row = _subaddresses[i];
            SubaddressRow *_row = new SubaddressRow(row->getRowId(), strdup(row->getAddress().c_str()), strdup(row->getLabel().c_str()));
            subaddresses[i] = reinterpret_cast<int64_t>(_row);
        }

        return subaddresses;
        */
    //   return nullptr;
    //}

    //int32_t subaddrress_size()
    //{
        //std::vector<Monero::SubaddressRow *> _subaddresses = m_subaddress->getAll();
        //return _subaddresses.size();
    //    return 0;
    //}

    //void subaddress_add_row(uint32_t accountIndex, char *label)
    //{
        //m_subaddress->addRow(accountIndex, std::string(label));
    //}

    //void subaddress_set_label(uint32_t accountIndex, uint32_t addressIndex, char *label)
    //{
        //m_subaddress->setLabel(accountIndex, addressIndex, std::string(label));
    //}

    //void subaddress_refresh(uint32_t accountIndex)
    //{
        //m_subaddress->refresh(accountIndex);
    //}    
    //int32_t account_size()
    //{
        //std::vector<Monero::SubaddressAccountRow *> _accocunts = m_account->getAll();
        //return _accocunts.size();
    //    return 0;
    //}

    //int64_t *account_get_all()
    //{
        /*
        std::vector<Monero::SubaddressAccountRow *> _accocunts = m_account->getAll();
        size_t size = _accocunts.size();
        int64_t *accocunts = (int64_t *)malloc(size * sizeof(int64_t));

        for (int i = 0; i < size; i++)
        {
            Monero::SubaddressAccountRow *row = _accocunts[i];
            AccountRow *_row = new AccountRow(row->getRowId(), strdup(row->getLabel().c_str()));
            accocunts[i] = reinterpret_cast<int64_t>(_row);
        }

        return accocunts;
        */
    //   return nullptr;
    //}

    //void account_add_row(char *label)
    //{
        //m_account->addRow(std::string(label));
    //}
    //void account_set_label_row(uint32_t account_index, char *label)
    //{
        //m_account->setLabel(account_index, label);
    //}

    //void account_refresh()
    //{
        //m_account->refresh();
    //}

    //int64_t *transactions_get_all()
    //{
        /*
        std::vector<Monero::TransactionInfo *> transactions = m_transaction_history->getAll();
        size_t size = transactions.size();
        int64_t *transactionAddresses = (int64_t *)malloc(size * sizeof(int64_t));

        for (int i = 0; i < size; i++)
        {
            Monero::TransactionInfo *row = transactions[i];
            TransactionInfoRow *tx = new TransactionInfoRow(row);
            transactionAddresses[i] = reinterpret_cast<int64_t>(tx);
        }

        return transactionAddresses;
        */
    //   return nullptr;
    //}

    //void transactions_refresh()
    //{
        //m_transaction_history->refresh();
    //}

    //int64_t transactions_count()
    //{
        //return m_transaction_history->count();
    //    return 0;
    //}

    //int LedgerExchange(
    //    unsigned char *command,
    //    unsigned int cmd_len,
    //    unsigned char *response,
    //    unsigned int max_resp_len)
    //{
    //    return -1;
    //}

    //int LedgerFind(char *buffer, size_t len)
    //{
    //    return -1;
    //}

    //void on_startup()
    //{
        //Monero::Utils::onStartup();
        //Monero::WalletManagerFactory::setLogLevel(4);
    //}

    //void rescan_blockchain()
    //{
        //m_wallet->rescanBlockchainAsync();
    //}

    char * get_tx_key(char * txId)
    {
        return strdup(""); //return strdup(m_wallet->getTxKey(std::string(txId)).c_str());
    }

    //int32_t asset_types_size() 
    //{
    //    return 0; //return Monero::Assets::list().size();
    //}

    //char **asset_types() 
    //{
        /*
        size_t size = Monero::Assets::list().size();
        std::vector<std::string> assetList = Monero::Assets::list();
        char **assetTypesPts;
        assetTypesPts = (char **) malloc( size * sizeof(char*));

        for (int i = 0; i < size; i++)
        {

            std::string asset = assetList[i];
            //assetTypes[i] = (char *)malloc( 5 * sizeof(char));
            assetTypesPts[i] = strdup(asset.c_str());
        }

        return assetTypesPts;
        */
    //   return nullptr;
    //}

    //std::map<std::string, uint64_t> rates;

    //void update_rate()
    //{
        //rates = get_current_wallet()->oracleRates();
    //}

    //int64_t *get_rate()
    //{
        /*
        size_t size = rates.size();
        int64_t *havenRates = (int64_t *)malloc(size * sizeof(int64_t));
        int i = 0;

        for (auto const& rate : rates)
        {   
            char *assetType = strdup(rate.first.c_str());
            HavenRate *havenRate = new HavenRate(assetType, rate.second);
            havenRates[i] = reinterpret_cast<int64_t>(havenRate);
            i++;
        }

        return havenRates;
        */
    //   return nullptr;
    //}

    //int32_t size_of_rate()
    //{
    //    return 0; //return static_cast<int32_t>(rates.size());
    //}

    void set_trusted_daemon(bool arg)
    {
        //m_wallet->setTrustedDaemon(arg);
    }

    bool trusted_daemon()
    {
        return false;
        //return m_wallet->trustedDaemon();
    }

    char* get_version()
    {
        return strdup(plain_wallet::get_version().c_str());
    }

#ifdef __cplusplus
}
#endif
