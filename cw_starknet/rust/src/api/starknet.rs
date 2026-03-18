use std::{
    collections::{HashMap, HashSet},
    future::Future,
    time::Duration,
};

use bip39::{Language, Mnemonic};
use hmac::{Hmac, Mac};
use num_bigint::BigUint;
use once_cell::sync::Lazy;
use sha2::Sha256;
use starknet_rust::{
    accounts::{
        Account, AccountFactory, ExecutionEncoding, OpenZeppelinAccountFactory, SingleOwnerAccount,
    },
    core::{
        chain_id,
        crypto::Signature,
        types::{
            AddressFilter, BlockId, BlockTag, Call, EmittedEvent, EventFilter, ExecutionResult,
            Felt, FunctionCall, MaybePreConfirmedBlockWithTxHashes, StarknetError,
            TransactionReceipt,
        },
        utils::{get_contract_address, get_selector_from_name},
    },
    providers::{
        jsonrpc::{HttpTransport, JsonRpcClient},
        Provider, ProviderError, Url,
    },
    signers::{LocalWallet, SigningKey, VerifyingKey},
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
    pub block_number: Option<i64>,
    pub from: String,
    pub to: String,
    pub amount_wei: String,
    pub is_outgoing: bool,
    pub token_symbol: String,
    pub block_timestamp: Option<i64>,
    pub tx_fee_wei: Option<String>,
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

#[derive(Clone, Debug)]
struct TransferEventRecord {
    transaction_hash: Felt,
    block_number: Option<u64>,
    from: String,
    to: String,
    amount_wei: String,
    is_outgoing: bool,
    token_symbol: String,
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
        let provider = make_provider(&node_url)?;
        let private_key = parse_private_key(&private_key_hex)?;
        let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
        let recipient_address = parse_felt_hex(&recipient_address_hex, "recipient_address_hex")?;
        let token_address = parse_felt_hex(&token_address_hex, "token_address_hex")?;
        let chain_id = parse_chain_id(chain_id_hex.as_deref())?;
        let calldata = transfer_calldata(recipient_address, &amount_wei)?;
        let call = transfer_call(token_address, calldata)?;

        let account = SingleOwnerAccount::new(
            provider,
            LocalWallet::from(SigningKey::from_secret_scalar(private_key)),
            account_address,
            chain_id,
            ExecutionEncoding::New,
        );

        let fee = account
            .execute_v3(vec![call])
            .gas_estimate_multiplier(1.5)
            .gas_price_estimate_multiplier(1.5)
            .estimate_fee()
            .await
            .map_err(format_account_error)?;

        Ok(fee.overall_fee.to_string())
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
        let private_key = parse_private_key(&private_key_hex)?;
        let account_address = parse_felt_hex(&account_address_hex, "account_address_hex")?;
        let recipient_address = parse_felt_hex(&recipient_address_hex, "recipient_address_hex")?;
        let token_address = parse_felt_hex(&token_address_hex, "token_address_hex")?;
        let account_class_hash =
            parse_felt_hex(&account_class_hash_hex, "account_class_hash_hex")?;
        let chain_id = parse_chain_id(chain_id_hex.as_deref())?;
        let signing_key = SigningKey::from_secret_scalar(private_key);
        let public_key = signing_key.verifying_key().scalar();

        let deployment_provider = make_provider(&node_url)?;
        if !is_account_deployed_with_provider(&deployment_provider, account_address).await? {
            let factory = OpenZeppelinAccountFactory::new(
                account_class_hash,
                chain_id,
                LocalWallet::from(signing_key.clone()),
                deployment_provider,
            )
            .await
            .map_err(|_| "failed to derive Starknet public key".to_string())?;
            let deployment = factory
                .deploy_v3(public_key)
                .gas_estimate_multiplier(1.5)
                .gas_price_estimate_multiplier(1.5);

            let deployment_result = deployment.send().await.map_err(format_account_factory_error)?;
            wait_for_transaction(&node_url, deployment_result.transaction_hash).await?;
        }

        let provider = make_provider(&node_url)?;
        let calldata = transfer_calldata(recipient_address, &amount_wei)?;
        let call = transfer_call(token_address, calldata)?;
        let account = SingleOwnerAccount::new(
            provider,
            LocalWallet::from(signing_key),
            account_address,
            chain_id,
            ExecutionEncoding::New,
        );

        let invoke_result = account
            .execute_v3(vec![call])
            .gas_estimate_multiplier(1.5)
            .gas_price_estimate_multiplier(1.5)
            .send()
            .await
            .map_err(format_account_error)?;

        wait_for_transaction(&node_url, invoke_result.transaction_hash).await?;
        Ok(felt_to_hex(invoke_result.transaction_hash))
    }))
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
            let dedupe_key = format!("{:#x}_{}", event.transaction_hash, event.is_outgoing);
            if seen.insert(dedupe_key) {
                deduped.push(event);
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
            tx_fees.insert(tx_hash, fetch_transaction_fee(&provider, tx_hash).await.ok());
        }

        Ok(deduped
            .into_iter()
            .map(|event| TransferHistoryItem {
                transaction_hash: felt_to_hex(event.transaction_hash),
                block_number: event.block_number.and_then(|value| i64::try_from(value).ok()),
                from: event.from,
                to: event.to,
                amount_wei: event.amount_wei,
                is_outgoing: event.is_outgoing,
                token_symbol: event.token_symbol,
                block_timestamp: event
                    .block_number
                    .and_then(|value| block_timestamps.get(&value).copied().flatten()),
                tx_fee_wei: tx_fees.get(&event.transaction_hash).cloned().flatten(),
            })
            .collect())
    }))
}

pub fn get_block_number(node_url: String) -> I64Response {
    I64Response::from_result(run_async(async move {
        let provider = make_provider(&node_url)?;
        let block_number = provider.block_number().await.map_err(format_provider_error)?;
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
    let account_address = get_contract_address(
        public_key,
        account_class_hash,
        &[public_key],
        Felt::ZERO,
    );

    Ok(DerivedAccountData {
        private_key_hex: felt_to_hex(private_key),
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

fn run_async<F, T>(future: F) -> ApiResult<T>
where
    F: Future<Output = ApiResult<T>>,
{
    TOKIO_RUNTIME.block_on(future)
}

fn make_provider(node_url: &str) -> ApiResult<JsonRpcClient<HttpTransport>> {
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

fn transfer_call(token_address: Felt, calldata: Vec<Felt>) -> ApiResult<Call> {
    Ok(Call {
        to: token_address,
        selector: get_selector_from_name("transfer").map_err(|err| err.to_string())?,
        calldata,
    })
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
            .get_events(filter.clone(), continuation_token.clone(), DEFAULT_PAGE_SIZE)
            .await;

        let page = match result {
            Ok(page) => page,
            Err(_) => break,
        };

        for event in page.events {
            events.push(parse_transfer_event(event, is_outgoing, token_symbol.clone()));
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
        block_number: event.block_number,
        from: event.keys.get(1).copied().map(felt_to_hex).unwrap_or_default(),
        to: event.keys.get(2).copied().map(felt_to_hex).unwrap_or_default(),
        amount_wei: uint256_from_words(low, high).to_string(),
        is_outgoing,
        token_symbol,
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
        other => other.to_string(),
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

fn format_account_error<E>(error: E) -> String
where
    E: std::fmt::Display,
{
    error.to_string()
}

fn format_account_factory_error<E>(error: E) -> String
where
    E: std::fmt::Display,
{
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

        assert_eq!(uint256_from_words(low, high).to_string(), amount.to_string());
    }
}
