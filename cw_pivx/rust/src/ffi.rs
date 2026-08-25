//! FFI bindings for Dart/Flutter integration.
//!
//! This module provides C-compatible FFI functions that can be called
//! from Dart using dart:ffi.
//!
//! Function names use `cw_pivx_*` prefix for Cake Wallet compatibility.

use group::GroupEncoding;
use lazy_static::lazy_static;
use std::ffi::{c_char, CStr, CString};
use std::ptr;
use std::slice;
use std::sync::Mutex;
use zeroize::Zeroize;

use sapling::{
    keys::PreparedIncomingViewingKey,
    note::ExtractedNoteCommitment,
    note_encryption::{try_sapling_note_decryption, SaplingDomain, Zip212Enforcement},
    Node,
};
use zcash_note_encryption::{EphemeralKeyBytes, ShieldedOutput, ENC_CIPHERTEXT_SIZE};

use crate::keys::{validate_address, SaplingKeyManager};
use crate::notes::SpendableNote;
use crate::sync::SyncState;
use crate::types::Network;

/// A simple output wrapper that implements ShieldedOutput for trial decryption.
/// This allows us to trial decrypt outputs from raw bytes without needing
/// a full OutputDescription with proof.
struct TrialDecryptionOutput {
    ephemeral_key: EphemeralKeyBytes,
    cmu: ExtractedNoteCommitment,
    enc_ciphertext: [u8; ENC_CIPHERTEXT_SIZE],
}

impl ShieldedOutput<SaplingDomain, ENC_CIPHERTEXT_SIZE> for TrialDecryptionOutput {
    fn ephemeral_key(&self) -> EphemeralKeyBytes {
        self.ephemeral_key.clone()
    }

    fn cmstar_bytes(&self) -> [u8; 32] {
        self.cmu.to_bytes()
    }

    fn enc_ciphertext(&self) -> &[u8; ENC_CIPHERTEXT_SIZE] {
        &self.enc_ciphertext
    }
}

lazy_static! {
    static ref KEY_MANAGERS: Mutex<Vec<Option<SaplingKeyManager>>> = Mutex::new(Vec::new());
    static ref SYNC_STATES: Mutex<Vec<Option<SyncState>>> = Mutex::new(Vec::new());
    static ref LAST_ERROR: Mutex<Option<String>> = Mutex::new(None);
}

/// Helper macro for acquiring mutex locks with poison handling.
/// If a mutex is poisoned (thread panicked while holding it), this returns
/// an appropriate error value instead of panicking the entire application.
///
/// Usage: lock_or_fail!(MUTEX, error_return_value)
macro_rules! lock_or_fail {
    ($mutex:expr, $error_return:expr) => {
        match $mutex.lock() {
            Ok(guard) => guard,
            Err(_poisoned) => {
                // Mutex is poisoned, a previous thread panicked while holding it.
                // We cannot safely use the data, so return an error.
                // Use set_error_safe to avoid recursive poison if LAST_ERROR is also poisoned.
                set_error_safe("Internal state corrupted (mutex poisoned). Please restart wallet.");
                return $error_return;
            }
        }
    };
}

/// Safely set error message, handling the case where LAST_ERROR mutex itself is poisoned.
/// This prevents cascading panics when reporting errors.
fn set_error_safe(msg: &str) {
    if let Ok(mut error) = LAST_ERROR.lock() {
        *error = Some(msg.to_string());
    }
    // If LAST_ERROR is poisoned, silently fail; we cannot report the error,
    // but at least we don't crash the application.
}

/// Set the last error message.
/// Use this for normal error reporting. If the mutex is poisoned, this will
/// set a generic "corrupted state" error instead of the specific message.
fn set_error(msg: &str) {
    let mut error = lock_or_fail!(LAST_ERROR, ());
    *error = Some(msg.to_string());
}

/// Safely convert an i64 handle to usize index with validation.
/// Returns None if the handle is negative or too large for usize.
fn handle_to_index(handle: i64) -> Option<usize> {
    if handle < 0 {
        return None;
    }
    // On 32-bit systems, check if handle fits in usize
    #[cfg(target_pointer_width = "32")]
    {
        if handle > usize::MAX as i64 {
            return None;
        }
    }
    Some(handle as usize)
}

/// Macro to validate a handle and get the corresponding item from a Vec<Option<T>>.
/// Returns with error_return if handle is invalid or out of bounds.
macro_rules! get_from_handle {
    ($handle:expr, $vec:expr, $error_return:expr, $item_name:expr) => {{
        let idx = match handle_to_index($handle) {
            Some(i) => i,
            None => {
                set_error(&format!("Invalid {}: must be non-negative", $item_name));
                return $error_return;
            }
        };
        match $vec.get(idx).and_then(|item| item.as_ref()) {
            Some(item) => item,
            None => {
                if idx >= $vec.len() {
                    set_error(&format!("Invalid {}: out of range", $item_name));
                } else {
                    set_error(&format!("{} has been disposed", $item_name));
                }
                return $error_return;
            }
        }
    }};
}

/// Get and clear the last error message.
#[no_mangle]
pub extern "C" fn cw_pivx_get_last_error() -> *mut c_char {
    let mut error = lock_or_fail!(LAST_ERROR, ptr::null_mut());
    match error.take() {
        Some(msg) => {
            // Replace null bytes with spaces if any (should never happen in error messages)
            let sanitized = msg.replace('\0', " ");
            CString::new(sanitized)
                .expect("Error message sanitized: no null bytes")
                .into_raw()
        }
        None => ptr::null_mut(),
    }
}

/// Helper to safely extract fixed-size byte array from FFI pointer.
/// Returns error string if pointer is null or size doesn't match.
unsafe fn bytes_from_ffi_ptr<const N: usize>(
    ptr: *const u8,
    param_name: &str,
) -> Result<[u8; N], String> {
    if ptr.is_null() {
        return Err(format!("{} is null", param_name));
    }
    let slice = slice::from_raw_parts(ptr, N);
    slice
        .try_into()
        .map_err(|_| format!("{} size mismatch (expected {} bytes)", param_name, N))
}

/// Validate fee is reasonable.
/// Fee must be at least 10,000 zatoshis (0.0001 PIV). No absolute upper cap:
/// the Dart policy scales the fee with serialized size (100 zat/byte), so a
/// large shield/unshield (many inputs/outputs) legitimately exceeds 1 PIV, and
/// PIVX Core imposes no absolute fee cap.
fn validate_fee(fee: u64) -> Result<(), String> {
    const MIN_FEE: u64 = 10_000; // 0.0001 PIV
    if fee < MIN_FEE {
        return Err(format!("Fee too low (min {} zatoshis)", MIN_FEE));
    }
    Ok(())
}

/// Validate a shielded output amount.
///
/// PIVX Core v5.6.1 computes shielded dust as:
/// DEFAULT_SHIELDEDTXFEE_K * dustRelayFee.GetFee(SPENDDESCRIPTION_SIZE
/// + CTXOUT_REGULAR_SIZE + BINDINGSIG_SIZE), which is 1,446,000 zatoshis.
fn validate_shielded_amount(amount: u64, param_name: &str) -> Result<(), String> {
    const MAX_REASONABLE: u64 = 10_000_000_000_000_000_000; // 100 billion PIV
    const SHIELDED_DUST_THRESHOLD: u64 = 1_446_000;

    if amount == 0 {
        return Err(format!("{} cannot be zero", param_name));
    }
    if amount < SHIELDED_DUST_THRESHOLD {
        return Err(format!(
            "{} is below shielded dust threshold ({} zatoshis)",
            param_name, SHIELDED_DUST_THRESHOLD
        ));
    }
    if amount > MAX_REASONABLE {
        return Err(format!("{} exceeds maximum reasonable amount", param_name));
    }
    Ok(())
}

/// Validate string length is within reasonable bounds.
/// This prevents DoS attacks via extremely long strings.
fn validate_string_length(s: &str, max_len: usize, param_name: &str) -> Result<(), String> {
    if s.len() > max_len {
        return Err(format!(
            "{} too long (max {} chars, got {})",
            param_name,
            max_len,
            s.len()
        ));
    }
    Ok(())
}

