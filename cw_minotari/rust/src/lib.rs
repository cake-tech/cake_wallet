use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

mod error;
mod wallet;

pub use error::MinotariError;
pub use wallet::MinotariWallet;

/// Opaque wallet handle for FFI
pub struct WalletHandle {
    wallet: Box<MinotariWallet>,
}

/// Initialize logging for the library
#[no_mangle]
pub extern "C" fn minotari_init_logging() {
    env_logger::init();
}

/// Create a new Minotari wallet from a 24-word mnemonic seed phrase
///
/// # Arguments
/// * `mnemonic` - 24-word BIP39 mnemonic seed phrase (null-terminated C string)
/// * `data_path` - Path to store wallet data (null-terminated C string)
/// * `passphrase` - Optional passphrase for mnemonic (can be null)
/// * `error_out` - Pointer to store error message if creation fails
///
/// # Returns
/// * Wallet handle on success, null pointer on failure
/// * If null is returned, error_out will contain the error message
#[no_mangle]
pub extern "C" fn minotari_wallet_create_from_mnemonic(
    mnemonic: *const c_char,
    data_path: *const c_char,
    passphrase: *const c_char,
    error_out: *mut *mut c_char,
) -> *mut WalletHandle {
    if mnemonic.is_null() || data_path.is_null() {
        set_error(error_out, "mnemonic and data_path cannot be null");
        return ptr::null_mut();
    }

    let mnemonic_str = match unsafe { CStr::from_ptr(mnemonic) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_error(error_out, "Invalid UTF-8 in mnemonic");
            return ptr::null_mut();
        }
    };

    let data_path_str = match unsafe { CStr::from_ptr(data_path) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_error(error_out, "Invalid UTF-8 in data_path");
            return ptr::null_mut();
        }
    };

    let passphrase_str = if passphrase.is_null() {
        ""
    } else {
        match unsafe { CStr::from_ptr(passphrase) }.to_str() {
            Ok(s) => s,
            Err(_) => {
                set_error(error_out, "Invalid UTF-8 in passphrase");
                return ptr::null_mut();
            }
        }
    };

    match MinotariWallet::from_mnemonic(mnemonic_str, data_path_str, passphrase_str) {
        Ok(wallet) => Box::into_raw(Box::new(WalletHandle {
            wallet: Box::new(wallet),
        })),
        Err(e) => {
            set_error(error_out, &e.to_string());
            ptr::null_mut()
        }
    }
}

/// Restore a wallet from mnemonic by deleting existing data and creating new wallet
///
/// # Arguments
/// * `mnemonic` - 24-word BIP39 mnemonic seed phrase
/// * `data_path` - Path to wallet data
/// * `passphrase` - Optional passphrase for mnemonic (can be null)
/// * `error_out` - Pointer to store error message if restoration fails
///
/// # Returns
/// * Wallet handle on success, null pointer on failure
#[no_mangle]
pub extern "C" fn minotari_wallet_restore(
    mnemonic: *const c_char,
    data_path: *const c_char,
    passphrase: *const c_char,
    error_out: *mut *mut c_char,
) -> *mut WalletHandle {
    if mnemonic.is_null() || data_path.is_null() {
        set_error(error_out, "mnemonic and data_path cannot be null");
        return ptr::null_mut();
    }

    let data_path_str = match unsafe { CStr::from_ptr(data_path) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_error(error_out, "Invalid UTF-8 in data_path");
            return ptr::null_mut();
        }
    };

    // Delete existing wallet data before restoring
    match MinotariWallet::delete_wallet_data(data_path_str) {
        Ok(_) => {},
        Err(e) => {
            set_error(error_out, &format!("Failed to delete wallet data: {}", e));
            return ptr::null_mut();
        }
    }

    // Create wallet from mnemonic (same as create)
    minotari_wallet_create_from_mnemonic(mnemonic, data_path, passphrase, error_out)
}

