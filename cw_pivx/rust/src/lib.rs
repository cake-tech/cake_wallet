//! PIVX Sapling FFI Library for Cake Wallet
//!
//! This library provides C-compatible FFI bindings for PIVX Sapling operations:
//! - Key derivation (ZIP-32)
//! - Note scanning (trial decryption)
//! - Transaction building (Groth16 proofs)
//!
//! # Safety
//!
//! All FFI functions are marked `unsafe` and require:
//! - Valid non-null pointers where specified
//! - Proper memory management (caller must free returned strings/buffers)
//! - Thread-safe usage patterns

pub mod error;
pub mod ffi;
pub mod keys;
pub mod notes;
pub mod prover;
pub mod sync;
pub mod transaction;
pub mod types;
pub mod utils;

use std::ffi::{c_char, c_uchar, CStr, CString};
use std::ptr;

pub use error::*;
pub use keys::{
    decode_payment_address, encode_payment_address, hrp, validate_address, SaplingKeyManager,
};
pub use notes::{select_notes_for_amount, CompactNote, SpendableNote};
pub use sync::{SyncProgress, SyncState, SAPLING_TREE_DEPTH};
pub use transaction::{
    BuiltTransaction, PivxMainnet, PivxTestnet, TransactionBuilder, TransactionOptions,
    TransactionOutput, PIVX_SAPLING_ACTIVATION,
};
pub use types::Network;

pub use ffi::*;

/// Caller must free the returned string with `pivx_free_string`.
#[no_mangle]
pub extern "C" fn pivx_sapling_version() -> *mut c_char {
    let version = env!("CARGO_PKG_VERSION");
    match CString::new(version) {
        Ok(s) => s.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// Free a string allocated by this library.
///
/// # Safety
/// The pointer must have been allocated by this library and not already freed.
#[no_mangle]
pub unsafe extern "C" fn pivx_free_string(s: *mut c_char) {
    if !s.is_null() {
        let len = CStr::from_ptr(s).to_bytes_with_nul().len();
        crate::ffi::zero_ffi_allocation(s.cast::<u8>(), len);
        drop(CString::from_raw(s));
    }
}

/// Free a byte buffer allocated by this library.
///
/// # Safety
/// The pointer must have been allocated by this library and not already freed.
#[no_mangle]
pub unsafe extern "C" fn pivx_free_buffer(ptr: *mut c_uchar, len: usize) {
    if !ptr.is_null() && len > 0 {
        crate::ffi::zero_ffi_allocation(ptr.cast::<u8>(), len);
        drop(Vec::from_raw_parts(ptr, len, len));
    }
}

thread_local! {
    static LAST_ERROR: std::cell::RefCell<Option<String>> = std::cell::RefCell::new(None);
}

/// Get the last error message.
/// Returns null if no error occurred.
/// Caller must free the returned string with `pivx_free_string`.
#[no_mangle]
pub extern "C" fn pivx_get_last_error() -> *mut c_char {
    LAST_ERROR.with(|e| match e.borrow().as_ref() {
        Some(msg) => CString::new(msg.as_str())
            .map(|s| s.into_raw())
            .unwrap_or(ptr::null_mut()),
        None => ptr::null_mut(),
    })
}

/// Clear the last error.
#[no_mangle]
pub extern "C" fn pivx_clear_last_error() {
    LAST_ERROR.with(|e| {
        *e.borrow_mut() = None;
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CStr;

    #[test]
    fn test_init() {
        assert_eq!(pivx_sapling_init(), 0);
    }

    #[test]
    fn test_version() {
        let version = pivx_sapling_version();
        assert!(!version.is_null());
        unsafe {
            let s = CStr::from_ptr(version).to_str().unwrap();
            assert!(!s.is_empty());
            pivx_free_string(version);
        }
    }
}