/// Validate memo length (max 512 bytes for Sapling).
fn validate_memo(memo: Option<&str>) -> Result<(), String> {
    if let Some(m) = memo {
        if m.len() > 512 {
            return Err(format!("Memo too long (max 512 bytes, got {})", m.len()));
        }
    }
    Ok(())
}

#[no_mangle]
pub extern "C" fn cw_pivx_version() -> *mut c_char {
    CString::new(env!("CARGO_PKG_VERSION"))
        .expect("Version string is valid: no null bytes")
        .into_raw()
}

/// Overwrite FFI-owned memory before returning it to the allocator.
pub(crate) unsafe fn zero_ffi_allocation(ptr: *mut u8, len: usize) {
    if ptr.is_null() || len == 0 {
        return;
    }

    for offset in 0..len {
        ptr.add(offset).write_volatile(0);
    }
}

/// Copy a Rust-owned string into an FFI buffer, then zero the Rust staging copy.
fn ffi_buffer_from_string(mut value: String) -> Option<FFIBuffer> {
    let len = value.len();
    let data = unsafe {
        let ptr = libc::malloc(len) as *mut u8;
        if ptr.is_null() {
            value.zeroize();
            return None;
        }
        ptr::copy_nonoverlapping(value.as_ptr(), ptr, len);
        ptr
    };

    value.zeroize();
    Some(FFIBuffer { data, len })
}

/// Free a string allocated by this library.
#[no_mangle]
pub extern "C" fn cw_pivx_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let len = CStr::from_ptr(ptr).to_bytes_with_nul().len();
            zero_ffi_allocation(ptr.cast::<u8>(), len);
            let _ = CString::from_raw(ptr);
        }
    }
}

// Also provide the old name for compatibility
#[no_mangle]
pub extern "C" fn pivx_sapling_free_string(ptr: *mut c_char) {
    cw_pivx_free_string(ptr);
}

/// FFI buffer for returning binary data.
#[repr(C)]
pub struct FFIBuffer {
    pub data: *mut u8,
    pub len: usize,
}

/// Free a buffer allocated by this library.
#[no_mangle]
pub extern "C" fn cw_pivx_free_buffer(buffer: FFIBuffer) {
    if !buffer.data.is_null() && buffer.len > 0 {
        unsafe {
            zero_ffi_allocation(buffer.data, buffer.len);
            libc::free(buffer.data.cast::<libc::c_void>());
        }
    }
}

/// Initialize keys from a seed.
/// Returns a handle for future operations, or -1 on error.
#[no_mangle]
pub extern "C" fn cw_pivx_init_keys(seed: *const u8, seed_len: usize, is_testnet: u8) -> i64 {
    if seed.is_null() || seed_len < 32 {
        set_error("Invalid seed");
        return -1;
    }

    let seed_slice = unsafe { slice::from_raw_parts(seed, seed_len) };
    let network = if is_testnet != 0 {
        Network::Testnet
    } else {
        Network::Mainnet
    };

    match SaplingKeyManager::from_seed(seed_slice, network) {
        Ok(manager) => {
            let mut managers = lock_or_fail!(KEY_MANAGERS, -1);

            // Find first available slot (reuse disposed handles) or create new
            let id = managers
                .iter()
                .position(|m| m.is_none())
                .unwrap_or_else(|| {
                    managers.push(None);
                    managers.len() - 1
                }) as i64;

            managers[id as usize] = Some(manager);

            // Pair a sync state at the same index.
            let mut states = lock_or_fail!(SYNC_STATES, -1);
            while states.len() <= id as usize {
                states.push(None);
            }
            states[id as usize] = Some(SyncState::new());

            id
        }
        Err(e) => {
            set_error(&format!("Failed to create key manager: {:?}", e));
            -1
        }
    }
}

/// Dispose keys.
#[no_mangle]
pub extern "C" fn cw_pivx_dispose_keys(handle: i64) {
    let idx = match handle_to_index(handle) {
        Some(i) => i,
        None => {
            set_error("Invalid handle: must be non-negative");
            return;
        }
    };

    let mut managers = lock_or_fail!(KEY_MANAGERS, ());
    if idx < managers.len() {
        managers[idx] = None;
    }
}

/// Get the default payment address.
#[no_mangle]
pub extern "C" fn cw_pivx_get_default_address(handle: i64) -> *mut c_char {
    let managers = lock_or_fail!(KEY_MANAGERS, ptr::null_mut());
    let manager = get_from_handle!(handle, managers, ptr::null_mut(), "key handle");

    match manager.default_address() {
        Ok(addr) => {
            let encoded = manager.encode_payment_address(&addr);
            CString::new(encoded)
                .expect("Address encoding is valid: no null bytes")
                .into_raw()
        }
        Err(e) => {
            set_error(&format!("Failed to get address: {:?}", e));
            ptr::null_mut()
        }
    }
}

/// Derive an address at a specific index.
#[no_mangle]
pub extern "C" fn cw_pivx_derive_address(handle: i64, index: u64) -> *mut c_char {
    let managers = lock_or_fail!(KEY_MANAGERS, ptr::null_mut());
    let idx = handle as usize;

    if idx >= managers.len() {
        set_error("Invalid handle");
        return ptr::null_mut();
    }

    let manager = match &managers[idx] {
        Some(m) => m,
        None => {
            set_error("Handle disposed");
            return ptr::null_mut();
        }
    };

    let mut div_bytes = [0u8; 11];
    div_bytes[0..8].copy_from_slice(&(index as u64).to_le_bytes());
    let div_index = zcash_primitives::zip32::DiversifierIndex::from(div_bytes);

    match manager.derive_address(div_index) {
        Ok(addr) => {
            let encoded = manager.encode_payment_address(&addr);
            CString::new(encoded)
                .expect("Address encoding is valid: no null bytes")
                .into_raw()
        }
        Err(e) => {
            set_error(&format!("Failed to derive address: {:?}", e));
            ptr::null_mut()
        }
    }
}

/// Get the full viewing key.
#[no_mangle]
pub extern "C" fn cw_pivx_get_viewing_key(handle: i64) -> *mut c_char {
    let managers = lock_or_fail!(KEY_MANAGERS, ptr::null_mut());
    let idx = handle as usize;

    if idx >= managers.len() {
        set_error("Invalid handle");
        return ptr::null_mut();
    }

    let manager = match &managers[idx] {
        Some(m) => m,
        None => {
            set_error("Handle disposed");
            return ptr::null_mut();
        }
    };

    let encoded = manager.encode_full_viewing_key();
    CString::new(encoded)
        .expect("FVK encoding is valid: no null bytes")
        .into_raw()
}

/// Validate a Sapling address.
#[no_mangle]
pub extern "C" fn cw_pivx_validate_address(address: *const c_char, is_testnet: u8) -> u8 {
    if address.is_null() {
        return 0;
    }

    let address_str = unsafe {
        match CStr::from_ptr(address).to_str() {
            Ok(s) => s,
            Err(_) => return 0,
        }
    };

    let network = if is_testnet != 0 {
        Network::Testnet
    } else {
        Network::Mainnet
    };

    if validate_address(address_str, network) {
        1
    } else {
        0
    }
}

/// Initialize sync engine.
#[no_mangle]
pub extern "C" fn cw_pivx_init_sync_engine(_is_testnet: u8) -> i64 {
    let mut states = lock_or_fail!(SYNC_STATES, -1);
    let id = states.len() as i64;
    states.push(Some(SyncState::new()));
    id
}

/// Dispose sync engine.
#[no_mangle]
pub extern "C" fn cw_pivx_dispose_sync_engine(handle: i64) {
    let idx = handle as usize;
    let mut states = lock_or_fail!(SYNC_STATES, ());
    if idx < states.len() {
        states[idx] = None;
    }
}