/// Get the wallet address as a base58-encoded string
///
/// # Arguments
/// * `handle` - Wallet handle
/// * `error_out` - Pointer to store error message if operation fails
///
/// # Returns
/// * Null-terminated C string containing the address, or null on failure
/// * Caller must free the returned string using minotari_string_free
#[no_mangle]
pub extern "C" fn minotari_wallet_get_address(
    handle: *const WalletHandle,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    if handle.is_null() {
        set_error(error_out, "wallet handle is null");
        return ptr::null_mut();
    }

    let wallet = unsafe { &(*handle).wallet };

    match wallet.get_address() {
        Ok(address) => match CString::new(address) {
            Ok(c_str) => c_str.into_raw(),
            Err(_) => {
                set_error(error_out, "Failed to convert address to C string");
                ptr::null_mut()
            }
        },
        Err(e) => {
            set_error(error_out, &e.to_string());
            ptr::null_mut()
        }
    }
}

/// Get the wallet balance in microTari (6 decimal places)
///
/// # Arguments
/// * `handle` - Wallet handle
/// * `available_out` - Pointer to store available balance
/// * `pending_incoming_out` - Pointer to store pending incoming balance
/// * `pending_outgoing_out` - Pointer to store pending outgoing balance
/// * `error_out` - Pointer to store error message if operation fails
///
/// # Returns
/// * 0 on success, -1 on failure
#[no_mangle]
pub extern "C" fn minotari_wallet_get_balance(
    handle: *const WalletHandle,
    available_out: *mut u64,
    pending_incoming_out: *mut u64,
    pending_outgoing_out: *mut u64,
    error_out: *mut *mut c_char,
) -> i32 {
    if handle.is_null() {
        set_error(error_out, "wallet handle is null");
        return -1;
    }

    if available_out.is_null() || pending_incoming_out.is_null() || pending_outgoing_out.is_null() {
        set_error(error_out, "output pointers cannot be null");
        return -1;
    }

    let wallet = unsafe { &(*handle).wallet };

    match wallet.get_balance() {
        Ok((available, pending_in, pending_out)) => {
            unsafe {
                *available_out = available;
                *pending_incoming_out = pending_in;
                *pending_outgoing_out = pending_out;
            }
            0
        }
        Err(e) => {
            set_error(error_out, &e.to_string());
            -1
        }
    }
}

/// Sync wallet with the network
///
/// # Arguments
/// * `handle` - Wallet handle
/// * `base_node_address` - Base node address to sync with
/// * `error_out` - Pointer to store error message if sync fails
///
/// # Returns
/// * 0 on success, -1 on failure
#[no_mangle]
pub extern "C" fn minotari_wallet_sync(
    handle: *const WalletHandle,
    base_node_address: *const c_char,
    error_out: *mut *mut c_char,
) -> i32 {
    if handle.is_null() || base_node_address.is_null() {
        set_error(error_out, "handle and base_node_address cannot be null");
        return -1;
    }

    let base_node_str = match unsafe { CStr::from_ptr(base_node_address) }.to_str() {
        Ok(s) => s,
        Err(_) => {
            set_error(error_out, "Invalid UTF-8 in base_node_address");
            return -1;
        }
    };

    let wallet = unsafe { &(*handle).wallet };

    match wallet.sync(base_node_str) {
        Ok(_) => 0,
        Err(e) => {
            set_error(error_out, &e.to_string());
            -1
        }
    }
}

/// Free a wallet handle
///
/// # Arguments
/// * `handle` - Wallet handle to free
#[no_mangle]
pub extern "C" fn minotari_wallet_free(handle: *mut WalletHandle) {
    if !handle.is_null() {
        unsafe {
            let _ = Box::from_raw(handle);
        }
    }
}

/// Free a string returned by this library
///
/// # Arguments
/// * `s` - String pointer to free
#[no_mangle]
pub extern "C" fn minotari_string_free(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

/// Helper function to set error message
fn set_error(error_out: *mut *mut c_char, message: &str) {
    if !error_out.is_null() {
        if let Ok(c_str) = CString::new(message) {
            unsafe {
                *error_out = c_str.into_raw();
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wallet_lifecycle() {
        // This is a placeholder test
        // Real tests will need actual minotari-cli integration
        assert!(true);
    }
}
