use std::{
    collections::{HashMap, HashSet},
    future::Future,
    time::Duration,
};

use async_trait::async_trait;
use bip39::{Language, Mnemonic};
use hmac::{Hmac, Mac};
use num_bigint::BigUint;
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use starknet_rust::{
    accounts::{
        Account, AccountFactory, ConnectedAccount, ExecutionEncoding, OpenZeppelinAccountFactory,
        SingleOwnerAccount,
    },
    core::{
        chain_id,
        codec::Decode,
        crypto::Signature,
        types::{
            AddressFilter, BlockId, BlockTag, BroadcastedTransaction, ByteArray, Call,
            DeployAccountTransaction, EmittedEvent, EventFilter, ExecutionResult, Felt,
            FunctionCall, InvokeTransaction, MaybePreConfirmedBlockWithTxHashes,
            ResourceBoundsMapping, SimulationFlagForEstimateFee, StarknetError, Transaction,
            TransactionFinalityStatus, TransactionReceipt, TypedData,
        },
        utils::{get_contract_address, get_selector_from_name},
    },
    providers::{
        jsonrpc::{HttpTransport, JsonRpcClient},
        Provider, ProviderError, Url,
    },
    signers::{LocalWallet, Signer, SignerInteractivityContext, SigningKey, VerifyingKey},
};
use starknet_rust_curve::curve_params::EC_ORDER;
use tokio::runtime::{Builder, Runtime};

type HmacSha256 = Hmac<Sha256>;
type ApiResult<T> = Result<T, String>;

const DERIVATION_CONTEXT: &[u8] = b"Starknet key derivation";
const DEFAULT_PAGE_SIZE: u64 = 100;
const DEFAULT_MAX_EVENT_PAGES: usize = 10;
const WAIT_FOR_TRANSACTION_POLL_INTERVAL: Duration = Duration::from_secs(3);
const WAIT_FOR_TRANSACTION_TIMEOUT: Duration = Duration::from_secs(300);
const DEFAULT_OPENZEPPELIN_ACCOUNT_CLASS_HASH_HEX: &str =
    "0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381";

static TOKIO_RUNTIME: Lazy<Runtime> = Lazy::new(|| {
    Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("failed to initialize Tokio runtime for cw_starknet")
});