/// Get the current sync height.
#[no_mangle]
pub extern "C" fn cw_pivx_get_sync_height(handle: i64) -> u32 {
    let states = lock_or_fail!(SYNC_STATES, 0);
    let idx = handle as usize;

    match states.get(idx).and_then(|s| s.as_ref()) {
        Some(state) => state.sync_height(),
        None => 0,
    }
}

/// Get the shielded balance.
#[no_mangle]
pub extern "C" fn cw_pivx_get_shielded_balance(handle: i64) -> u64 {
    let states = lock_or_fail!(SYNC_STATES, 0);
    let idx = handle as usize;

    match states.get(idx).and_then(|s| s.as_ref()) {
        Some(state) => state.shielded_balance(),
        None => 0,
    }
}

/// Get the number of unspent notes.
#[no_mangle]
pub extern "C" fn cw_pivx_get_unspent_note_count(handle: i64) -> usize {
    let states = lock_or_fail!(SYNC_STATES, 0);
    let idx = handle as usize;

    match states.get(idx).and_then(|s| s.as_ref()) {
        Some(state) => state.unspent_notes().len(),
        None => 0,
    }
}

/// Reset sync state.
#[no_mangle]
pub extern "C" fn cw_pivx_reset_sync(handle: i64) {
    let mut states = lock_or_fail!(SYNC_STATES, ());
    let idx = handle as usize;

    if let Some(Some(state)) = states.get_mut(idx) {
        *state = SyncState::new();
    }
}

/// Try to decrypt a Sapling output and add to sync state if successful.
///
/// This is the core function for detecting incoming shielded transactions.
/// It attempts trial decryption of a Sapling output using the wallet's
/// incoming viewing key.
///
/// # Parameters
/// * `key_handle`: Handle from cw_pivx_init_keys
/// * `sync_handle`: Handle from cw_pivx_init_sync_engine
/// * `cmu`: Note commitment (32 bytes)
/// * `epk`: Ephemeral public key (32 bytes)
/// * `enc_ciphertext`: Encrypted ciphertext (580 bytes)
/// * `height`: Block height
/// * `tx_index`: Transaction index in block
/// * `output_index`: Output index in transaction
/// * `position`: Position in commitment tree
///
/// # Returns
/// The note value in zatoshis if decryption succeeds, 0 otherwise.
#[no_mangle]
pub extern "C" fn cw_pivx_try_decrypt_output(
    key_handle: i64,
    sync_handle: i64,
    cmu: *const u8,
    epk: *const u8,
    enc_ciphertext: *const u8,
    height: u32,
    tx_index: u32,
    output_index: u32,
    position: u64,
) -> u64 {
    if cmu.is_null() || epk.is_null() || enc_ciphertext.is_null() {
        set_error("Null pointer provided");
        return 0;
    }

    let managers = lock_or_fail!(KEY_MANAGERS, 0);
    let key_manager = match managers.get(key_handle as usize).and_then(|m| m.as_ref()) {
        Some(m) => m,
        None => {
            set_error("Invalid key handle");
            return 0;
        }
    };

    let cmu_bytes: [u8; 32] = match unsafe { bytes_from_ffi_ptr(cmu, "cmu") } {
        Ok(bytes) => bytes,
        Err(e) => {
            set_error(&e);
            return 0;
        }
    };

    let cmu_extracted = match ExtractedNoteCommitment::from_bytes(&cmu_bytes).into_option() {
        Some(c) => c,
        None => {
            set_error("Invalid note commitment (cmu)");
            return 0; // Invalid commitment: this IS an error, not just "not for us"
        }
    };

    let epk_bytes: [u8; 32] = match unsafe { bytes_from_ffi_ptr(epk, "epk") } {
        Ok(bytes) => bytes,
        Err(e) => {
            set_error(&e);
            return 0;
        }
    };
    let ephemeral_key = EphemeralKeyBytes(epk_bytes);

    let enc_bytes: [u8; ENC_CIPHERTEXT_SIZE] =
        match unsafe { bytes_from_ffi_ptr(enc_ciphertext, "enc_ciphertext") } {
            Ok(bytes) => bytes,
            Err(e) => {
                set_error(&e);
                return 0;
            }
        };

    let output = TrialDecryptionOutput {
        ephemeral_key,
        cmu: cmu_extracted,
        enc_ciphertext: enc_bytes,
    };

    let dfvk = key_manager.diversifiable_full_viewing_key();
    let ivk = dfvk.fvk().vk.ivk();
    let prepared_ivk = PreparedIncomingViewingKey::new(&ivk);

    // PIVX does not enforce ZIP-212 (unlike Zcash post-Canopy); librustpivx's
    // zip212_enforcement() always returns Off.
    let zip212 = Zip212Enforcement::Off;

    let result = try_sapling_note_decryption(&prepared_ivk, &output, zip212);

    match result {
        Some((note, address, memo)) => {
            let value = note.value().inner();
            let nf = note.nf(&dfvk.fvk().vk.nk, position);
            let mut spendable_note =
                SpendableNote::new(note, address, position, nf, height, tx_index, output_index);
            // our send path writes the memo as raw utf8 with zero padding, so
            // strip trailing zeros and read as utf8; an empty memo stays None.
            let end = memo.iter().rposition(|&b| b != 0).map_or(0, |i| i + 1);
            if end > 0 {
                spendable_note.memo = String::from_utf8(memo[..end].to_vec()).ok();
            }

            drop(managers); // release before acquiring SYNC_STATES
            let mut states = lock_or_fail!(SYNC_STATES, 0);
            if let Some(Some(state)) = states.get_mut(sync_handle as usize) {
                let _ = state.add_note(spendable_note);
            }

            value
        }
        None => {
            // not for us, or decryption failed
            0
        }
    }
}

/// Check if a nullifier matches any of our notes and mark them spent.
///
/// # Parameters
/// * `sync_handle`: Handle from cw_pivx_init_sync_engine
/// * `nullifier`: 32-byte nullifier to check
///
/// # Returns
/// 1 if a note was marked spent, 0 otherwise.
#[no_mangle]
pub extern "C" fn cw_pivx_check_nullifier(sync_handle: i64, nullifier: *const u8) -> u8 {
    if nullifier.is_null() {
        return 0;
    }

    let nf_bytes: [u8; 32] = unsafe { slice::from_raw_parts(nullifier, 32) }
        .try_into()
        .unwrap_or([0u8; 32]);

    let nf = match sapling::Nullifier::from_slice(&nf_bytes) {
        Ok(n) => n,
        Err(_) => return 0,
    };

    let mut states = lock_or_fail!(SYNC_STATES, 0);
    if let Some(Some(state)) = states.get_mut(sync_handle as usize) {
        if state.is_nullifier_spent(&nf) {
            return 0; // Already known
        }
        state.add_spent_nullifier(nf);
        return 1;
    }

    0
}

/// Update sync height after processing a block.
#[no_mangle]
pub extern "C" fn cw_pivx_set_sync_height(sync_handle: i64, height: u32) {
    let mut states = lock_or_fail!(SYNC_STATES, ());
    if let Some(Some(state)) = states.get_mut(sync_handle as usize) {
        state.set_sync_height(height);
    }
}