static CURVE_ORDER: Lazy<BigUint> = Lazy::new(|| BigUint::from_bytes_be(&EC_ORDER.to_bytes_be()));

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DerivedAccountData {
    pub private_key_hex: String,
    pub public_key_hex: String,
    pub account_address_hex: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StarknetSignatureData {
    pub r_hex: String,
    pub s_hex: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TransferHistoryItem {
    pub transaction_hash: String,
    pub event_id: String,
    pub event_index: i64,
    pub block_number: Option<i64>,
    pub from: String,
    pub to: String,
    pub amount_wei: String,
    pub is_outgoing: bool,
    pub token_symbol: String,
    pub token_address_hex: String,
    pub block_timestamp: Option<i64>,
    pub tx_fee_wei: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StarknetTokenMetadata {
    pub token_address_hex: String,
    pub name: String,
    pub symbol: String,
    pub decimals: i32,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct StarknetCallInput {
    pub contract_address_hex: String,
    pub entrypoint: String,
    pub calldata_hex: Vec<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StarknetFeeQuote {
    pub overall_fee_wei: String,
    pub execution_fee_wei: String,
    pub deploy_account_fee_wei: Option<String>,
    pub account_deployment_required: bool,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StarknetExecutionPlanData {
    pub invoke_transaction_hash_hex: String,
    pub deploy_account_transaction_hash_hex: Option<String>,
    pub account_deployment_required: bool,
    pub plan_json: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StarknetTransactionDetails {
    pub transaction_hash: String,
    pub transaction_type: String,
    pub is_pending: bool,
    pub block_number: Option<i64>,
    pub block_timestamp: Option<i64>,
    pub actual_fee_wei: Option<String>,
    pub action_name: Option<String>,
    pub call_count: Option<i32>,
    pub primary_contract_address_hex: Option<String>,
    pub primary_entrypoint: Option<String>,
    pub sender_address_hex: Option<String>,
    pub finality_status: Option<String>,
    pub execution_status: Option<String>,
    pub revert_reason: Option<String>,
    pub account_deployment_required: bool,
    pub l1_gas_max_amount: Option<String>,
    pub l1_gas_max_price_wei: Option<String>,
    pub l2_gas_max_amount: Option<String>,
    pub l2_gas_max_price_wei: Option<String>,
    pub l1_data_gas_max_amount: Option<String>,
    pub l1_data_gas_max_price_wei: Option<String>,
    pub tip: Option<i64>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DerivedAccountDataResponse {
    pub value: Option<DerivedAccountData>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StarknetSignatureDataResponse {
    pub value: Option<StarknetSignatureData>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StringResponse {
    pub value: Option<String>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BoolResponse {
    pub value: Option<bool>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct I64Response {
    pub value: Option<i64>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TransferHistoryResponse {
    pub items: Vec<TransferHistoryItem>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TokenMetadataResponse {
    pub value: Option<StarknetTokenMetadata>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FeeQuoteResponse {
    pub value: Option<StarknetFeeQuote>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ExecutionPlanResponse {
    pub value: Option<StarknetExecutionPlanData>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TransactionDetailsResponse {
    pub value: Option<StarknetTransactionDetails>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StringListResponse {
    pub items: Vec<String>,
    pub error: Option<String>,
}

#[derive(Clone, Debug)]
struct TransferEventRecord {
    transaction_hash: Felt,
    event_index: u64,
    block_number: Option<u64>,
    from: String,
    to: String,
    amount_wei: String,
    is_outgoing: bool,
    token_symbol: String,
    token_address_hex: String,
}

#[derive(Clone, Debug)]
struct ExternalSignerError(String);

#[derive(Clone, Debug)]
struct PublicKeyOnlySigner {
    public_key: Felt,
}

#[derive(Clone, Debug)]
struct PreparedTransactionParams {
    nonce: Felt,
    l1_gas: u64,
    l1_gas_price: u128,
    l2_gas: u64,
    l2_gas_price: u128,
    l1_data_gas: u64,
    l1_data_gas_price: u128,
    tip: u64,
}

#[derive(Clone, Debug)]
struct PreparedExternalExecution {
    fee_quote: StarknetFeeQuote,
    invoke_transaction_hash: Felt,
    deploy_account_transaction_hash: Option<Felt>,
    serialized_plan: SerializedExternalExecutionPlan,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum StarknetFeePriority {
    Slow,
    Medium,
    Fast,
}

#[derive(Clone, Debug)]
struct DecodedInvokeCall {
    contract_address: Felt,
    selector: Felt,
    calldata: Vec<Felt>,
}

#[derive(Clone, Debug)]
struct DecodedTransactionSummary {
    transaction_type: String,
    action_name: Option<String>,
    call_count: Option<i32>,
    primary_contract_address_hex: Option<String>,
    primary_entrypoint: Option<String>,
    sender_address_hex: Option<String>,
    account_deployment_required: bool,
    l1_gas_max_amount: Option<String>,
    l1_gas_max_price_wei: Option<String>,
    l2_gas_max_amount: Option<String>,
    l2_gas_max_price_wei: Option<String>,
    l1_data_gas_max_amount: Option<String>,
    l1_data_gas_max_price_wei: Option<String>,
    tip: Option<i64>,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
struct SerializedPreparedTransactionParams {
    nonce_hex: String,
    l1_gas: u64,
    l1_gas_price_wei: String,
    l2_gas: u64,
    l2_gas_price_wei: String,
    l1_data_gas: u64,
    l1_data_gas_price_wei: String,
    tip: u64,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
struct SerializedExternalExecutionPlan {
    public_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    chain_id_hex: String,
    calls: Vec<StarknetCallInput>,
    invoke: SerializedPreparedTransactionParams,
    deploy: Option<SerializedPreparedTransactionParams>,
}

impl DerivedAccountDataResponse {
    fn from_result(result: ApiResult<DerivedAccountData>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl StarknetSignatureDataResponse {
    fn from_result(result: ApiResult<StarknetSignatureData>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl StringResponse {
    fn from_result(result: ApiResult<String>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl BoolResponse {
    fn from_result(result: ApiResult<bool>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl I64Response {
    fn from_result(result: ApiResult<i64>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl TransferHistoryResponse {
    fn from_result(result: ApiResult<Vec<TransferHistoryItem>>) -> Self {
        match result {
            Ok(items) => Self { items, error: None },
            Err(error) => Self {
                items: Vec::new(),
                error: Some(error),
            },
        }
    }
}

impl TokenMetadataResponse {
    fn from_result(result: ApiResult<StarknetTokenMetadata>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl FeeQuoteResponse {
    fn from_result(result: ApiResult<StarknetFeeQuote>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl ExecutionPlanResponse {
    fn from_result(result: ApiResult<StarknetExecutionPlanData>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl TransactionDetailsResponse {
    fn from_result(result: ApiResult<StarknetTransactionDetails>) -> Self {
        let (value, error) = split_result(result);
        Self { value, error }
    }
}

impl StringListResponse {
    fn from_result(result: ApiResult<Vec<String>>) -> Self {
        match result {
            Ok(items) => Self { items, error: None },
            Err(error) => Self {
                items: Vec::new(),
                error: Some(error),
            },
        }
    }
}

impl std::fmt::Display for ExternalSignerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::error::Error for ExternalSignerError {}

impl StarknetFeePriority {
    fn from_raw(raw: i32) -> Self {
        match raw {
            0 => Self::Slow,
            2 => Self::Fast,
            _ => Self::Medium,
        }
    }
}

#[async_trait]
impl Signer for PublicKeyOnlySigner {
    type GetPublicKeyError = ExternalSignerError;
    type SignError = ExternalSignerError;

    async fn get_public_key(&self) -> Result<VerifyingKey, Self::GetPublicKeyError> {
        Ok(VerifyingKey::from_scalar(self.public_key))
    }

    async fn sign_hash(&self, _hash: &Felt) -> Result<Signature, Self::SignError> {
        Err(ExternalSignerError(
            "This Starknet signer only exposes public-key operations".to_string(),
        ))
    }

    fn is_interactive(&self, _context: SignerInteractivityContext<'_>) -> bool {
        true
    }
}

impl SerializedPreparedTransactionParams {
    fn from_prepared(params: &PreparedTransactionParams) -> Self {
        Self {
            nonce_hex: felt_to_hex(params.nonce),
            l1_gas: params.l1_gas,
            l1_gas_price_wei: params.l1_gas_price.to_string(),
            l2_gas: params.l2_gas,
            l2_gas_price_wei: params.l2_gas_price.to_string(),
            l1_data_gas: params.l1_data_gas,
            l1_data_gas_price_wei: params.l1_data_gas_price.to_string(),
            tip: params.tip,
        }
    }

    fn to_prepared(&self, label: &str) -> ApiResult<PreparedTransactionParams> {
        Ok(PreparedTransactionParams {
            nonce: parse_felt_hex(&self.nonce_hex, &format!("{label}.nonce_hex"))?,
            l1_gas: self.l1_gas,
            l1_gas_price: parse_u128_decimal(
                &self.l1_gas_price_wei,
                &format!("{label}.l1_gas_price_wei"),
            )?,
            l2_gas: self.l2_gas,
            l2_gas_price: parse_u128_decimal(
                &self.l2_gas_price_wei,
                &format!("{label}.l2_gas_price_wei"),
            )?,
            l1_data_gas: self.l1_data_gas,
            l1_data_gas_price: parse_u128_decimal(
                &self.l1_data_gas_price_wei,
                &format!("{label}.l1_data_gas_price_wei"),
            )?,
            tip: self.tip,
        })
    }
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn derive_account(
    mnemonic: Option<String>,
    passphrase: Option<String>,
    private_key_hex: Option<String>,
    account_class_hash_hex: String,
) -> DerivedAccountDataResponse {
    DerivedAccountDataResponse::from_result(derive_account_inner(
        mnemonic,
        passphrase,
        private_key_hex,
        account_class_hash_hex,
    ))
}

pub fn derive_account_from_public_key(
    public_key_hex: String,
    account_class_hash_hex: String,
) -> DerivedAccountDataResponse {
    DerivedAccountDataResponse::from_result(derive_account_from_public_key_inner(
        public_key_hex,
        account_class_hash_hex,
    ))
}

pub fn get_token_balance(
    node_url: String,
    account_address_hex: String,
    token_address_hex: String,
) -> StringResponse {
    StringResponse::from_result(run_async(async move {
        let provider = make_provider(&node_url)?;
        let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
        let token_address = parse_felt_hex(&token_address_hex, "token_address_hex")?;
        let selector = get_selector_from_name("balanceOf").map_err(|err| err.to_string())?;

        let result = provider
            .call(
                FunctionCall {
                    contract_address: token_address,
                    entry_point_selector: selector,
                    calldata: vec![account_address],
                },
                BlockId::Tag(BlockTag::Latest),
            )
            .await
            .map_err(format_provider_error)?;

        Ok(uint256_from_call_result(&result).to_string())
    }))
}

pub fn get_token_metadata(node_url: String, token_address_hex: String) -> TokenMetadataResponse {
    TokenMetadataResponse::from_result(run_async(async move {
        let provider = make_provider(&node_url)?;
        let token_address = parse_felt_hex(&token_address_hex, "token_address_hex")?;

        let name = call_token_string(&provider, token_address, "name").await?;
        let symbol = call_token_string(&provider, token_address, "symbol").await?;
        let decimals = call_token_decimals(&provider, token_address).await?;

        Ok(StarknetTokenMetadata {
            token_address_hex: felt_to_hex(token_address),
            name,
            symbol,
            decimals,
        })
    }))
}

pub fn is_account_deployed(node_url: String, account_address_hex: String) -> BoolResponse {
    BoolResponse::from_result(run_async(async move {
        let provider = make_provider(&node_url)?;
        let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
        is_account_deployed_with_provider(&provider, account_address).await
    }))
}

pub fn estimate_transfer_fee(
    node_url: String,
    private_key_hex: String,
    account_address_hex: String,
    recipient_address_hex: String,
    token_address_hex: String,
    amount_wei: String,
    chain_id_hex: Option<String>,
) -> StringResponse {
    StringResponse::from_result(run_async(async move {
        let quote = estimate_execute_fee_inner(
            node_url,
            private_key_hex,
            account_address_hex,
            DEFAULT_OPENZEPPELIN_ACCOUNT_CLASS_HASH_HEX.to_string(),
            vec![StarknetCallInput {
                contract_address_hex: token_address_hex,
                entrypoint: "transfer".to_string(),
                calldata_hex: transfer_calldata_hex(recipient_address_hex, amount_wei)?,
            }],
            StarknetFeePriority::Medium,
            chain_id_hex,
        )
        .await?;

        Ok(quote.overall_fee_wei)
    }))
}

pub fn estimate_standard_transfer_fee(
    node_url: String,
    private_key_hex: String,
    account_address_hex: String,
    token_address_hex: String,
    chain_id_hex: Option<String>,
) -> StringResponse {
    estimate_transfer_fee(
        node_url,
        private_key_hex,
        account_address_hex.clone(),
        account_address_hex,
        token_address_hex,
        "1000".to_string(),
        chain_id_hex,
    )
}

pub fn send_transfer(
    node_url: String,
    private_key_hex: String,
    account_address_hex: String,
    recipient_address_hex: String,
    token_address_hex: String,
    amount_wei: String,
    account_class_hash_hex: String,
    chain_id_hex: Option<String>,
) -> StringResponse {
    StringResponse::from_result(run_async(async move {
        execute_calls_inner(
            node_url,
            private_key_hex,
            account_address_hex,
            account_class_hash_hex,
            vec![StarknetCallInput {
                contract_address_hex: token_address_hex,
                entrypoint: "transfer".to_string(),
                calldata_hex: transfer_calldata_hex(recipient_address_hex, amount_wei)?,
            }],
            StarknetFeePriority::Medium,
            chain_id_hex,
        )
        .await
    }))
}

pub fn estimate_execute_fee(
    node_url: String,
    private_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    calls: Vec<StarknetCallInput>,
    fee_priority_raw: i32,
    chain_id_hex: Option<String>,
) -> FeeQuoteResponse {
    FeeQuoteResponse::from_result(run_async(estimate_execute_fee_inner(
        node_url,
        private_key_hex,
        account_address_hex,
        account_class_hash_hex,
        calls,
        StarknetFeePriority::from_raw(fee_priority_raw),
        chain_id_hex,
    )))
}

pub fn estimate_execute_fee_external_signer(
    node_url: String,
    public_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    calls: Vec<StarknetCallInput>,
    fee_priority_raw: i32,
    chain_id_hex: Option<String>,
) -> FeeQuoteResponse {
    FeeQuoteResponse::from_result(run_async(async move {
        Ok(prepare_external_execution_inner(
            node_url,
            public_key_hex,
            account_address_hex,
            account_class_hash_hex,
            calls,
            StarknetFeePriority::from_raw(fee_priority_raw),
            chain_id_hex,
        )
        .await?
        .fee_quote)
    }))
}

pub fn execute_calls(
    node_url: String,
    private_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    calls: Vec<StarknetCallInput>,
    fee_priority_raw: i32,
    chain_id_hex: Option<String>,
) -> StringResponse {
    StringResponse::from_result(run_async(execute_calls_inner(
        node_url,
        private_key_hex,
        account_address_hex,
        account_class_hash_hex,
        calls,
        StarknetFeePriority::from_raw(fee_priority_raw),
        chain_id_hex,
    )))
}

pub fn get_execute_transaction_hashes_external_signer(
    node_url: String,
    public_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    calls: Vec<StarknetCallInput>,
    fee_priority_raw: i32,
    chain_id_hex: Option<String>,
) -> ExecutionPlanResponse {
    ExecutionPlanResponse::from_result(run_async(async move {
        let prepared = prepare_external_execution_inner(
            node_url,
            public_key_hex,
            account_address_hex,
            account_class_hash_hex,
            calls,
            StarknetFeePriority::from_raw(fee_priority_raw),
            chain_id_hex,
        )
        .await?;

        Ok(StarknetExecutionPlanData {
            invoke_transaction_hash_hex: felt_to_hex(prepared.invoke_transaction_hash),
            deploy_account_transaction_hash_hex: prepared
                .deploy_account_transaction_hash
                .map(felt_to_hex),
            account_deployment_required: prepared.fee_quote.account_deployment_required,
            plan_json: serde_json::to_string(&prepared.serialized_plan)
                .map_err(|err| format!("Failed to serialize Starknet execution plan: {err}"))?,
        })
    }))
}

pub fn execute_calls_external_signer(
    node_url: String,
    plan_json: String,
    invoke_r_hex: String,
    invoke_s_hex: String,
    deploy_r_hex: Option<String>,
    deploy_s_hex: Option<String>,
) -> StringResponse {
    StringResponse::from_result(run_async(execute_calls_external_signer_inner(
        node_url,
        plan_json,
        invoke_r_hex,
        invoke_s_hex,
        deploy_r_hex,
        deploy_s_hex,
    )))
}

pub fn fetch_transfer_history(
    node_url: String,
    account_address_hex: String,
    token_address_hex: String,
    token_symbol: String,
    from_block: Option<i64>,
    max_pages: Option<i32>,
) -> TransferHistoryResponse {
    TransferHistoryResponse::from_result(run_async(async move {
        let provider = make_provider(&node_url)?;
        let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
        let token_address = parse_felt_hex(&token_address_hex, "token_address_hex")?;
        let transfer_selector =
            get_selector_from_name("Transfer").map_err(|err| err.to_string())?;
        let from_block = from_block
            .map(|value| u64::try_from(value).map(BlockId::Number))
            .transpose()
            .map_err(|_| "from_block must be greater than or equal to 0".to_string())?;
        let max_pages = max_pages
            .map(|value| usize::try_from(value).map_err(|_| ()))
            .transpose()
            .map_err(|_| "max_pages must be greater than or equal to 0".to_string())?
            .unwrap_or(DEFAULT_MAX_EVENT_PAGES);

        let mut events = Vec::new();
        fetch_paginated_transfer_events(
            &provider,
            EventFilter {
                from_block: from_block.clone(),
                to_block: None,
                address: Some(AddressFilter::Single(token_address)),
                keys: Some(vec![vec![transfer_selector], vec![account_address]]),
            },
            true,
            token_symbol.clone(),
            max_pages,
            &mut events,
        )
        .await;
        fetch_paginated_transfer_events(
            &provider,
            EventFilter {
                from_block,
                to_block: None,
                address: Some(AddressFilter::Single(token_address)),
                keys: Some(vec![vec![transfer_selector], vec![], vec![account_address]]),
            },
            false,
            token_symbol,
            max_pages,
            &mut events,
        )
        .await;

        let mut deduped = Vec::new();
        let mut seen = HashSet::new();
        for event in events {
            let dedupe_key = format!("{:#x}_{}", event.transaction_hash, event.event_index);
            if seen.insert(dedupe_key.clone()) {
                deduped.push(event);
            } else if event.is_outgoing {
                if let Some(existing) = deduped.iter_mut().find(|item| {
                    format!("{:#x}_{}", item.transaction_hash, item.event_index) == dedupe_key
                }) {
                    existing.is_outgoing = true;
                }
            }
        }

        let mut block_timestamps = HashMap::new();
        for block_number in deduped.iter().filter_map(|event| event.block_number) {
            block_timestamps.entry(block_number).or_insert(None);
        }
        let block_numbers = block_timestamps.keys().copied().collect::<Vec<_>>();
        for block_number in block_numbers {
            block_timestamps.insert(
                block_number,
                fetch_block_timestamp(&provider, block_number).await.ok(),
            );
        }

        let mut tx_fees = HashMap::new();
        for tx_hash in deduped.iter().map(|event| event.transaction_hash) {
            tx_fees.entry(tx_hash).or_insert(None);
        }
        let tx_hashes = tx_fees.keys().copied().collect::<Vec<_>>();
        for tx_hash in tx_hashes {
            tx_fees.insert(
                tx_hash,
                fetch_transaction_fee(&provider, tx_hash).await.ok(),
            );
        }

        Ok(deduped
            .into_iter()
            .map(|event| TransferHistoryItem {
                transaction_hash: felt_to_hex(event.transaction_hash),
                event_id: format!(
                    "{}:{}:{}",
                    felt_to_hex(event.transaction_hash),
                    event.token_address_hex,
                    event.event_index
                ),
                event_index: i64::try_from(event.event_index).unwrap_or(i64::MAX),
                block_number: event
                    .block_number
                    .and_then(|value| i64::try_from(value).ok()),
                from: event.from,
                to: event.to,
                amount_wei: event.amount_wei,
                is_outgoing: event.is_outgoing,
                token_symbol: event.token_symbol,
                token_address_hex: event.token_address_hex,
                block_timestamp: event
                    .block_number
                    .and_then(|value| block_timestamps.get(&value).copied().flatten()),
                tx_fee_wei: tx_fees.get(&event.transaction_hash).cloned().flatten(),
            })
            .collect())
    }))
}

pub fn get_transaction_details(
    node_url: String,
    transaction_hash_hex: String,
) -> TransactionDetailsResponse {
    TransactionDetailsResponse::from_result(run_async(async move {
        let provider = make_provider(&node_url)?;
        let transaction_hash = parse_felt_hex(&transaction_hash_hex, "transaction_hash_hex")?;
        fetch_transaction_details(&provider, transaction_hash).await
    }))
}

pub fn get_block_number(node_url: String) -> I64Response {
    I64Response::from_result(run_async(async move {
        let provider = make_provider(&node_url)?;
        let block_number = provider
            .block_number()
            .await
            .map_err(format_provider_error)?;
        i64::try_from(block_number).map_err(|_| "Block number does not fit in i64".to_string())
    }))
}

pub fn sign_message_hash(
    private_key_hex: String,
    message_hash_hex: String,
) -> StarknetSignatureDataResponse {
    StarknetSignatureDataResponse::from_result(sign_message_hash_inner(
        private_key_hex,
        message_hash_hex,
    ))
}

pub fn verify_message_hash_signature(
    public_key_hex: String,
    message_hash_hex: String,
    r_hex: String,
    s_hex: String,
) -> BoolResponse {
    BoolResponse::from_result(verify_message_hash_signature_inner(
        public_key_hex,
        message_hash_hex,
        r_hex,
        s_hex,
    ))
}

pub fn sign_typed_data(
    private_key_hex: String,
    account_address_hex: String,
    typed_data_json: String,
) -> StringListResponse {
    StringListResponse::from_result(sign_typed_data_inner(
        private_key_hex,
        account_address_hex,
        typed_data_json,
    ))
}

pub fn get_typed_data_message_hash(
    account_address_hex: String,
    typed_data_json: String,
) -> StringResponse {
    StringResponse::from_result(get_typed_data_message_hash_inner(
        account_address_hex,
        typed_data_json,
    ))
}

fn split_result<T>(result: ApiResult<T>) -> (Option<T>, Option<String>) {
    match result {
        Ok(value) => (Some(value), None),
        Err(error) => (None, Some(error)),
    }
}

fn derive_account_inner(
    mnemonic: Option<String>,
    passphrase: Option<String>,
    private_key_hex: Option<String>,
    account_class_hash_hex: String,
) -> ApiResult<DerivedAccountData> {
    let private_key = if let Some(private_key_hex) = private_key_hex {
        parse_private_key(&private_key_hex)?
    } else if let Some(mnemonic) = mnemonic {
        derive_private_key_from_mnemonic(&mnemonic, passphrase.as_deref())?
    } else {
        return Err("Either mnemonic or private_key_hex must be provided".to_string());
    };

    validate_private_key(private_key)?;

    let signing_key = SigningKey::from_secret_scalar(private_key);
    let public_key = signing_key.verifying_key().scalar();
    let account_class_hash = parse_felt_hex(&account_class_hash_hex, "account_class_hash_hex")?;
    let account_address =
        get_contract_address(public_key, account_class_hash, &[public_key], Felt::ZERO);

    Ok(DerivedAccountData {
        private_key_hex: felt_to_hex(private_key),
        public_key_hex: felt_to_hex(public_key),
        account_address_hex: felt_to_hex(account_address),
    })
}

fn derive_account_from_public_key_inner(
    public_key_hex: String,
    account_class_hash_hex: String,
) -> ApiResult<DerivedAccountData> {
    let public_key = parse_felt_hex(&public_key_hex, "public_key_hex")?;
    let account_class_hash = parse_felt_hex(&account_class_hash_hex, "account_class_hash_hex")?;
    let account_address = derive_account_address_from_public_key(public_key, account_class_hash);

    Ok(DerivedAccountData {
        private_key_hex: String::new(),
        public_key_hex: felt_to_hex(public_key),
        account_address_hex: felt_to_hex(account_address),
    })
}

fn sign_message_hash_inner(
    private_key_hex: String,
    message_hash_hex: String,
) -> ApiResult<StarknetSignatureData> {
    let private_key = parse_private_key(&private_key_hex)?;
    let message_hash = parse_felt_hex(&message_hash_hex, "message_hash_hex")?;
    let signature = SigningKey::from_secret_scalar(private_key)
        .sign(&message_hash)
        .map_err(|err| err.to_string())?;

    Ok(StarknetSignatureData {
        r_hex: felt_to_hex(signature.r),
        s_hex: felt_to_hex(signature.s),
    })
}

fn verify_message_hash_signature_inner(
    public_key_hex: String,
    message_hash_hex: String,
    r_hex: String,
    s_hex: String,
) -> ApiResult<bool> {
    let public_key = parse_felt_hex(&public_key_hex, "public_key_hex")?;
    let message_hash = parse_felt_hex(&message_hash_hex, "message_hash_hex")?;
    let signature = Signature {
        r: parse_felt_hex(&r_hex, "r_hex")?,
        s: parse_felt_hex(&s_hex, "s_hex")?,
    };

    VerifyingKey::from_scalar(public_key)
        .verify(&message_hash, &signature)
        .map_err(|err| err.to_string())
}

fn sign_typed_data_inner(
    private_key_hex: String,
    account_address_hex: String,
    typed_data_json: String,
) -> ApiResult<Vec<String>> {
    let private_key = parse_private_key(&private_key_hex)?;
    let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
    let typed_data: TypedData = serde_json::from_str(&typed_data_json)
        .map_err(|err| format!("Invalid typedData: {err}"))?;
    let message_hash = typed_data
        .message_hash(account_address)
        .map_err(|err| format!("Invalid typedData: {err}"))?;
    let signature = SigningKey::from_secret_scalar(private_key)
        .sign(&message_hash)
        .map_err(|err| err.to_string())?;

    Ok(vec![felt_to_hex(signature.r), felt_to_hex(signature.s)])
}

fn get_typed_data_message_hash_inner(
    account_address_hex: String,
    typed_data_json: String,
) -> ApiResult<String> {
    let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
    let typed_data: TypedData = serde_json::from_str(&typed_data_json)
        .map_err(|err| format!("Invalid typedData: {err}"))?;
    let message_hash = typed_data
        .message_hash(account_address)
        .map_err(|err| format!("Invalid typedData: {err}"))?;

    Ok(felt_to_hex(message_hash))
}

async fn estimate_execute_fee_inner(
    node_url: String,
    private_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    calls: Vec<StarknetCallInput>,
    fee_priority: StarknetFeePriority,
    chain_id_hex: Option<String>,
) -> ApiResult<StarknetFeeQuote> {
    let provider = make_provider(&node_url)?;
    let private_key = parse_private_key(&private_key_hex)?;
    let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
    let account_class_hash = parse_felt_hex(&account_class_hash_hex, "account_class_hash_hex")?;
    let chain_id = parse_chain_id(chain_id_hex.as_deref())?;
    let signing_key = SigningKey::from_secret_scalar(private_key);
    let public_key = signing_key.verifying_key().scalar();
    let call_inputs = build_execution_calls(calls)?;
    let is_deployed = is_account_deployed_with_provider(&provider, account_address).await?;

    if is_deployed {
        let account = make_single_owner_account(
            provider.clone(),
            LocalWallet::from(signing_key),
            account_address,
            chain_id,
        );
        let nonce = account.get_nonce().await.map_err(format_provider_error)?;
        let invoke_params = prepare_transaction_params_from_fee_estimate(
            &provider,
            nonce,
            account
                .execute_v3(call_inputs)
                .nonce(nonce)
                .estimate_fee()
                .await
                .map_err(format_account_error)?,
            fee_priority,
        )
        .await?;

        let execution_fee = calculate_overall_fee_from_params(&invoke_params).to_string();
        return Ok(StarknetFeeQuote {
            overall_fee_wei: execution_fee.clone(),
            execution_fee_wei: execution_fee,
            deploy_account_fee_wei: None,
            account_deployment_required: false,
        });
    }

    let factory = OpenZeppelinAccountFactory::new(
        account_class_hash,
        chain_id,
        LocalWallet::from(signing_key.clone()),
        provider.clone(),
    )
    .await
    .map_err(|_| "failed to derive Starknet public key".to_string())?;

    let deploy_request = factory
        .deploy_v3(public_key)
        .nonce(Felt::ZERO)
        .l1_gas(0)
        .l1_gas_price(0)
        .l2_gas(0)
        .l2_gas_price(0)
        .l1_data_gas(0)
        .l1_data_gas_price(0)
        .tip(0)
        .prepared()
        .map_err(|_| "failed to prepare deploy account request".to_string())?
        .get_deploy_request(true, false)
        .await
        .map_err(format_account_error)?;

    let account = make_single_owner_account(
        provider.clone(),
        LocalWallet::from(signing_key),
        account_address,
        chain_id,
    );

    let invoke_request = account
        .execute_v3(call_inputs)
        .nonce(Felt::ONE)
        .l1_gas(0)
        .l1_gas_price(0)
        .l2_gas(0)
        .l2_gas_price(0)
        .l1_data_gas(0)
        .l1_data_gas_price(0)
        .tip(0)
        .prepared()
        .map_err(|_| "failed to prepare invoke request".to_string())?
        .get_invoke_request(true, false)
        .await
        .map_err(format_account_error)?;

    let fee_estimates = provider
        .estimate_fee(
            [
                starknet_rust::core::types::BroadcastedTransaction::DeployAccount(deploy_request),
                starknet_rust::core::types::BroadcastedTransaction::Invoke(invoke_request),
            ],
            Vec::<starknet_rust::core::types::SimulationFlagForEstimateFee>::new(),
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .map_err(format_provider_error)?;

    if fee_estimates.len() != 2 {
        return Err(format!(
            "Unexpected Starknet fee estimate response length: {}",
            fee_estimates.len()
        ));
    }

    let tip = fetch_latest_block_tip(&provider).await?;
    let deploy_params = prepare_transaction_params_from_estimate_with_tip(
        Felt::ZERO,
        &fee_estimates[0],
        tip,
        fee_priority,
    )?;
    let invoke_params = prepare_transaction_params_from_estimate_with_tip(
        Felt::ONE,
        &fee_estimates[1],
        tip,
        fee_priority,
    )?;
    let deploy_fee = calculate_overall_fee_from_params(&deploy_params);
    let execution_fee = calculate_overall_fee_from_params(&invoke_params);
    Ok(StarknetFeeQuote {
        overall_fee_wei: (deploy_fee.clone() + execution_fee.clone()).to_string(),
        execution_fee_wei: execution_fee.to_string(),
        deploy_account_fee_wei: Some(deploy_fee.to_string()),
        account_deployment_required: true,
    })
}

async fn prepare_external_execution_inner(
    node_url: String,
    public_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    calls: Vec<StarknetCallInput>,
    fee_priority: StarknetFeePriority,
    chain_id_hex: Option<String>,
) -> ApiResult<PreparedExternalExecution> {
    let provider = make_provider(&node_url)?;
    let public_key = parse_felt_hex(&public_key_hex, "public_key_hex")?;
    let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
    let account_class_hash = parse_felt_hex(&account_class_hash_hex, "account_class_hash_hex")?;
    let chain_id = parse_chain_id(chain_id_hex.as_deref())?;
    let signer = PublicKeyOnlySigner { public_key };

    validate_derived_account_address(public_key, account_class_hash, account_address)?;

    let execution_calls = build_execution_calls(calls.clone())?;
    let account =
        make_single_owner_account(provider.clone(), signer.clone(), account_address, chain_id);

    if is_account_deployed_with_provider(&provider, account_address).await? {
        let nonce = account.get_nonce().await.map_err(format_provider_error)?;
        let invoke_params = prepare_transaction_params_from_fee_estimate(
            &provider,
            nonce,
            account
                .execute_v3(execution_calls.clone())
                .nonce(nonce)
                .estimate_fee()
                .await
                .map_err(format_account_error)?,
            fee_priority,
        )
        .await?;
        let invoke_hash = build_invoke_transaction_hash(&account, execution_calls, &invoke_params)?;

        return Ok(PreparedExternalExecution {
            fee_quote: StarknetFeeQuote {
                overall_fee_wei: calculate_overall_fee_from_params(&invoke_params).to_string(),
                execution_fee_wei: calculate_overall_fee_from_params(&invoke_params).to_string(),
                deploy_account_fee_wei: None,
                account_deployment_required: false,
            },
            invoke_transaction_hash: invoke_hash,
            deploy_account_transaction_hash: None,
            serialized_plan: SerializedExternalExecutionPlan {
                public_key_hex: felt_to_hex(public_key),
                account_address_hex: felt_to_hex(account_address),
                account_class_hash_hex: felt_to_hex(account_class_hash),
                chain_id_hex: felt_to_hex(chain_id),
                calls,
                invoke: SerializedPreparedTransactionParams::from_prepared(&invoke_params),
                deploy: None,
            },
        });
    }

    let factory =
        OpenZeppelinAccountFactory::new(account_class_hash, chain_id, signer, provider.clone())
            .await
            .map_err(|err| err.to_string())?;

    let zero_deploy_request = factory
        .deploy_v3(public_key)
        .nonce(Felt::ZERO)
        .l1_gas(0)
        .l1_gas_price(0)
        .l2_gas(0)
        .l2_gas_price(0)
        .l1_data_gas(0)
        .l1_data_gas_price(0)
        .tip(0)
        .prepared()
        .map_err(|_| "failed to prepare deploy account request".to_string())?
        .get_deploy_request(true, true)
        .await
        .map_err(format_account_error)?;

    let zero_invoke_request = account
        .execute_v3(execution_calls.clone())
        .nonce(Felt::ONE)
        .l1_gas(0)
        .l1_gas_price(0)
        .l2_gas(0)
        .l2_gas_price(0)
        .l1_data_gas(0)
        .l1_data_gas_price(0)
        .tip(0)
        .prepared()
        .map_err(|_| "failed to prepare invoke request".to_string())?
        .get_invoke_request(true, true)
        .await
        .map_err(format_account_error)?;

    let fee_estimates = provider
        .estimate_fee(
            [
                BroadcastedTransaction::DeployAccount(zero_deploy_request),
                BroadcastedTransaction::Invoke(zero_invoke_request),
            ],
            vec![SimulationFlagForEstimateFee::SkipValidate],
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .map_err(format_provider_error)?;

    if fee_estimates.len() != 2 {
        return Err(format!(
            "Unexpected Starknet fee estimate response length: {}",
            fee_estimates.len()
        ));
    }

    let tip = fetch_latest_block_tip(&provider).await?;
    let deploy_params = prepare_transaction_params_from_estimate_with_tip(
        Felt::ZERO,
        &fee_estimates[0],
        tip,
        fee_priority,
    )?;
    let invoke_params = prepare_transaction_params_from_estimate_with_tip(
        Felt::ONE,
        &fee_estimates[1],
        tip,
        fee_priority,
    )?;
    let deploy_hash = build_deploy_transaction_hash(&factory, public_key, &deploy_params)?;
    let invoke_hash = build_invoke_transaction_hash(&account, execution_calls, &invoke_params)?;
    let deploy_fee = calculate_overall_fee_from_params(&deploy_params);
    let execution_fee = calculate_overall_fee_from_params(&invoke_params);

    Ok(PreparedExternalExecution {
        fee_quote: StarknetFeeQuote {
            overall_fee_wei: (deploy_fee.clone() + execution_fee.clone()).to_string(),
            execution_fee_wei: execution_fee.to_string(),
            deploy_account_fee_wei: Some(deploy_fee.to_string()),
            account_deployment_required: true,
        },
        invoke_transaction_hash: invoke_hash,
        deploy_account_transaction_hash: Some(deploy_hash),
        serialized_plan: SerializedExternalExecutionPlan {
            public_key_hex: felt_to_hex(public_key),
            account_address_hex: felt_to_hex(account_address),
            account_class_hash_hex: felt_to_hex(account_class_hash),
            chain_id_hex: felt_to_hex(chain_id),
            calls,
            invoke: SerializedPreparedTransactionParams::from_prepared(&invoke_params),
            deploy: Some(SerializedPreparedTransactionParams::from_prepared(
                &deploy_params,
            )),
        },
    })
}

async fn execute_calls_external_signer_inner(
    node_url: String,
    plan_json: String,
    invoke_r_hex: String,
    invoke_s_hex: String,
    deploy_r_hex: Option<String>,
    deploy_s_hex: Option<String>,
) -> ApiResult<String> {
    let plan: SerializedExternalExecutionPlan = serde_json::from_str(&plan_json)
        .map_err(|err| format!("Invalid Starknet execution plan: {err}"))?;
    let provider = make_provider(&node_url)?;
    let public_key = parse_felt_hex(&plan.public_key_hex, "plan.public_key_hex")?;
    let account_address = parse_felt_hex(&plan.account_address_hex, "plan.account_address_hex")?;
    let account_class_hash =
        parse_felt_hex(&plan.account_class_hash_hex, "plan.account_class_hash_hex")?;
    let chain_id = parse_felt_hex(&plan.chain_id_hex, "plan.chain_id_hex")?;
    let invoke_params = plan.invoke.to_prepared("plan.invoke")?;

    validate_derived_account_address(public_key, account_class_hash, account_address)?;

    let execution_calls = build_execution_calls(plan.calls.clone())?;
    let account = make_single_owner_account(
        provider.clone(),
        PublicKeyOnlySigner { public_key },
        account_address,
        chain_id,
    );

    if let Some(deploy_plan) = plan.deploy {
        let deploy_r_hex = deploy_r_hex.ok_or_else(|| {
            "Missing deploy_account signature for undeployed Starknet account".to_string()
        })?;
        let deploy_s_hex = deploy_s_hex.ok_or_else(|| {
            "Missing deploy_account signature for undeployed Starknet account".to_string()
        })?;
        let deploy_signature = parse_signature_hex(&deploy_r_hex, &deploy_s_hex, "deploy")?;
        let deploy_params = deploy_plan.to_prepared("plan.deploy")?;
        let factory = OpenZeppelinAccountFactory::new(
            account_class_hash,
            chain_id,
            PublicKeyOnlySigner { public_key },
            provider.clone(),
        )
        .await
        .map_err(|err| err.to_string())?;
        let deployment = factory
            .deploy_v3(public_key)
            .nonce(deploy_params.nonce)
            .l1_gas(deploy_params.l1_gas)
            .l1_gas_price(deploy_params.l1_gas_price)
            .l2_gas(deploy_params.l2_gas)
            .l2_gas_price(deploy_params.l2_gas_price)
            .l1_data_gas(deploy_params.l1_data_gas)
            .l1_data_gas_price(deploy_params.l1_data_gas_price)
            .tip(deploy_params.tip)
            .prepared()
            .map_err(|_| "failed to prepare deploy account request".to_string())?;
        let mut deploy_request = deployment
            .get_deploy_request(false, true)
            .await
            .map_err(format_account_error)?;
        deploy_request.signature = vec![deploy_signature.r, deploy_signature.s];
        let deploy_result = provider
            .add_deploy_account_transaction(deploy_request)
            .await
            .map_err(format_provider_error)?;
        wait_for_transaction(&node_url, deploy_result.transaction_hash).await?;
    }

    let invoke_signature = parse_signature_hex(&invoke_r_hex, &invoke_s_hex, "invoke")?;
    let invocation = account
        .execute_v3(execution_calls)
        .nonce(invoke_params.nonce)
        .l1_gas(invoke_params.l1_gas)
        .l1_gas_price(invoke_params.l1_gas_price)
        .l2_gas(invoke_params.l2_gas)
        .l2_gas_price(invoke_params.l2_gas_price)
        .l1_data_gas(invoke_params.l1_data_gas)
        .l1_data_gas_price(invoke_params.l1_data_gas_price)
        .tip(invoke_params.tip)
        .prepared()
        .map_err(|_| "failed to prepare invoke request".to_string())?;
    let mut invoke_request = invocation
        .get_invoke_request(false, true)
        .await
        .map_err(format_account_error)?;
    invoke_request.broadcasted_invoke_txn_v3.signature =
        vec![invoke_signature.r, invoke_signature.s];
    let invoke_result = provider
        .add_invoke_transaction(invoke_request)
        .await
        .map_err(format_provider_error)?;

    wait_for_transaction(&node_url, invoke_result.transaction_hash).await?;
    Ok(felt_to_hex(invoke_result.transaction_hash))
}

async fn execute_calls_inner(
    node_url: String,
    private_key_hex: String,
    account_address_hex: String,
    account_class_hash_hex: String,
    calls: Vec<StarknetCallInput>,
    fee_priority: StarknetFeePriority,
    chain_id_hex: Option<String>,
) -> ApiResult<String> {
    let private_key = parse_private_key(&private_key_hex)?;
    let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
    let account_class_hash = parse_felt_hex(&account_class_hash_hex, "account_class_hash_hex")?;
    let chain_id = parse_chain_id(chain_id_hex.as_deref())?;
    let signing_key = SigningKey::from_secret_scalar(private_key);
    let public_key = signing_key.verifying_key().scalar();
    let call_inputs = build_execution_calls(calls)?;

    let provider = make_provider(&node_url)?;
    if !is_account_deployed_with_provider(&provider, account_address).await? {
        let factory = OpenZeppelinAccountFactory::new(
            account_class_hash,
            chain_id,
            LocalWallet::from(signing_key.clone()),
            provider.clone(),
        )
        .await
        .map_err(|_| "failed to derive Starknet public key".to_string())?;
        let deploy_estimate = factory
            .deploy_v3(public_key)
            .estimate_fee()
            .await
            .map_err(format_account_error)?;
        let deploy_params = prepare_transaction_params_from_fee_estimate(
            &provider,
            Felt::ZERO,
            deploy_estimate,
            fee_priority,
        )
        .await?;
        let deployment = factory
            .deploy_v3(public_key)
            .nonce(deploy_params.nonce)
            .l1_gas(deploy_params.l1_gas)
            .l1_gas_price(deploy_params.l1_gas_price)
            .l2_gas(deploy_params.l2_gas)
            .l2_gas_price(deploy_params.l2_gas_price)
            .l1_data_gas(deploy_params.l1_data_gas)
            .l1_data_gas_price(deploy_params.l1_data_gas_price)
            .tip(deploy_params.tip);

        let deployment_result = deployment.send().await.map_err(format_account_error)?;
        wait_for_transaction(&node_url, deployment_result.transaction_hash).await?;
    }

    let execute_provider = make_provider(&node_url)?;
    let account = make_single_owner_account(
        execute_provider.clone(),
        LocalWallet::from(signing_key),
        account_address,
        chain_id,
    );
    let nonce = account.get_nonce().await.map_err(format_provider_error)?;
    let invoke_params = prepare_transaction_params_from_fee_estimate(
        &execute_provider,
        nonce,
        account
            .execute_v3(call_inputs.clone())
            .nonce(nonce)
            .estimate_fee()
            .await
            .map_err(format_account_error)?,
        fee_priority,
    )
    .await?;
    let invoke_result = account
        .execute_v3(call_inputs)
        .nonce(invoke_params.nonce)
        .l1_gas(invoke_params.l1_gas)
        .l1_gas_price(invoke_params.l1_gas_price)
        .l2_gas(invoke_params.l2_gas)
        .l2_gas_price(invoke_params.l2_gas_price)
        .l1_data_gas(invoke_params.l1_data_gas)
        .l1_data_gas_price(invoke_params.l1_data_gas_price)
        .tip(invoke_params.tip)
        .send()
        .await
        .map_err(format_account_error)?;

    wait_for_transaction(&node_url, invoke_result.transaction_hash).await?;
    Ok(felt_to_hex(invoke_result.transaction_hash))
}

fn run_async<F, T>(future: F) -> ApiResult<T>
where
    F: Future<Output = ApiResult<T>>,
{
    TOKIO_RUNTIME.block_on(future)
}

fn make_provider(node_url: &str) -> ApiResult<JsonRpcClient<HttpTransport>> {
    crate::ensure_crypto_provider();
    let url = Url::parse(node_url).map_err(|err| format!("Invalid Starknet node URL: {err}"))?;
    Ok(JsonRpcClient::new(HttpTransport::new(url)))
}

fn parse_private_key(private_key_hex: &str) -> ApiResult<Felt> {
    let private_key = parse_felt_hex(private_key_hex, "private_key_hex")?;
    validate_private_key(private_key)?;
    Ok(private_key)
}

fn parse_felt_hex(value: &str, field_name: &str) -> ApiResult<Felt> {
    let normalized = normalize_hex(value);
    Felt::from_hex(&normalized).map_err(|err| format!("Invalid {field_name} `{value}`: {err}"))
}

fn parse_chain_id(chain_id_hex: Option<&str>) -> ApiResult<Felt> {
    match chain_id_hex {
        Some(value) => parse_felt_hex(value, "chain_id_hex"),
        None => Ok(chain_id::MAINNET),
    }
}

fn parse_u128_decimal(value: &str, field_name: &str) -> ApiResult<u128> {
    value
        .parse::<u128>()
        .map_err(|_| format!("Invalid decimal {field_name} `{value}`"))
}

fn normalize_hex(value: &str) -> String {
    if value.starts_with("0x") || value.starts_with("0X") {
        value.to_string()
    } else {
        format!("0x{value}")
    }
}

fn felt_to_hex(felt: Felt) -> String {
    format!("{felt:#x}")
}

fn validate_private_key(private_key: Felt) -> ApiResult<()> {
    let value = felt_to_biguint(private_key);
    if value == BigUint::default() || value >= *CURVE_ORDER {
        return Err("Invalid Stark private key".to_string());
    }

    Ok(())
}

fn derive_private_key_from_mnemonic(mnemonic: &str, passphrase: Option<&str>) -> ApiResult<Felt> {
    let mnemonic = Mnemonic::parse_in(Language::English, mnemonic)
        .or_else(|_| Mnemonic::parse_normalized(mnemonic))
        .map_err(|err| format!("Invalid mnemonic: {err}"))?;
    let seed = mnemonic.to_seed(passphrase.unwrap_or_default());

    let mut hmac =
        HmacSha256::new_from_slice(seed.as_ref()).expect("HMAC supports arbitrary key lengths");
    hmac.update(DERIVATION_CONTEXT);
    let mut derived = hmac.finalize().into_bytes().to_vec();

    for i in 0..10_000u32 {
        let candidate = BigUint::from_bytes_be(&derived) % &*CURVE_ORDER;
        if candidate != BigUint::default() {
            let candidate_bytes = candidate.to_bytes_be();
            return Ok(Felt::from_bytes_be_slice(&candidate_bytes));
        }

        let mut next_hmac =
            HmacSha256::new_from_slice(&derived).expect("HMAC supports arbitrary key lengths");
        next_hmac.update(&[(i & 0xff) as u8]);
        derived = next_hmac.finalize().into_bytes().to_vec();
    }

    Err("Failed to derive valid Stark private key".to_string())
}

fn make_single_owner_account<S>(
    provider: JsonRpcClient<HttpTransport>,
    signer: S,
    account_address: Felt,
    chain_id: Felt,
) -> SingleOwnerAccount<JsonRpcClient<HttpTransport>, S>
where
    S: Signer + Sync + Send,
{
    SingleOwnerAccount::new(
        provider,
        signer,
        account_address,
        chain_id,
        ExecutionEncoding::New,
    )
}

fn derive_account_address_from_public_key(public_key: Felt, account_class_hash: Felt) -> Felt {
    get_contract_address(public_key, account_class_hash, &[public_key], Felt::ZERO)
}

fn validate_derived_account_address(
    public_key: Felt,
    account_class_hash: Felt,
    account_address: Felt,
) -> ApiResult<()> {
    let expected_address = derive_account_address_from_public_key(public_key, account_class_hash);

    if expected_address != account_address {
        return Err(format!(
            "Account address {} does not match Starknet public key {} for class hash {} (expected {})",
            felt_to_hex(account_address),
            felt_to_hex(public_key),
            felt_to_hex(account_class_hash),
            felt_to_hex(expected_address),
        ));
    }

    Ok(())
}

async fn fetch_latest_block_tip(provider: &JsonRpcClient<HttpTransport>) -> ApiResult<u64> {
    Ok(provider
        .get_block_with_txs(BlockId::Tag(BlockTag::Latest), None)
        .await
        .map_err(format_provider_error)?
        .median_tip())
}

fn apply_multiplier_u64(value: u64, numerator: u64, denominator: u64) -> ApiResult<u64> {
    let adjusted = (u128::from(value) * u128::from(numerator))
        .checked_add(u128::from(denominator.saturating_sub(1)))
        .ok_or_else(|| "fee calculation overflow".to_string())?
        / u128::from(denominator);
    u64::try_from(adjusted).map_err(|_| "fee calculation overflow".to_string())
}

fn apply_multiplier_u128(value: u128, numerator: u64, denominator: u64) -> ApiResult<u128> {
    value
        .checked_mul(u128::from(numerator))
        .and_then(|intermediate| {
            intermediate.checked_add(u128::from(denominator.saturating_sub(1)))
        })
        .map(|adjusted| adjusted / u128::from(denominator))
        .ok_or_else(|| "fee calculation overflow".to_string())
}

fn fee_priority_multipliers(priority: StarknetFeePriority) -> (u64, u64, u64, u64, u64, u64) {
    match priority {
        StarknetFeePriority::Slow => (115, 100, 110, 100, 50, 100),
        StarknetFeePriority::Medium => (135, 100, 130, 100, 100, 100),
        StarknetFeePriority::Fast => (160, 100, 150, 100, 200, 100),
    }
}

fn adjust_tip(value: u64, numerator: u64, denominator: u64) -> ApiResult<u64> {
    if value == 0 || numerator == 0 {
        return Ok(0);
    }

    Ok(apply_multiplier_u64(value, numerator, denominator)?.max(1))
}

fn prepare_transaction_params_from_estimate_with_tip(
    nonce: Felt,
    fee_estimate: &starknet_rust::core::types::FeeEstimate,
    tip: u64,
    fee_priority: StarknetFeePriority,
) -> ApiResult<PreparedTransactionParams> {
    let (
        gas_amount_numerator,
        gas_amount_denominator,
        gas_price_numerator,
        gas_price_denominator,
        tip_numerator,
        tip_denominator,
    ) = fee_priority_multipliers(fee_priority);

    Ok(PreparedTransactionParams {
        nonce,
        l1_gas: apply_multiplier_u64(
            fee_estimate.l1_gas_consumed,
            gas_amount_numerator,
            gas_amount_denominator,
        )?,
        l1_gas_price: apply_multiplier_u128(
            fee_estimate.l1_gas_price,
            gas_price_numerator,
            gas_price_denominator,
        )?,
        l2_gas: apply_multiplier_u64(
            fee_estimate.l2_gas_consumed,
            gas_amount_numerator,
            gas_amount_denominator,
        )?,
        l2_gas_price: apply_multiplier_u128(
            fee_estimate.l2_gas_price,
            gas_price_numerator,
            gas_price_denominator,
        )?,
        l1_data_gas: apply_multiplier_u64(
            fee_estimate.l1_data_gas_consumed,
            gas_amount_numerator,
            gas_amount_denominator,
        )?,
        l1_data_gas_price: apply_multiplier_u128(
            fee_estimate.l1_data_gas_price,
            gas_price_numerator,
            gas_price_denominator,
        )?,
        tip: adjust_tip(tip, tip_numerator, tip_denominator)?,
    })
}

async fn prepare_transaction_params_from_fee_estimate(
    provider: &JsonRpcClient<HttpTransport>,
    nonce: Felt,
    fee_estimate: starknet_rust::core::types::FeeEstimate,
    fee_priority: StarknetFeePriority,
) -> ApiResult<PreparedTransactionParams> {
    let tip = fetch_latest_block_tip(provider).await?;
    prepare_transaction_params_from_estimate_with_tip(nonce, &fee_estimate, tip, fee_priority)
}

fn calculate_overall_fee_from_params(params: &PreparedTransactionParams) -> BigUint {
    (BigUint::from(params.l1_gas) * BigUint::from(params.l1_gas_price))
        + (BigUint::from(params.l2_gas) * BigUint::from(params.l2_gas_price))
        + (BigUint::from(params.l1_data_gas) * BigUint::from(params.l1_data_gas_price))
}

fn build_invoke_transaction_hash<S>(
    account: &SingleOwnerAccount<JsonRpcClient<HttpTransport>, S>,
    calls: Vec<Call>,
    params: &PreparedTransactionParams,
) -> ApiResult<Felt>
where
    S: Signer + Sync + Send,
{
    let invocation = account
        .execute_v3(calls)
        .nonce(params.nonce)
        .l1_gas(params.l1_gas)
        .l1_gas_price(params.l1_gas_price)
        .l2_gas(params.l2_gas)
        .l2_gas_price(params.l2_gas_price)
        .l1_data_gas(params.l1_data_gas)
        .l1_data_gas_price(params.l1_data_gas_price)
        .tip(params.tip)
        .prepared()
        .map_err(|_| "failed to prepare invoke request".to_string())?;

    Ok(invocation.transaction_hash(false))
}

fn build_deploy_transaction_hash<S>(
    factory: &OpenZeppelinAccountFactory<S, JsonRpcClient<HttpTransport>>,
    public_key: Felt,
    params: &PreparedTransactionParams,
) -> ApiResult<Felt>
where
    S: Signer + Sync + Send,
{
    let deployment = factory
        .deploy_v3(public_key)
        .nonce(params.nonce)
        .l1_gas(params.l1_gas)
        .l1_gas_price(params.l1_gas_price)
        .l2_gas(params.l2_gas)
        .l2_gas_price(params.l2_gas_price)
        .l1_data_gas(params.l1_data_gas)
        .l1_data_gas_price(params.l1_data_gas_price)
        .tip(params.tip)
        .prepared()
        .map_err(|_| "failed to prepare deploy account request".to_string())?;

    Ok(deployment.transaction_hash(false))
}

fn parse_signature_hex(r_hex: &str, s_hex: &str, label: &str) -> ApiResult<Signature> {
    Ok(Signature {
        r: parse_felt_hex(r_hex, &format!("{label}_r_hex"))?,
        s: parse_felt_hex(s_hex, &format!("{label}_s_hex"))?,
    })
}

fn build_execution_calls(calls: Vec<StarknetCallInput>) -> ApiResult<Vec<Call>> {
    calls
        .into_iter()
        .enumerate()
        .map(|(index, call)| {
            let contract_address = parse_felt_hex(
                &call.contract_address_hex,
                &format!("calls[{index}].contractAddress"),
            )?;
            let selector = parse_entrypoint_selector(&call.entrypoint, index)?;
            let calldata = call
                .calldata_hex
                .iter()
                .enumerate()
                .map(|(calldata_index, value)| {
                    parse_felt_hex(value, &format!("calls[{index}].calldata[{calldata_index}]"))
                })
                .collect::<ApiResult<Vec<_>>>()?;

            Ok(Call {
                to: contract_address,
                selector,
                calldata,
            })
        })
        .collect()
}

fn parse_entrypoint_selector(value: &str, index: usize) -> ApiResult<Felt> {
    if value.starts_with("0x") || value.starts_with("0X") {
        parse_felt_hex(value, &format!("calls[{index}].entrypoint"))
    } else {
        get_selector_from_name(value)
            .map_err(|err| format!("Invalid calls[{index}].entrypoint `{value}`: {err}"))
    }
}

fn transfer_calldata_hex(
    recipient_address_hex: String,
    amount_wei: String,
) -> ApiResult<Vec<String>> {
    let recipient_address = parse_felt_hex(&recipient_address_hex, "recipient_address_hex")?;
    Ok(transfer_calldata(recipient_address, &amount_wei)?
        .into_iter()
        .map(felt_to_hex)
        .collect())
}

fn transfer_calldata(recipient_address: Felt, amount_wei: &str) -> ApiResult<Vec<Felt>> {
    let amount = parse_decimal_biguint(amount_wei, "amount_wei")?;
    let (low, high) = biguint_to_uint256_words(&amount)?;
    Ok(vec![recipient_address, low, high])
}

fn parse_decimal_biguint(value: &str, field_name: &str) -> ApiResult<BigUint> {
    BigUint::parse_bytes(value.as_bytes(), 10)
        .ok_or_else(|| format!("Invalid decimal {field_name} `{value}`"))
}

fn biguint_to_uint256_words(value: &BigUint) -> ApiResult<(Felt, Felt)> {
    let bytes = value.to_bytes_be();
    if bytes.len() > 32 {
        return Err("uint256 value is too large".to_string());
    }

    let mut padded = [0u8; 32];
    padded[(32 - bytes.len())..].copy_from_slice(&bytes);

    let high = u128::from_be_bytes(padded[0..16].try_into().unwrap());
    let low = u128::from_be_bytes(padded[16..32].try_into().unwrap());

    Ok((Felt::from(low), Felt::from(high)))
}

fn uint256_from_call_result(values: &[Felt]) -> BigUint {
    let low = values.first().copied().unwrap_or(Felt::ZERO);
    let high = values.get(1).copied().unwrap_or(Felt::ZERO);
    uint256_from_words(low, high)
}

fn uint256_from_words(low: Felt, high: Felt) -> BigUint {
    (felt_to_biguint(high) << 128usize) | felt_to_biguint(low)
}

fn felt_to_biguint(value: Felt) -> BigUint {
    BigUint::from_bytes_be(&value.to_bytes_be())
}

fn felt_to_usize(value: Felt) -> Result<usize, ()> {
    felt_to_biguint(value)
        .to_string()
        .parse::<usize>()
        .map_err(|_| ())
}

fn felt_to_short_string(value: Felt) -> String {
    let bytes = value.to_bytes_be();
    let start = bytes
        .iter()
        .position(|byte| *byte != 0)
        .unwrap_or(bytes.len());
    String::from_utf8_lossy(&bytes[start..])
        .trim_matches('\u{0}')
        .to_string()
}

async fn call_token_string(
    provider: &JsonRpcClient<HttpTransport>,
    token_address: Felt,
    entrypoint: &str,
) -> ApiResult<String> {
    let selector = get_selector_from_name(entrypoint).map_err(|err| err.to_string())?;
    let result = provider
        .call(
            FunctionCall {
                contract_address: token_address,
                entry_point_selector: selector,
                calldata: vec![],
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .map_err(format_provider_error)?;

    if let Ok(value) = ByteArray::decode(&result).and_then(|value| {
        String::try_from(value).map_err(|err| {
            starknet_rust::core::codec::Error::custom(format!("Invalid UTF-8 token string: {err}"))
        })
    }) {
        if !value.is_empty() {
            return Ok(value);
        }
    }

    result
        .first()
        .copied()
        .map(felt_to_short_string)
        .filter(|value| !value.is_empty())
        .ok_or_else(|| format!("Missing token {entrypoint} response"))
}

async fn call_token_decimals(
    provider: &JsonRpcClient<HttpTransport>,
    token_address: Felt,
) -> ApiResult<i32> {
    let selector = get_selector_from_name("decimals").map_err(|err| err.to_string())?;
    let result = provider
        .call(
            FunctionCall {
                contract_address: token_address,
                entry_point_selector: selector,
                calldata: vec![],
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .map_err(format_provider_error)?;

    let decimals = result
        .first()
        .copied()
        .ok_or_else(|| "Missing token decimals response".to_string())?;
    felt_to_biguint(decimals)
        .to_string()
        .parse::<i32>()
        .map_err(|_| "Token decimals do not fit in i32".to_string())
}

async fn is_account_deployed_with_provider(
    provider: &JsonRpcClient<HttpTransport>,
    account_address: Felt,
) -> ApiResult<bool> {
    match provider
        .get_class_hash_at(BlockId::Tag(BlockTag::Latest), account_address)
        .await
    {
        Ok(_) => Ok(true),
        Err(ProviderError::StarknetError(StarknetError::ContractNotFound)) => Ok(false),
        Err(err) => Err(format_provider_error(err)),
    }
}

async fn fetch_paginated_transfer_events(
    provider: &JsonRpcClient<HttpTransport>,
    filter: EventFilter,
    is_outgoing: bool,
    token_symbol: String,
    max_pages: usize,
    events: &mut Vec<TransferEventRecord>,
) {
    let mut continuation_token = None;
    let mut page_count = 0usize;

    loop {
        let result = provider
            .get_events(
                filter.clone(),
                continuation_token.clone(),
                DEFAULT_PAGE_SIZE,
            )
            .await;

        let page = match result {
            Ok(page) => page,
            Err(_) => break,
        };

        for event in page.events {
            events.push(parse_transfer_event(
                event,
                is_outgoing,
                token_symbol.clone(),
            ));
        }

        continuation_token = page.continuation_token;
        page_count += 1;
        if continuation_token.is_none() || page_count >= max_pages {
            break;
        }
    }
}

fn parse_transfer_event(
    event: EmittedEvent,
    is_outgoing: bool,
    token_symbol: String,
) -> TransferEventRecord {
    let low = event.data.first().copied().unwrap_or(Felt::ZERO);
    let high = event.data.get(1).copied().unwrap_or(Felt::ZERO);

    TransferEventRecord {
        transaction_hash: event.transaction_hash,
        event_index: event.event_index,
        block_number: event.block_number,
        from: event
            .keys
            .get(1)
            .copied()
            .map(felt_to_hex)
            .unwrap_or_default(),
        to: event
            .keys
            .get(2)
            .copied()
            .map(felt_to_hex)
            .unwrap_or_default(),
        amount_wei: uint256_from_words(low, high).to_string(),
        is_outgoing,
        token_symbol,
        token_address_hex: felt_to_hex(event.from_address),
    }
}

async fn fetch_block_timestamp(
    provider: &JsonRpcClient<HttpTransport>,
    block_number: u64,
) -> ApiResult<i64> {
    let block = provider
        .get_block_with_tx_hashes(BlockId::Number(block_number))
        .await
        .map_err(format_provider_error)?;

    let timestamp = match block {
        MaybePreConfirmedBlockWithTxHashes::Block(block) => block.timestamp,
        MaybePreConfirmedBlockWithTxHashes::PreConfirmedBlock(block) => block.timestamp,
    };

    i64::try_from(timestamp).map_err(|_| "Block timestamp does not fit in i64".to_string())
}

async fn fetch_transaction_fee(
    provider: &JsonRpcClient<HttpTransport>,
    transaction_hash: Felt,
) -> ApiResult<String> {
    let receipt = provider
        .get_transaction_receipt(transaction_hash)
        .await
        .map_err(format_provider_error)?;
    Ok(actual_fee_from_receipt(&receipt.receipt).to_string())
}

fn actual_fee_from_receipt(receipt: &TransactionReceipt) -> BigUint {
    let fee_amount = match receipt {
        TransactionReceipt::Invoke(inner) => inner.actual_fee.amount,
        TransactionReceipt::L1Handler(inner) => inner.actual_fee.amount,
        TransactionReceipt::Declare(inner) => inner.actual_fee.amount,
        TransactionReceipt::Deploy(inner) => inner.actual_fee.amount,
        TransactionReceipt::DeployAccount(inner) => inner.actual_fee.amount,
    };

    felt_to_biguint(fee_amount)
}

async fn fetch_transaction_details(
    provider: &JsonRpcClient<HttpTransport>,
    transaction_hash: Felt,
) -> ApiResult<StarknetTransactionDetails> {
    let transaction = provider
        .get_transaction_by_hash(transaction_hash, None)
        .await
        .map_err(format_provider_error)?;
    let receipt = provider
        .get_transaction_receipt(transaction_hash)
        .await
        .map_err(format_provider_error)?;
    let summary = summarize_transaction(&transaction)?;
    let block_number = i64::try_from(receipt.block.block_number())
        .map_err(|_| "Block number does not fit in i64".to_string())
        .ok();
    let block_timestamp = if receipt.block.is_pre_confirmed() {
        None
    } else {
        fetch_block_timestamp(provider, receipt.block.block_number())
            .await
            .ok()
    };

    let (execution_status, revert_reason) = match receipt.receipt.execution_result() {
        ExecutionResult::Succeeded => (Some("SUCCEEDED".to_string()), None),
        ExecutionResult::Reverted { reason } => {
            (Some("REVERTED".to_string()), Some(reason.clone()))
        }
    };

    Ok(StarknetTransactionDetails {
        transaction_hash: felt_to_hex(transaction_hash),
        transaction_type: summary.transaction_type,
        is_pending: matches!(
            receipt.receipt.finality_status(),
            TransactionFinalityStatus::PreConfirmed
        ),
        block_number,
        block_timestamp,
        actual_fee_wei: Some(actual_fee_from_receipt(&receipt.receipt).to_string()),
        action_name: summary.action_name,
        call_count: summary.call_count,
        primary_contract_address_hex: summary.primary_contract_address_hex,
        primary_entrypoint: summary.primary_entrypoint,
        sender_address_hex: summary.sender_address_hex,
        finality_status: Some(finality_status_to_string(receipt.receipt.finality_status())),
        execution_status,
        revert_reason,
        account_deployment_required: summary.account_deployment_required,
        l1_gas_max_amount: summary.l1_gas_max_amount,
        l1_gas_max_price_wei: summary.l1_gas_max_price_wei,
        l2_gas_max_amount: summary.l2_gas_max_amount,
        l2_gas_max_price_wei: summary.l2_gas_max_price_wei,
        l1_data_gas_max_amount: summary.l1_data_gas_max_amount,
        l1_data_gas_max_price_wei: summary.l1_data_gas_max_price_wei,
        tip: summary.tip,
    })
}

fn summarize_transaction(transaction: &Transaction) -> ApiResult<DecodedTransactionSummary> {
    match transaction {
        Transaction::Invoke(InvokeTransaction::V0(tx)) => {
            let calls = vec![DecodedInvokeCall {
                contract_address: tx.contract_address,
                selector: tx.entry_point_selector,
                calldata: tx.calldata.clone(),
            }];
            Ok(DecodedTransactionSummary {
                transaction_type: "INVOKE".to_string(),
                action_name: infer_action_name(&calls),
                call_count: Some(1),
                primary_contract_address_hex: Some(felt_to_hex(tx.contract_address)),
                primary_entrypoint: Some(selector_display_name(tx.entry_point_selector)),
                sender_address_hex: Some(felt_to_hex(tx.contract_address)),
                account_deployment_required: false,
                l1_gas_max_amount: None,
                l1_gas_max_price_wei: None,
                l2_gas_max_amount: None,
                l2_gas_max_price_wei: None,
                l1_data_gas_max_amount: None,
                l1_data_gas_max_price_wei: None,
                tip: None,
            })
        }
        Transaction::Invoke(InvokeTransaction::V1(tx)) => Ok(summarize_account_invoke_transaction(
            "INVOKE".to_string(),
            tx.sender_address,
            &tx.calldata,
            None,
            None,
        )),
        Transaction::Invoke(InvokeTransaction::V3(tx)) => Ok(summarize_account_invoke_transaction(
            "INVOKE".to_string(),
            tx.sender_address,
            &tx.calldata,
            Some(&tx.resource_bounds),
            Some(tx.tip),
        )),
        Transaction::DeployAccount(DeployAccountTransaction::V1(_)) => {
            Ok(DecodedTransactionSummary {
                transaction_type: "DEPLOY_ACCOUNT".to_string(),
                action_name: Some("deploy_account".to_string()),
                call_count: Some(1),
                primary_contract_address_hex: None,
                primary_entrypoint: Some("constructor".to_string()),
                sender_address_hex: None,
                account_deployment_required: true,
                l1_gas_max_amount: None,
                l1_gas_max_price_wei: None,
                l2_gas_max_amount: None,
                l2_gas_max_price_wei: None,
                l1_data_gas_max_amount: None,
                l1_data_gas_max_price_wei: None,
                tip: None,
            })
        }
        Transaction::DeployAccount(DeployAccountTransaction::V3(tx)) => {
            Ok(DecodedTransactionSummary {
                transaction_type: "DEPLOY_ACCOUNT".to_string(),
                action_name: Some("deploy_account".to_string()),
                call_count: Some(1),
                primary_contract_address_hex: None,
                primary_entrypoint: Some("constructor".to_string()),
                sender_address_hex: None,
                account_deployment_required: true,
                l1_gas_max_amount: Some(tx.resource_bounds.l1_gas.max_amount.to_string()),
                l1_gas_max_price_wei: Some(
                    tx.resource_bounds.l1_gas.max_price_per_unit.to_string(),
                ),
                l2_gas_max_amount: Some(tx.resource_bounds.l2_gas.max_amount.to_string()),
                l2_gas_max_price_wei: Some(
                    tx.resource_bounds.l2_gas.max_price_per_unit.to_string(),
                ),
                l1_data_gas_max_amount: Some(tx.resource_bounds.l1_data_gas.max_amount.to_string()),
                l1_data_gas_max_price_wei: Some(
                    tx.resource_bounds
                        .l1_data_gas
                        .max_price_per_unit
                        .to_string(),
                ),
                tip: i64::try_from(tx.tip).ok(),
            })
        }
        Transaction::Declare(_) => Ok(DecodedTransactionSummary {
            transaction_type: "DECLARE".to_string(),
            action_name: Some("declare".to_string()),
            call_count: Some(1),
            primary_contract_address_hex: None,
            primary_entrypoint: Some("declare".to_string()),
            sender_address_hex: None,
            account_deployment_required: false,
            l1_gas_max_amount: None,
            l1_gas_max_price_wei: None,
            l2_gas_max_amount: None,
            l2_gas_max_price_wei: None,
            l1_data_gas_max_amount: None,
            l1_data_gas_max_price_wei: None,
            tip: transaction
                .tip()
                .and_then(|value| i64::try_from(value).ok()),
        }),
        Transaction::Deploy(_) => Ok(DecodedTransactionSummary {
            transaction_type: "DEPLOY".to_string(),
            action_name: Some("deploy".to_string()),
            call_count: Some(1),
            primary_contract_address_hex: None,
            primary_entrypoint: Some("constructor".to_string()),
            sender_address_hex: None,
            account_deployment_required: false,
            l1_gas_max_amount: None,
            l1_gas_max_price_wei: None,
            l2_gas_max_amount: None,
            l2_gas_max_price_wei: None,
            l1_data_gas_max_amount: None,
            l1_data_gas_max_price_wei: None,
            tip: None,
        }),
        Transaction::L1Handler(_) => Ok(DecodedTransactionSummary {
            transaction_type: "L1_HANDLER".to_string(),
            action_name: Some("l1_handler".to_string()),
            call_count: Some(1),
            primary_contract_address_hex: None,
            primary_entrypoint: Some("l1_handler".to_string()),
            sender_address_hex: None,
            account_deployment_required: false,
            l1_gas_max_amount: None,
            l1_gas_max_price_wei: None,
            l2_gas_max_amount: None,
            l2_gas_max_price_wei: None,
            l1_data_gas_max_amount: None,
            l1_data_gas_max_price_wei: None,
            tip: None,
        }),
    }
}

fn summarize_account_invoke_transaction(
    transaction_type: String,
    sender_address: Felt,
    calldata: &[Felt],
    resource_bounds: Option<&ResourceBoundsMapping>,
    tip: Option<u64>,
) -> DecodedTransactionSummary {
    let decoded_calls = decode_account_execute_calls(calldata);
    let primary_call = decoded_calls.first();

    DecodedTransactionSummary {
        transaction_type,
        action_name: infer_action_name(&decoded_calls),
        call_count: i32::try_from(decoded_calls.len()).ok(),
        primary_contract_address_hex: primary_call.map(|call| felt_to_hex(call.contract_address)),
        primary_entrypoint: primary_call.map(|call| selector_display_name(call.selector)),
        sender_address_hex: Some(felt_to_hex(sender_address)),
        account_deployment_required: false,
        l1_gas_max_amount: resource_bounds.map(|bounds| bounds.l1_gas.max_amount.to_string()),
        l1_gas_max_price_wei: resource_bounds
            .map(|bounds| bounds.l1_gas.max_price_per_unit.to_string()),
        l2_gas_max_amount: resource_bounds.map(|bounds| bounds.l2_gas.max_amount.to_string()),
        l2_gas_max_price_wei: resource_bounds
            .map(|bounds| bounds.l2_gas.max_price_per_unit.to_string()),
        l1_data_gas_max_amount: resource_bounds
            .map(|bounds| bounds.l1_data_gas.max_amount.to_string()),
        l1_data_gas_max_price_wei: resource_bounds
            .map(|bounds| bounds.l1_data_gas.max_price_per_unit.to_string()),
        tip: tip.and_then(|value| i64::try_from(value).ok()),
    }
}

fn decode_account_execute_calls(calldata: &[Felt]) -> Vec<DecodedInvokeCall> {
    let Some(first) = calldata.first() else {
        return Vec::new();
    };

    let Ok(call_count) = felt_to_usize(*first) else {
        return Vec::new();
    };
    let descriptors_start = 1usize;
    let descriptors_end = descriptors_start.saturating_add(call_count.saturating_mul(4));
    if calldata.len() <= descriptors_end {
        return Vec::new();
    }

    let Ok(flat_calldata_len) = felt_to_usize(calldata[descriptors_end]) else {
        return Vec::new();
    };
    let flat_calldata_start = descriptors_end + 1;
    let flat_calldata_end = flat_calldata_start.saturating_add(flat_calldata_len);
    if calldata.len() < flat_calldata_end {
        return Vec::new();
    }

    let flat_calldata = &calldata[flat_calldata_start..flat_calldata_end];
    let mut decoded = Vec::with_capacity(call_count);

    for index in 0..call_count {
        let base = descriptors_start + index * 4;
        let contract_address = calldata[base];
        let selector = calldata[base + 1];
        let Ok(data_offset) = felt_to_usize(calldata[base + 2]) else {
            return Vec::new();
        };
        let Ok(data_len) = felt_to_usize(calldata[base + 3]) else {
            return Vec::new();
        };
        let data_end = data_offset.saturating_add(data_len);
        if data_end > flat_calldata.len() {
            return Vec::new();
        }

        decoded.push(DecodedInvokeCall {
            contract_address,
            selector,
            calldata: flat_calldata[data_offset..data_end].to_vec(),
        });
    }

    decoded
}

fn infer_action_name(calls: &[DecodedInvokeCall]) -> Option<String> {
    if calls.is_empty() {
        return None;
    }

    let normalized_entrypoints = calls
        .iter()
        .map(|call| action_name_for_selector(call.selector))
        .collect::<Vec<_>>();

    if normalized_entrypoints
        .iter()
        .all(|entrypoint| entrypoint == "transfer")
    {
        return Some("transfer".to_string());
    }

    if normalized_entrypoints
        .iter()
        .all(|entrypoint| entrypoint == "approve")
    {
        return Some("approval".to_string());
    }

    if normalized_entrypoints
        .iter()
        .any(|entrypoint| looks_like_swap_action(entrypoint))
    {
        return Some("swap".to_string());
    }

    if calls.len() > 1 {
        return Some("multicall".to_string());
    }

    normalized_entrypoints.first().cloned()
}

fn selector_display_name(selector: Felt) -> String {
    known_selector_name(selector)
        .map(|name| name.to_string())
        .unwrap_or_else(|| felt_to_hex(selector))
}

fn known_selector_name(selector: Felt) -> Option<&'static str> {
    static KNOWN_SELECTORS: Lazy<Vec<(Felt, &'static str)>> = Lazy::new(|| {
        [
            "transfer",
            "approve",
            "transferFrom",
            "swap",
            "multi_route_swap",
            "exact_input",
            "exact_output",
            "multihop_swap",
            "deposit",
            "withdraw",
            "mint",
            "burn",
            "claim",
            "stake",
            "unstake",
        ]
        .into_iter()
        .filter_map(|name| {
            get_selector_from_name(name)
                .ok()
                .map(|selector| (selector, name))
        })
        .collect()
    });

    KNOWN_SELECTORS
        .iter()
        .find_map(|(known_selector, name)| (*known_selector == selector).then_some(*name))
}

fn action_name_for_selector(selector: Felt) -> String {
    known_selector_name(selector)
        .map(normalize_action_name)
        .filter(|value| !value.is_empty())
        .unwrap_or_else(|| "contract_call".to_string())
}

fn normalize_action_name(value: &str) -> String {
    let mut output = String::with_capacity(value.len());
    let mut previous_was_separator = false;

    for (index, ch) in value.chars().enumerate() {
        if ch == '_' || ch == '-' || ch == ' ' {
            if !output.is_empty() && !previous_was_separator {
                output.push('_');
                previous_was_separator = true;
            }
            continue;
        }

        if ch.is_ascii_uppercase() {
            if index > 0 && !previous_was_separator && !output.ends_with('_') {
                output.push('_');
            }
            output.push(ch.to_ascii_lowercase());
            previous_was_separator = false;
            continue;
        }

        output.push(ch.to_ascii_lowercase());
        previous_was_separator = false;
    }

    output.trim_matches('_').to_string()
}

fn looks_like_swap_action(value: &str) -> bool {
    value.contains("swap") || value.contains("exact_input") || value.contains("exact_output")
}

fn finality_status_to_string(status: &TransactionFinalityStatus) -> String {
    match status {
        TransactionFinalityStatus::PreConfirmed => "PRE_CONFIRMED".to_string(),
        TransactionFinalityStatus::AcceptedOnL2 => "ACCEPTED_ON_L2".to_string(),
        TransactionFinalityStatus::AcceptedOnL1 => "ACCEPTED_ON_L1".to_string(),
    }
}

async fn wait_for_transaction(node_url: &str, tx_hash: Felt) -> ApiResult<()> {
    let provider = make_provider(node_url)?;
    let deadline = tokio::time::Instant::now() + WAIT_FOR_TRANSACTION_TIMEOUT;

    loop {
        match provider.get_transaction_receipt(tx_hash).await {
            Ok(receipt) => {
                return match receipt.receipt.execution_result() {
                    ExecutionResult::Succeeded => Ok(()),
                    ExecutionResult::Reverted { reason } => {
                        Err(format!("Transaction reverted: {reason}"))
                    }
                };
            }
            Err(ProviderError::StarknetError(StarknetError::TransactionHashNotFound)) => {}
            Err(err) => return Err(format_provider_error(err)),
        }

        if tokio::time::Instant::now() >= deadline {
            return Err(format!(
                "Timed out while waiting for transaction {}",
                felt_to_hex(tx_hash)
            ));
        }

        tokio::time::sleep(WAIT_FOR_TRANSACTION_POLL_INTERVAL).await;
    }
}

fn format_provider_error(error: ProviderError) -> String {
    match error {
        ProviderError::StarknetError(error) => format_starknet_error(error),
        other => format!("{other:?}"),
    }
}

fn format_starknet_error(error: StarknetError) -> String {
    let base = format!("StarknetRpcError({}): {}", error.code(), error.message());

    match error {
        StarknetError::TransactionExecutionError(data) => {
            format!("{base}: {:?}", data.execution_error)
        }
        StarknetError::ContractError(data) => format!("{base}: {data:?}"),
        StarknetError::InvalidTransactionNonce(data) => format!("{base}: {data:?}"),
        StarknetError::ValidationFailure(data) => format!("{base}: {data:?}"),
        StarknetError::CompilationFailed(data) => format!("{base}: {data:?}"),
        StarknetError::UnexpectedError(data) => format!("{base}: {data:?}"),
        StarknetError::NoTraceAvailable(data) => format!("{base}: {data:?}"),
        _ => base,
    }
}

fn format_account_error<E: std::fmt::Display>(error: E) -> String {
    error.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_MNEMONIC: &str =
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    const TEST_CLASS_HASH: &str =
        "0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381";

    #[test]
    fn derivation_is_deterministic() {
        let account_1 = derive_account_inner(
            Some(TEST_MNEMONIC.to_string()),
            None,
            None,
            TEST_CLASS_HASH.to_string(),
        )
        .unwrap();
        let account_2 = derive_account_inner(
            Some(TEST_MNEMONIC.to_string()),
            None,
            None,
            TEST_CLASS_HASH.to_string(),
        )
        .unwrap();

        assert_eq!(account_1, account_2);
    }

    #[test]
    fn passphrase_changes_derived_account() {
        let no_passphrase = derive_account_inner(
            Some(TEST_MNEMONIC.to_string()),
            None,
            None,
            TEST_CLASS_HASH.to_string(),
        )
        .unwrap();
        let with_passphrase = derive_account_inner(
            Some(TEST_MNEMONIC.to_string()),
            Some("cake-wallet".to_string()),
            None,
            TEST_CLASS_HASH.to_string(),
        )
        .unwrap();

        assert_ne!(no_passphrase, with_passphrase);
    }

    #[test]
    fn signing_and_verification_round_trip() {
        let account = derive_account_inner(
            Some(TEST_MNEMONIC.to_string()),
            None,
            None,
            TEST_CLASS_HASH.to_string(),
        )
        .unwrap();
        let signature =
            sign_message_hash_inner(account.private_key_hex.clone(), "0xdeadbeef".to_string())
                .unwrap();

        assert!(verify_message_hash_signature_inner(
            account.public_key_hex,
            "0xdeadbeef".to_string(),
            signature.r_hex,
            signature.s_hex,
        )
        .unwrap());
    }

    #[test]
    fn decimal_to_uint256_words_round_trip() {
        let amount = parse_decimal_biguint("12345678901234567890", "amount").unwrap();
        let (low, high) = biguint_to_uint256_words(&amount).unwrap();

        assert_eq!(
            uint256_from_words(low, high).to_string(),
            amount.to_string()
        );
    }
}