/// Estimate transaction fee.
/// Returns the estimated fee in zatoshis, or u64::MAX if overflow would occur.
#[no_mangle]
pub extern "C" fn cw_pivx_estimate_fee(
    spends: usize,
    outputs: usize,
    t_inputs: usize,
    t_outputs: usize,
) -> u64 {
    // PIVX Core shielded relay policy: size * 10,000 zatoshis/kB * 100, rounded up.
    const MIN_RELAY_FEE_PER_KB: u64 = 10_000;
    const SHIELDED_FEE_FACTOR: u64 = 100;
    const MIN_FEE: u64 = 10_000;
    const SAPLING_SPEND_SIZE: u64 = 384;
    const SAPLING_OUTPUT_SIZE: u64 = 948;
    const TRANSPARENT_INPUT_SIZE: u64 = 148;
    const TRANSPARENT_OUTPUT_SIZE: u64 = 34;
    // Fixed non-count bytes; the four CompactSize vector-count prefixes are
    // added per-vector below so the estimate stays an exact upper bound past
    // 253 elements (below that this equals the old flat 85).
    const SAPLING_FIXED_OVERHEAD_SIZE: u64 = 81;

    // Validate inputs are in reasonable range (prevent overflow attacks)
    const MAX_INPUTS: usize = 10_000;
    if spends > MAX_INPUTS
        || outputs > MAX_INPUTS
        || t_inputs > MAX_INPUTS
        || t_outputs > MAX_INPUTS
    {
        set_error("Too many inputs/outputs for fee calculation");
        return u64::MAX; // Signal error with saturated value
    }

    // The Sapling builder pads shielded outputs to at least MIN_SHIELDED_OUTPUTS
    // with dummy outputs (protocol privacy rule, shared with PIVX Core), so the
    // wire tx has that many even with fewer real outputs.
    const MIN_SHIELDED_OUTPUTS: usize = 2;
    let effective_outputs = outputs.max(MIN_SHIELDED_OUTPUTS);

    // CompactSize prefix length per vector: 1 byte below 253, 3 up to 65535.
    let compact = |n: usize| -> u64 {
        if n < 0xfd {
            1
        } else if n <= 0xffff {
            3
        } else {
            5
        }
    };
    let overhead = SAPLING_FIXED_OVERHEAD_SIZE
        + compact(spends)
        + compact(effective_outputs)
        + compact(t_inputs)
        + compact(t_outputs);

    let size = overhead
        .checked_add((spends as u64).saturating_mul(SAPLING_SPEND_SIZE))
        .and_then(|v| {
            v.checked_add((effective_outputs as u64).saturating_mul(SAPLING_OUTPUT_SIZE))
        })
        .and_then(|v| v.checked_add((t_inputs as u64).saturating_mul(TRANSPARENT_INPUT_SIZE)))
        .and_then(|v| v.checked_add((t_outputs as u64).saturating_mul(TRANSPARENT_OUTPUT_SIZE)));

    match size
        .and_then(|s| s.checked_mul(MIN_RELAY_FEE_PER_KB))
        .and_then(|s| s.checked_mul(SHIELDED_FEE_FACTOR))
    {
        Some(weighted_size) => {
            let fee = weighted_size.saturating_add(999) / 1000;
            fee.max(MIN_FEE)
        }
        None => {
            set_error("Fee calculation overflow");
            u64::MAX
        }
    }
}

/// Check if proving parameters are available.
#[no_mangle]
pub extern "C" fn cw_pivx_has_proving_params(path: *const c_char) -> u8 {
    if path.is_null() {
        return 0;
    }

    let path_str = unsafe {
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return 0,
        }
    };

    if crate::prover::has_proving_params(path_str) {
        1
    } else {
        0
    }
}

/// Initialize the Groth16 prover with the proving parameters.
///
/// This loads the ~50MB proving parameter files into memory.
/// Should be called once before any transaction building.
///
/// # Parameters
/// * `params_dir`: Path to directory containing sapling-spend.params and sapling-output.params
///
/// # Returns
/// 0 on success, negative on error
#[no_mangle]
pub extern "C" fn cw_pivx_init_prover(params_dir: *const c_char) -> i32 {
    if params_dir.is_null() {
        set_error("Null params directory");
        return -1;
    }

    let dir_str = unsafe {
        match CStr::from_ptr(params_dir).to_str() {
            Ok(s) => s,
            Err(_) => {
                set_error("Invalid path encoding");
                return -1;
            }
        }
    };

    match crate::prover::init_prover(dir_str) {
        Ok(()) => 0,
        Err(e) => {
            set_error(&format!("Failed to init prover: {}", e));
            -1
        }
    }
}

/// Check if the prover is initialized.
#[no_mangle]
pub extern "C" fn cw_pivx_is_prover_initialized() -> u8 {
    if crate::prover::is_prover_initialized() {
        1
    } else {
        0
    }
}

/// Free the prover and release memory (~50MB).
#[no_mangle]
pub extern "C" fn cw_pivx_dispose_prover() {
    crate::prover::dispose_prover();
}

// serialize one note to the json shape the dart side stores/spends with.
fn spendable_note_to_json(note: &SpendableNote) -> serde_json::Value {
    // BeforeZip212 rseed is an Fr scalar; AfterZip212 is raw [u8; 32].
    let rseed_bytes = match note.note.rseed() {
        sapling::Rseed::BeforeZip212(fr_value) => hex::encode(fr_value.to_bytes()),
        sapling::Rseed::AfterZip212(bytes) => hex::encode(bytes),
    };
    let recipient = note.note.recipient();
    let addr_bytes = recipient.to_bytes();
    let diversifier_bytes = recipient.diversifier().0;
    let cmu_bytes = note.note.cmu().to_bytes();
    let pk_d_bytes = recipient.pk_d().inner().to_bytes();
    // PIVX is pre-ZIP-212, so rcm == rseed.
    let rcm_bytes = rseed_bytes.clone();

    serde_json::json!({
        "value": note.value(),
        "position": note.position,
        "height": note.height,
        "tx_index": note.tx_index,
        "output_index": note.output_index,
        "nullifier": hex::encode(note.nullifier.0),
        "rseed": rseed_bytes,
        "rcm": rcm_bytes,
        "address": hex::encode(addr_bytes),
        "diversifier": hex::encode(diversifier_bytes),
        "pk_d": hex::encode(pk_d_bytes),
        "cmu": hex::encode(cmu_bytes),
        "memo": note.memo,
    })
}

/// Get all spendable notes from the sync state as JSON.
///
/// Returns a JSON array of note objects, each containing all data
/// needed for transaction building including the rseed and diversifier.
///
/// # Parameters
/// * `sync_handle`: Handle from cw_pivx_init_sync_engine
///
/// # Returns
/// JSON string with note data, or null on error.
/// Caller must free with cw_pivx_free_string.
#[no_mangle]
pub extern "C" fn cw_pivx_get_spendable_notes(sync_handle: i64) -> *mut c_char {
    let states = lock_or_fail!(SYNC_STATES, ptr::null_mut());

    let sync_state = match states.get(sync_handle as usize).and_then(|s| s.as_ref()) {
        Some(s) => s,
        None => {
            set_error("Invalid sync handle");
            return ptr::null_mut();
        }
    };

    let notes_json: Vec<serde_json::Value> = sync_state
        .unspent_notes()
        .iter()
        .map(|note| spendable_note_to_json(note))
        .collect();

    let json_str = serde_json::to_string(&notes_json).unwrap_or_else(|_| "[]".to_string());
    CString::new(json_str)
        .expect("JSON string is valid: no null bytes")
        .into_raw()
}

/// Get the single unspent note at [position] as JSON (the one just decrypted),
/// so the scan loop doesn't re-serialize every note on each match (was O(K^2)
/// over a restore). Returns null if there's no unspent note there.
/// Caller must free with cw_pivx_free_string.
#[no_mangle]
pub extern "C" fn cw_pivx_get_note_at_position(sync_handle: i64, position: u64) -> *mut c_char {
    let states = lock_or_fail!(SYNC_STATES, ptr::null_mut());
    let sync_state = match states.get(sync_handle as usize).and_then(|s| s.as_ref()) {
        Some(s) => s,
        None => {
            set_error("Invalid sync handle");
            return ptr::null_mut();
        }
    };

    match sync_state
        .unspent_notes()
        .into_iter()
        .find(|n| n.position == position)
    {
        Some(note) => {
            let json_str =
                serde_json::to_string(&spendable_note_to_json(note)).unwrap_or_default();
            match CString::new(json_str) {
                Ok(c) => c.into_raw(),
                Err(_) => ptr::null_mut(),
            }
        }
        None => ptr::null_mut(),
    }
}

/// Restore a note from JSON data.
///
/// This allows restoring notes from persistent storage after app restart.
/// The JSON should contain the same fields returned by cw_pivx_get_spendable_notes.
///
/// # Parameters
/// * `key_handle`: Handle from cw_pivx_init_keys
/// * `sync_handle`: Handle from cw_pivx_init_sync_engine
/// * `note_json`: JSON string with note data
///
/// # Returns
/// 1 on success, 0 on failure
#[no_mangle]
pub extern "C" fn cw_pivx_restore_note(
    _key_handle: i64,
    sync_handle: i64,
    note_json: *const c_char,
) -> i32 {
    if note_json.is_null() {
        set_error("Null note JSON");
        return 0;
    }

    let json_str = match unsafe { CStr::from_ptr(note_json).to_str() } {
        Ok(s) => s,
        Err(_) => {
            set_error("Invalid UTF-8 in note JSON");
            return 0;
        }
    };

    let note_data: serde_json::Value = match serde_json::from_str(json_str) {
        Ok(v) => v,
        Err(e) => {
            set_error(&format!("Invalid JSON: {}", e));
            return 0;
        }
    };

    let value = note_data["value"].as_u64().unwrap_or(0);
    let position = note_data["position"].as_u64().unwrap_or(0);
    let height = note_data["height"].as_u64().unwrap_or(0) as u32;
    let tx_index = note_data["tx_index"].as_u64().unwrap_or(0) as u32;
    let output_index = note_data["output_index"].as_u64().unwrap_or(0) as u32;

    let rseed_hex = note_data["rseed"].as_str().unwrap_or("");
    let address_hex = note_data["address"].as_str().unwrap_or("");
    let nullifier_hex = note_data["nullifier"].as_str().unwrap_or("");

    // rseed is a 32-byte Fr scalar (BeforeZip212).
    let rseed_bytes: [u8; 32] = match hex::decode(rseed_hex) {
        Ok(bytes) if bytes.len() == 32 => bytes
            .try_into()
            .expect("Length checked: rseed is exactly 32 bytes"),
        _ => {
            set_error("Invalid rseed");
            return 0;
        }
    };

    // Address is 43 bytes: 11-byte diversifier + 32-byte pk_d.
    let address_bytes: [u8; 43] = match hex::decode(address_hex) {
        Ok(bytes) if bytes.len() == 43 => bytes
            .try_into()
            .expect("Length checked: address is exactly 43 bytes"),
        _ => {
            set_error(&format!(
                "Invalid address: expected 43 bytes, got {} from '{}'",
                hex::decode(address_hex).map(|b| b.len()).unwrap_or(0),
                address_hex
            ));
            return 0;
        }
    };

    let nullifier_bytes: [u8; 32] = match hex::decode(nullifier_hex) {
        Ok(bytes) if bytes.len() == 32 => bytes
            .try_into()
            .expect("Length checked: nullifier is exactly 32 bytes"),
        _ => {
            set_error("Invalid nullifier");
            return 0;
        }
    };

    use sapling::{value::NoteValue, PaymentAddress, Rseed};

    let address = match PaymentAddress::from_bytes(&address_bytes) {
        Some(a) => a,
        None => {
            set_error("Invalid payment address bytes");
            return 0;
        }
    };

    // PIVX uses BeforeZip212.
    let rseed_fr = match jubjub::Fr::from_bytes(&rseed_bytes).into_option() {
        Some(fr) => fr,
        None => {
            set_error("Invalid rseed Fr");
            return 0;
        }
    };
    let rseed = Rseed::BeforeZip212(rseed_fr);

    let note = sapling::Note::from_parts(address, NoteValue::from_raw(value), rseed);
    let nullifier = sapling::Nullifier(nullifier_bytes);

    let spendable_note = SpendableNote::new(
        note,
        address,
        position,
        nullifier,
        height,
        tx_index,
        output_index,
    );

    let mut states = lock_or_fail!(SYNC_STATES, -1);
    if let Some(Some(state)) = states.get_mut(sync_handle as usize) {
        let _ = state.add_note(spendable_note);
        1
    } else {
        set_error("Invalid sync handle");
        0
    }
}

/// Build a transparent-to-shielded (t-to-z, shield) transaction.
///
/// `utxos_json` is an array of objects with `txid` (display hex), `vout`,
/// `value`, `script_pubkey` (hex, P2PKH) and `private_key` (32-byte hex).
/// `change` of zero means no transparent change output; otherwise
/// `change_address` receives it. Amounts must balance exactly:
/// sum(utxos) = amount + change + fee.
#[no_mangle]
pub extern "C" fn cw_pivx_build_shield_tx(
    key_handle: i64,
    utxos_json: *const c_char,
    to_address: *const c_char,
    amount: u64,
    memo: *const c_char,
    fee: u64,
    change_address: *const c_char,
    change: u64,
) -> FFIBuffer {
    let empty_result = FFIBuffer {
        data: ptr::null_mut(),
        len: 0,
    };

    if utxos_json.is_null() || to_address.is_null() {
        set_error("Null parameter provided");
        return empty_result;
    }
    if let Err(e) = validate_shielded_amount(amount, "amount") {
        set_error(&e);
        return empty_result;
    }
    if let Err(e) = validate_fee(fee) {
        set_error(&e);
        return empty_result;
    }
    if !crate::prover::is_prover_initialized() {
        set_error("Prover not initialized. Call cw_pivx_init_prover first.");
        return empty_result;
    }

    let utxos_str = unsafe {
        match CStr::from_ptr(utxos_json).to_str() {
            Ok(s) => s,
            Err(_) => {
                set_error("Invalid UTXO JSON encoding");
                return empty_result;
            }
        }
    };
    let to_str = unsafe {
        match CStr::from_ptr(to_address).to_str() {
            Ok(s) => s,
            Err(_) => {
                set_error("Invalid address encoding");
                return empty_result;
            }
        }
    };
    let memo_str = if memo.is_null() {
        None
    } else {
        unsafe {
            match CStr::from_ptr(memo).to_str() {
                Ok(s) if !s.is_empty() => Some(s.to_string()),
                _ => None,
            }
        }
    };
    if let Err(e) = validate_memo(memo_str.as_deref()) {
        set_error(&e);
        return empty_result;
    }
    if let Err(e) = validate_string_length(utxos_str, 1_000_000, "utxos_json") {
        set_error(&e);
        return empty_result;
    }
    if let Err(e) = validate_string_length(to_str, 1000, "to_address") {
        set_error(&e);
        return empty_result;
    }

    let managers = lock_or_fail!(KEY_MANAGERS, empty_result);
    let key_manager = match managers.get(key_handle as usize).and_then(|m| m.as_ref()) {
        Some(m) => m,
        None => {
            set_error("Invalid key handle");
            return empty_result;
        }
    };
    let testnet = key_manager.network() == crate::types::Network::Testnet;

    // The shield destination must be a Sapling payment address.
    let recipient = match key_manager.decode_payment_address(to_str) {
        Ok(addr) => addr,
        Err(e) => {
            set_error(&format!("Invalid shield destination address: {}", e));
            return empty_result;
        }
    };

    // Parse and validate the UTXO inputs and their signing keys.
    let utxos_data: Vec<crate::types::TransparentUtxoData> =
        match serde_json::from_str(utxos_str) {
            Ok(u) => u,
            Err(e) => {
                set_error(&format!("Failed to parse UTXO JSON: {}", e));
                return empty_result;
            }
        };
    if utxos_data.is_empty() {
        set_error("No UTXOs provided");
        return empty_result;
    }
    let mut inputs = Vec::with_capacity(utxos_data.len());
    for (idx, utxo) in utxos_data.iter().enumerate() {
        match crate::transaction::TransparentInput::from_parts(
            &utxo.txid,
            utxo.vout,
            utxo.value,
            &utxo.script_pubkey,
            &utxo.private_key,
        ) {
            Ok(input) => inputs.push(input),
            Err(e) => {
                set_error(&format!("Invalid UTXO {}: {}", idx, e));
                return empty_result;
            }
        }
    }

    // Optional transparent change.
    let transparent_change = if change == 0 {
        None
    } else {
        let change_str = if change_address.is_null() {
            None
        } else {
            unsafe { CStr::from_ptr(change_address).to_str().ok() }
        };
        let change_str = match change_str {
            Some(s) if !s.is_empty() => s,
            _ => {
                set_error("Change amount requires a change address");
                return empty_result;
            }
        };
        match crate::transaction::TransparentOutput::to_address(change_str, change, testnet) {
            Ok(output) => Some(output),
            Err(e) => {
                set_error(&format!("Invalid change address: {}", e));
                return empty_result;
            }
        }
    };

    let memo_bytes: Option<[u8; 512]> = memo_str.as_ref().map(|m| {
        let mut bytes = [0u8; 512];
        let m_bytes = m.as_bytes();
        let len = m_bytes.len().min(512);
        bytes[..len].copy_from_slice(&m_bytes[..len]);
        bytes
    });
    let outputs = vec![(recipient, amount, memo_bytes)];

    let tx_builder = crate::transaction::TransactionBuilder::new(
        key_manager.extended_spending_key().clone(),
        key_manager.diversifiable_full_viewing_key().clone(),
        testnet,
    );

    match tx_builder.build_shield_transaction(inputs, outputs, transparent_change, fee) {
        Ok(built_tx) => {
            let mut txid_hex = hex::encode(built_tx.txid);
            let mut tx_hex = hex::encode(&built_tx.raw_tx);
            let result_str = format!(
                r#"{{"status":"success","txid":"{}","tx_hex":"{}","fee":{}}}"#,
                txid_hex, tx_hex, built_tx.fee
            );
            let buffer = match ffi_buffer_from_string(result_str) {
                Some(buffer) => buffer,
                None => {
                    txid_hex.zeroize();
                    tx_hex.zeroize();
                    set_error("Memory allocation failed");
                    return empty_result;
                }
            };
            txid_hex.zeroize();
            tx_hex.zeroize();
            buffer
        }
        Err(e) => {
            let error_json = serde_json::to_string(&format!("{}", e))
                .unwrap_or_else(|_| "\"shield transaction build failed\"".to_string());
            let result_str = format!(
                r#"{{"status":"error","error":{}}}"#,
                error_json
            );
            match ffi_buffer_from_string(result_str) {
                Some(buffer) => buffer,
                None => {
                    set_error(&format!("Shield transaction build failed: {}", e));
                    empty_result
                }
            }
        }
    }
}

#[no_mangle]
pub extern "C" fn cw_pivx_build_shielded_tx(
    key_handle: i64,
    notes_json: *const c_char,
    to_address: *const c_char,
    amount: u64,
    memo: *const c_char,
    fee: u64,
    anchor_hex: *const c_char,
) -> FFIBuffer {
    let empty_result = FFIBuffer {
        data: ptr::null_mut(),
        len: 0,
    };

    if notes_json.is_null() || to_address.is_null() || anchor_hex.is_null() {
        set_error("Null parameter provided");
        return empty_result;
    }

    // Validate fee range; the amount dust check is destination-dependent
    // (shielded vs transparent) and happens after address parsing below.
    if let Err(e) = validate_fee(fee) {
        set_error(&e);
        return empty_result;
    }

    if !crate::prover::is_prover_initialized() {
        set_error("Prover not initialized. Call cw_pivx_init_prover first.");
        return empty_result;
    }

    let notes_str = unsafe {
        match CStr::from_ptr(notes_json).to_str() {
            Ok(s) => s,
            Err(_) => {
                set_error("Invalid notes JSON encoding");
                return empty_result;
            }
        }
    };

    let to_str = unsafe {
        match CStr::from_ptr(to_address).to_str() {
            Ok(s) => s,
            Err(_) => {
                set_error("Invalid address encoding");
                return empty_result;
            }
        }
    };

    let anchor_str = unsafe {
        match CStr::from_ptr(anchor_hex).to_str() {
            Ok(s) => s,
            Err(_) => {
                set_error("Invalid anchor encoding");
                return empty_result;
            }
        }
    };

    let memo_str = if memo.is_null() {
        None
    } else {
        unsafe {
            match CStr::from_ptr(memo).to_str() {
                Ok(s) if !s.is_empty() => Some(s.to_string()),
                _ => None,
            }
        }
    };

    if let Err(e) = validate_memo(memo_str.as_deref()) {
        set_error(&e);
        return empty_result;
    }

    // Length caps guard against DoS via huge inputs.
    if let Err(e) = validate_string_length(notes_str, 1_000_000, "notes_json") {
        set_error(&e);
        return empty_result;
    }
    if let Err(e) = validate_string_length(to_str, 1000, "to_address") {
        set_error(&e);
        return empty_result;
    }
    if let Err(e) = validate_string_length(anchor_str, 100, "anchor_hex") {
        set_error(&e);
        return empty_result;
    }

    let managers = lock_or_fail!(KEY_MANAGERS, empty_result);
    let key_manager = match managers.get(key_handle as usize).and_then(|m| m.as_ref()) {
        Some(m) => m,
        None => {
            set_error("Invalid key handle");
            return empty_result;
        }
    };

    let notes_data: Vec<crate::types::SpendableNoteData> = match serde_json::from_str(notes_str) {
        Ok(n) => n,
        Err(e) => {
            set_error(&format!("Failed to parse notes JSON: {}", e));
            return empty_result;
        }
    };

    if notes_data.is_empty() {
        set_error("No notes provided");
        return empty_result;
    }

    let total_input: u64 = notes_data.iter().map(|n| n.value).sum();
    if total_input < amount + fee {
        set_error(&format!(
            "Insufficient funds: have {} zatoshis, need {} + {} fee",
            total_input, amount, fee
        ));
        return empty_result;
    }

    // Parse destination address: a Sapling payment address selects the
    // z-to-z route, a PIVX base58 transparent address selects z-to-t
    // (deshield) with a transparent vout and shielded change.
    let testnet = key_manager.network() == crate::types::Network::Testnet;
    let mut shielded_recipient = None;
    let mut transparent_script = None;
    match key_manager.decode_payment_address(to_str) {
        Ok(addr) => shielded_recipient = Some(addr),
        Err(shielded_error) => {
            match crate::transaction::script_pubkey_for_transparent_address(to_str, testnet) {
                Ok(script) => transparent_script = Some(script),
                Err(_) => {
                    set_error(&format!("Invalid recipient address: {}", shielded_error));
                    return empty_result;
                }
            }
        }
    }

    if transparent_script.is_some() {
        if amount < crate::transaction::TRANSPARENT_DUST_THRESHOLD {
            set_error(&format!(
                "amount is below transparent dust threshold ({} zatoshis)",
                crate::transaction::TRANSPARENT_DUST_THRESHOLD
            ));
            return empty_result;
        }
        if memo_str.is_some() {
            set_error("Memo is not supported for transparent destinations");
            return empty_result;
        }
    } else if let Err(e) = validate_shielded_amount(amount, "amount") {
        set_error(&e);
        return empty_result;
    }

    let anchor_bytes: [u8; 32] = match hex::decode(anchor_str) {
        Ok(bytes) if bytes.len() == 32 => bytes
            .try_into()
            .expect("Length checked: anchor is exactly 32 bytes"),
        _ => {
            set_error("Invalid anchor: must be 32-byte hex");
            return empty_result;
        }
    };

    let anchor = match sapling::Anchor::from_bytes(anchor_bytes).into_option() {
        Some(a) => a,
        None => {
            set_error("Invalid anchor bytes");
            return empty_result;
        }
    };

    let mut spendable_notes = Vec::with_capacity(notes_data.len());
    let mut merkle_paths = Vec::with_capacity(notes_data.len());

    for (idx, note_data) in notes_data.iter().enumerate() {
        let (note, address) = match crate::notes::note_from_parts(
            &note_data.diversifier,
            &note_data.pk_d,
            note_data.value,
            &note_data.rseed,
        ) {
            Ok(n) => n,
            Err(e) => {
                set_error(&format!("Failed to reconstruct note {}: {}", idx, e));
                return empty_result;
            }
        };

        if let Some(expected_cmu) = note_data.cmu.as_ref() {
            let expected_cmu_bytes: [u8; 32] = match hex::decode(expected_cmu) {
                Ok(bytes) if bytes.len() == 32 => bytes
                    .try_into()
                    .expect("Length checked: cmu is exactly 32 bytes"),
                _ => {
                    set_error(&format!("Invalid cmu for note {}", idx));
                    return empty_result;
                }
            };
            let actual_cmu = note.cmu().to_bytes();
            if actual_cmu != expected_cmu_bytes {
                set_error(&format!(
                    "Reconstructed note commitment mismatch for note {}",
                    idx
                ));
                return empty_result;
            }
        }

        let position = note_data.witness_position;

        // Parse merkle path from witness before proving so we can verify the
        // witness is actually anchored to the selected root.
        let path = match crate::notes::parse_merkle_path(&note_data.witness, position) {
            Ok(p) => p,
            Err(e) => {
                set_error(&format!("Failed to parse witness for note {}: {}", idx, e));
                return empty_result;
            }
        };

        let witness_root = sapling::Anchor::from(path.root(Node::from_cmu(&note.cmu())));
        if witness_root.to_bytes() != anchor.to_bytes() {
            set_error(&format!(
                "Witness root mismatch for note {}: witness root does not match spend anchor",
                idx
            ));
            return empty_result;
        }

        let nullifier_bytes: [u8; 32] = match hex::decode(&note_data.nullifier) {
            Ok(bytes) if bytes.len() == 32 => bytes
                .try_into()
                .expect("Length checked: nullifier is exactly 32 bytes"),
            _ => {
                set_error(&format!("Invalid nullifier for note {}", idx));
                return empty_result;
            }
        };
        let nullifier = sapling::Nullifier(nullifier_bytes);
        let expected_nullifier = note.nf(
            &key_manager
                .diversifiable_full_viewing_key()
                .fvk()
                .vk
                .nk,
            position,
        );
        if expected_nullifier.0 != nullifier.0 {
            set_error(&format!("Nullifier mismatch for note {}", idx));
            return empty_result;
        }

        let spendable = crate::notes::SpendableNote::new(
            note, address, position, // witness_position from the ElectrumX response
            nullifier, 0, // height: not needed for spending
            0, // tx_index
            0, // output_index
        );
        spendable_notes.push(spendable);

        merkle_paths.push(path);
    }

    let memo_bytes: Option<[u8; 512]> = memo_str.as_ref().map(|m| {
        let mut bytes = [0u8; 512];
        let m_bytes = m.as_bytes();
        let len = m_bytes.len().min(512);
        bytes[..len].copy_from_slice(&m_bytes[..len]);
        bytes
    });

    let (outputs, transparent_outputs) = match (shielded_recipient, transparent_script) {
        (Some(recipient), _) => (vec![(recipient, amount, memo_bytes)], Vec::new()),
        (None, Some(script_pubkey)) => (
            Vec::new(),
            vec![crate::transaction::TransparentOutput {
                value: amount,
                script_pubkey,
            }],
        ),
        (None, None) => {
            set_error("Invalid recipient address");
            return empty_result;
        }
    };

    let tx_builder = crate::transaction::TransactionBuilder::new(
        key_manager.extended_spending_key().clone(),
        key_manager.diversifiable_full_viewing_key().clone(),
        testnet,
    );

    match tx_builder.build_route_transaction(
        spendable_notes,
        merkle_paths,
        anchor,
        outputs,
        transparent_outputs,
        fee,
    ) {
        Ok(built_tx) => {
            let mut txid_hex = hex::encode(built_tx.txid);
            let mut tx_hex = hex::encode(&built_tx.raw_tx);
            let result_str = format!(
                r#"{{"status":"success","txid":"{}","tx_hex":"{}","fee":{}}}"#,
                txid_hex, tx_hex, built_tx.fee
            );

            let buffer = match ffi_buffer_from_string(result_str) {
                Some(buffer) => buffer,
                None => {
                    txid_hex.zeroize();
                    tx_hex.zeroize();
                    set_error("Memory allocation failed");
                    return empty_result;
                }
            };

            txid_hex.zeroize();
            tx_hex.zeroize();
            buffer
        }
        Err(e) => {
            // Return error details as JSON so caller can understand what happened
            let mut error_message = format!("{}", e);
            let mut error_json = serde_json::to_string(&error_message)
                .unwrap_or_else(|_| "\"transaction build failed\"".to_string());
            let result_str = format!(
                r#"{{"status":"error","error":{},"notes_count":{},"total_input":{},"amount":{},"fee":{}}}"#,
                error_json,
                notes_data.len(),
                total_input,
                amount,
                fee
            );

            let buffer = match ffi_buffer_from_string(result_str) {
                Some(buffer) => buffer,
                None => {
                    set_error(&format!("Transaction build failed: {}", e));
                    error_message.zeroize();
                    error_json.zeroize();
                    return empty_result;
                }
            };

            error_message.zeroize();
            error_json.zeroize();
            buffer
        }
    }
}

/// Verify that a server-supplied witness recomputes to the expected anchor.
///
/// * `witness_hex`: 32 sibling hashes as hex (2048 hex chars), the same
///   serialization `cw_pivx_build_shielded_tx` parses into a spend path.
/// * `cmu_hex`: 32-byte note commitment as hex.
/// * `anchor_hex`: 32-byte expected anchor (Merkle root) as hex.
/// * `position`: Position of the note in the commitment tree.
///
/// Returns 1 when the locally recomputed root equals the anchor, 0 on a
/// clean mismatch, and -1 on parse or other errors (see
/// `cw_pivx_get_last_error`).
#[no_mangle]
pub extern "C" fn pivx_sapling_verify_witness_root(
    witness_hex: *const c_char,
    cmu_hex: *const c_char,
    anchor_hex: *const c_char,
    position: u64,
) -> i32 {
    if witness_hex.is_null() || cmu_hex.is_null() || anchor_hex.is_null() {
        set_error("Null pointer passed to verify_witness_root");
        return -1;
    }

    let witness_str = match unsafe { CStr::from_ptr(witness_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_error("Invalid witness encoding");
            return -1;
        }
    };
    let cmu_str = match unsafe { CStr::from_ptr(cmu_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_error("Invalid cmu encoding");
            return -1;
        }
    };
    let anchor_str = match unsafe { CStr::from_ptr(anchor_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_error("Invalid anchor encoding");
            return -1;
        }
    };

    if let Err(e) = validate_string_length(witness_str, 4096, "witness_hex") {
        set_error(&e);
        return -1;
    }

    let cmu_bytes: [u8; 32] = match hex::decode(cmu_str) {
        Ok(bytes) if bytes.len() == 32 => bytes
            .try_into()
            .expect("Length checked: cmu is exactly 32 bytes"),
        _ => {
            set_error("Invalid cmu: must be 32-byte hex");
            return -1;
        }
    };
    let anchor_bytes: [u8; 32] = match hex::decode(anchor_str) {
        Ok(bytes) if bytes.len() == 32 => bytes
            .try_into()
            .expect("Length checked: anchor is exactly 32 bytes"),
        _ => {
            set_error("Invalid anchor: must be 32-byte hex");
            return -1;
        }
    };

    match crate::notes::verify_witness_root(witness_str, position, cmu_bytes, anchor_bytes) {
        Ok(true) => 1,
        Ok(false) => 0,
        Err(e) => {
            set_error(&format!("Witness root verification failed: {}", e));
            -1
        }
    }
}

#[no_mangle]
pub extern "C" fn pivx_sapling_init() -> i32 {
    0 // Success
}

#[no_mangle]
pub extern "C" fn pivx_sapling_create_from_seed(
    seed: *const u8,
    seed_len: usize,
    is_testnet: i32,
    session_id: *mut i32,
) -> i32 {
    let handle = cw_pivx_init_keys(seed, seed_len, is_testnet as u8);
    if handle < 0 {
        -1
    } else {
        unsafe { *session_id = handle as i32 };
        0
    }
}

#[no_mangle]
pub extern "C" fn pivx_sapling_destroy(session_id: i32) -> i32 {
    cw_pivx_dispose_keys(session_id as i64);
    0
}

#[no_mangle]
pub extern "C" fn pivx_sapling_get_balance(session_id: i32) -> i64 {
    cw_pivx_get_shielded_balance(session_id as i64) as i64
}

#[no_mangle]
pub extern "C" fn pivx_sapling_get_sync_height(session_id: i32) -> i32 {
    cw_pivx_get_sync_height(session_id as i64) as i32
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zero_ffi_allocation_overwrites_bytes() {
        let mut bytes = vec![1u8, 2, 3, 4];

        unsafe {
            zero_ffi_allocation(bytes.as_mut_ptr(), bytes.len());
        }

        assert_eq!(bytes, vec![0u8; 4]);
    }

    #[test]
    fn test_ffi_buffer_from_string_copies_bytes() {
        let buffer = ffi_buffer_from_string("ffi-json".to_string()).unwrap();
        assert!(!buffer.data.is_null());
        assert_eq!(buffer.len, 8);

        let bytes = unsafe { slice::from_raw_parts(buffer.data, buffer.len) };
        assert_eq!(bytes, b"ffi-json");

        cw_pivx_free_buffer(buffer);
    }

    #[test]
    fn test_ffi_init_keys() {
        let seed = [0u8; 64];

        let handle = cw_pivx_init_keys(seed.as_ptr(), seed.len(), 0);
        assert!(handle >= 0);

        cw_pivx_dispose_keys(handle);
    }

    #[test]
    fn test_ffi_get_address() {
        let seed = [1u8; 64];

        let handle = cw_pivx_init_keys(seed.as_ptr(), seed.len(), 0);
        assert!(handle >= 0);

        let address_ptr = cw_pivx_get_default_address(handle);
        assert!(!address_ptr.is_null());

        let address = unsafe { CStr::from_ptr(address_ptr) }.to_str().unwrap();

        assert!(address.starts_with("ps"));

        cw_pivx_free_string(address_ptr);
        cw_pivx_dispose_keys(handle);
    }

    #[test]
    fn test_ffi_validate_address() {
        let valid = "ps1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqf0vjel";
        let valid_ptr = CString::new(valid).expect("Test string is valid: no null bytes");

        // This will fail validation because it's a dummy address, but the FFI call should work
        let _result = cw_pivx_validate_address(valid_ptr.as_ptr(), 0);
        // Address validation is tested in keys.rs
    }

    #[test]
    fn test_ffi_verify_witness_root() {
        use sapling::note::ExtractedNoteCommitment;
        use sapling::Anchor;

        // 32 canonical sibling nodes (value 1) and a canonical cmu (value 2).
        let mut sibling = [0u8; 32];
        sibling[0] = 1;
        let witness_hex = hex::encode(sibling).repeat(32);
        let mut cmu = [0u8; 32];
        cmu[0] = 2;

        let path = crate::notes::parse_merkle_path(&witness_hex, 3).unwrap();
        let cmu_parsed = ExtractedNoteCommitment::from_bytes(&cmu)
            .into_option()
            .unwrap();
        let anchor = Anchor::from(path.root(Node::from_cmu(&cmu_parsed))).to_bytes();

        let witness_c = CString::new(witness_hex.clone()).unwrap();
        let cmu_c = CString::new(hex::encode(cmu)).unwrap();
        let anchor_c = CString::new(hex::encode(anchor)).unwrap();

        // Matching witness verifies.
        assert_eq!(
            pivx_sapling_verify_witness_root(
                witness_c.as_ptr(),
                cmu_c.as_ptr(),
                anchor_c.as_ptr(),
                3
            ),
            1
        );

        // Tampered sibling (value 3, still canonical) is a clean mismatch.
        let mut tampered = witness_hex;
        tampered.replace_range(0..2, "03");
        let tampered_c = CString::new(tampered).unwrap();
        assert_eq!(
            pivx_sapling_verify_witness_root(
                tampered_c.as_ptr(),
                cmu_c.as_ptr(),
                anchor_c.as_ptr(),
                3
            ),
            0
        );

        // Wrong position is a clean mismatch.
        assert_eq!(
            pivx_sapling_verify_witness_root(
                witness_c.as_ptr(),
                cmu_c.as_ptr(),
                anchor_c.as_ptr(),
                4
            ),
            0
        );

        // Malformed inputs are errors, not mismatches.
        let bad_hex = CString::new("zz").unwrap();
        assert_eq!(
            pivx_sapling_verify_witness_root(
                bad_hex.as_ptr(),
                cmu_c.as_ptr(),
                anchor_c.as_ptr(),
                3
            ),
            -1
        );
        assert_eq!(
            pivx_sapling_verify_witness_root(
                witness_c.as_ptr(),
                bad_hex.as_ptr(),
                anchor_c.as_ptr(),
                3
            ),
            -1
        );
        assert_eq!(
            pivx_sapling_verify_witness_root(
                witness_c.as_ptr(),
                cmu_c.as_ptr(),
                std::ptr::null(),
                3
            ),
            -1
        );
    }

    // Guards the v1 display-order receive path: a display-order node sends cmu
    // (and epk) byte-reversed, and try_sapling_note_decryption checks the
    // decrypted note's commitment against the cmu it was handed. Forwarding the
    // reversed bytes un-reversed yields a different commitment, so the note
    // reads as "not ours" and is silently missed. The Dart receive path reverses
    // cmu and epk before this boundary (sapling_factories.dart output loop).
    #[test]
    fn display_order_cmu_must_be_reversed_for_trial_decryption() {
        use sapling::note::ExtractedNoteCommitment;
        use sapling::value::NoteValue;
        use sapling::{Note, Rseed};

        let manager = SaplingKeyManager::from_seed(&[7u8; 64], Network::Mainnet).unwrap();
        let address = manager.default_address().unwrap();
        let mut rcm_bytes = [0u8; 32];
        rcm_bytes[0] = 3;
        let rcm = jubjub::Fr::from_bytes(&rcm_bytes).into_option().unwrap();
        let note = Note::from_parts(address, NoteValue::from_raw(100_000), Rseed::BeforeZip212(rcm));

        let serialization = note.cmu().to_bytes();

        // Serialization (little-endian) order round-trips to the true commitment.
        assert_eq!(
            ExtractedNoteCommitment::from_bytes(&serialization)
                .into_option()
                .unwrap()
                .to_bytes(),
            serialization
        );

        // Display (big-endian) order, what an un-reversed v1 receive would use,
        // does not decode to the note's commitment, so decryption would miss it.
        let mut display = serialization;
        display.reverse();
        let decoded = ExtractedNoteCommitment::from_bytes(&display).into_option();
        assert!(
            decoded.map_or(true, |c| c.to_bytes() != serialization),
            "reversed (display-order) cmu must not decode to the note's true commitment"
        );
    }

    #[test]
    fn test_ffi_estimate_fee() {
        let fee = cw_pivx_estimate_fee(2, 2, 1, 1);
        assert_eq!(fee, 2_931_000);
    }

    #[test]
    fn estimate_fee_grows_with_compact_size_prefix_past_253_spends() {
        // Crossing 253 spends grows the CompactSize count prefix from 1 to 3
        // bytes: +1 spend (384) + 2, at the shielded rate = (384+2)*1000.
        let at_252 = cw_pivx_estimate_fee(252, 1, 0, 0);
        let at_253 = cw_pivx_estimate_fee(253, 1, 0, 0);
        assert_eq!(at_253 - at_252, 386_000);
    }

    #[test]
    fn test_ffi_sync_engine() {
        let handle = cw_pivx_init_sync_engine(0);
        assert!(handle >= 0);

        let height = cw_pivx_get_sync_height(handle);
        assert_eq!(height, 0); // Fresh sync state

        let balance = cw_pivx_get_shielded_balance(handle);
        assert_eq!(balance, 0);

        let count = cw_pivx_get_unspent_note_count(handle);
        assert_eq!(count, 0);

        cw_pivx_dispose_sync_engine(handle);
    }
}
