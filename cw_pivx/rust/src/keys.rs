//! PIVX Sapling key management.
//!
//! Implements ZIP-32 HD key derivation for Sapling shielded addresses.
//! Uses PIVX-specific HRPs (Human Readable Parts) for address encoding.
//!
//! # Security Note
//!
//! This module handles cryptographic secrets (spending keys) that must be
//! securely zeroed from memory when no longer needed. The SaplingKeyManager
//! implements Drop to ensure secrets are cleared.

use bech32::{FromBase32, ToBase32, Variant};
use sapling::{
    zip32::{DiversifiableFullViewingKey, ExtendedSpendingKey},
    PaymentAddress,
};
use zcash_primitives::zip32::{ChildIndex, DiversifierIndex};

use crate::error::SaplingError;
use crate::types::Network;

pub type SaplingResult<T> = Result<T, SaplingError>;

/// Bech32 human readable parts for PIVX Sapling.
pub mod hrp {
    pub const PAYMENT_ADDRESS_MAINNET: &str = "ps";
    pub const PAYMENT_ADDRESS_TESTNET: &str = "ptestsapling";

    pub const FULL_VIEWING_KEY_MAINNET: &str = "pviews";
    pub const FULL_VIEWING_KEY_TESTNET: &str = "pviewtestsapling";

    pub const EXTENDED_SPENDING_KEY_MAINNET: &str = "p-secret-extended-key-main";
    pub const EXTENDED_SPENDING_KEY_TESTNET: &str = "p-secret-extended-key-test";
}

pub struct SaplingKeyManager {
    extended_spending_key: ExtendedSpendingKey,
    dfvk: DiversifiableFullViewingKey,
    diversifier_index: DiversifierIndex,
    network: Network,
}

impl SaplingKeyManager {
    pub fn from_seed(seed: &[u8], network: Network) -> SaplingResult<Self> {
        if seed.len() < 32 {
            return Err(SaplingError::InvalidSeed);
        }

        let master = ExtendedSpendingKey::master(seed);

        // PIVX Sapling path m/32'/119'/account', account 0.
        let account_path = [
            ChildIndex::hardened(32),  // Purpose: Sapling
            ChildIndex::hardened(119), // Coin type: PIVX (SLIP-44)
            ChildIndex::hardened(0),   // Account 0
        ];

        let extended_spending_key = ExtendedSpendingKey::from_path(&master, &account_path);
        let dfvk = extended_spending_key.to_diversifiable_full_viewing_key();

        Ok(Self {
            extended_spending_key,
            dfvk,
            diversifier_index: DiversifierIndex::new(),
            network,
        })
    }

    pub fn extended_spending_key(&self) -> &ExtendedSpendingKey {
        &self.extended_spending_key
    }

    pub fn diversifiable_full_viewing_key(&self) -> &DiversifiableFullViewingKey {
        &self.dfvk
    }

    pub fn derive_address(
        &self,
        diversifier_index: DiversifierIndex,
    ) -> SaplingResult<PaymentAddress> {
        self.dfvk
            .address(diversifier_index)
            .ok_or(SaplingError::InvalidDiversifier)
    }

    pub fn default_address(&self) -> SaplingResult<PaymentAddress> {
        let (_, addr) = self.dfvk.default_address();
        Ok(addr)
    }

    pub fn next_address(&mut self) -> SaplingResult<PaymentAddress> {
        let (new_index, addr) = self
            .dfvk
            .find_address(self.diversifier_index)
            .ok_or(SaplingError::InvalidDiversifier)?;

        self.diversifier_index = new_index;
        self.diversifier_index
            .increment()
            .map_err(|_| SaplingError::InvalidDiversifier)?;

        Ok(addr)
    }

    pub fn encode_payment_address(&self, address: &PaymentAddress) -> String {
        let hrp = match self.network {
            Network::Mainnet => hrp::PAYMENT_ADDRESS_MAINNET,
            Network::Testnet => hrp::PAYMENT_ADDRESS_TESTNET,
        };

        encode_payment_address(hrp, address)
    }

    pub fn decode_payment_address(&self, encoded: &str) -> SaplingResult<PaymentAddress> {
        let expected_hrp = match self.network {
            Network::Mainnet => hrp::PAYMENT_ADDRESS_MAINNET,
            Network::Testnet => hrp::PAYMENT_ADDRESS_TESTNET,
        };

        decode_payment_address(expected_hrp, encoded)
    }

    pub fn encode_full_viewing_key(&self) -> String {
        let hrp = match self.network {
            Network::Mainnet => hrp::FULL_VIEWING_KEY_MAINNET,
            Network::Testnet => hrp::FULL_VIEWING_KEY_TESTNET,
        };

        let fvk = self.dfvk.to_bytes();
        bech32::encode(hrp, fvk.to_base32(), Variant::Bech32).expect("FVK encoding should not fail")
    }

    pub fn is_our_address(&self, address: &PaymentAddress) -> bool {
        let mut idx = DiversifierIndex::new();
        for _ in 0..1000 {
            if let Some((_, derived)) = self.dfvk.find_address(idx) {
                if derived == *address {
                    return true;
                }
            }
            if idx.increment().is_err() {
                break;
            }
        }
        false
    }

    pub fn network(&self) -> Network {
        self.network
    }
}

/// ExtendedSpendingKey doesn't implement Zeroize, so zero the secret fields by
/// hand on drop.
impl Drop for SaplingKeyManager {
    fn drop(&mut self) {
        // SECURITY: zero key material so it can't leak via memory/core dumps or
        // swap. Best-effort: write_bytes is non-volatile so the compiler may
        // elide it, and copies can still survive in caches/swap/pre-drop dumps.
        // Harden with volatile writes + mlock if that matters.
        use std::ptr;

        // SAFETY: the pointers come from &mut self, so they are valid, aligned,
        // and uniquely owned for the size of each type being overwritten.
        unsafe {
            let esk_ptr = &mut self.extended_spending_key as *mut ExtendedSpendingKey;
            ptr::write_bytes(
                esk_ptr as *mut u8,
                0,
                std::mem::size_of::<ExtendedSpendingKey>(),
            );

            let dfvk_ptr = &mut self.dfvk as *mut DiversifiableFullViewingKey;
            ptr::write_bytes(
                dfvk_ptr as *mut u8,
                0,
                std::mem::size_of::<DiversifiableFullViewingKey>(),
            );

            let div_ptr = &mut self.diversifier_index as *mut DiversifierIndex;
            ptr::write_bytes(
                div_ptr as *mut u8,
                0,
                std::mem::size_of::<DiversifierIndex>(),
            );
        }
    }
}

pub fn encode_payment_address(hrp: &str, address: &PaymentAddress) -> String {
    let bytes = address.to_bytes();
    bech32::encode(hrp, bytes.to_base32(), Variant::Bech32)
        .expect("Payment address encoding should not fail")
}

pub fn decode_payment_address(expected_hrp: &str, encoded: &str) -> SaplingResult<PaymentAddress> {
    let (hrp, data, _variant) =
        bech32::decode(encoded).map_err(|_| SaplingError::InvalidAddress)?;

    if hrp != expected_hrp {
        return Err(SaplingError::InvalidAddress);
    }

    let data = Vec::<u8>::from_base32(&data).map_err(|_| SaplingError::InvalidAddress)?;

    if data.len() != 43 {
        return Err(SaplingError::InvalidAddress);
    }

    let bytes: [u8; 43] = data.try_into().map_err(|_| SaplingError::InvalidAddress)?;

    PaymentAddress::from_bytes(&bytes).ok_or(SaplingError::InvalidAddress)
}

pub fn validate_address(address: &str, network: Network) -> bool {
    let expected_hrp = match network {
        Network::Mainnet => hrp::PAYMENT_ADDRESS_MAINNET,
        Network::Testnet => hrp::PAYMENT_ADDRESS_TESTNET,
    };

    decode_payment_address(expected_hrp, address).is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_derivation_from_seed() {
        let seed = [0u8; 64];

        let manager = SaplingKeyManager::from_seed(&seed, Network::Mainnet)
            .expect("Key derivation should succeed");

        let address = manager
            .default_address()
            .expect("Default address should work");

        let encoded = manager.encode_payment_address(&address);
        assert!(encoded.starts_with("ps"));

        let decoded = manager
            .decode_payment_address(&encoded)
            .expect("Decoding should succeed");
        assert_eq!(address, decoded);
    }

    #[test]
    fn test_address_derivation() {
        let seed = [1u8; 64];
        let mut manager = SaplingKeyManager::from_seed(&seed, Network::Mainnet)
            .expect("Key derivation should succeed");

        let addr1 = manager.next_address().expect("First address");
        let addr2 = manager.next_address().expect("Second address");

        assert_ne!(addr1, addr2);
    }

    #[test]
    fn test_viewing_key_encoding() {
        let seed = [2u8; 64];
        let manager = SaplingKeyManager::from_seed(&seed, Network::Mainnet)
            .expect("Key derivation should succeed");

        let fvk_encoded = manager.encode_full_viewing_key();
        assert!(fvk_encoded.starts_with("pviews"));
    }

    #[test]
    fn test_address_validation() {
        assert!(!validate_address("invalid", Network::Mainnet));

        let seed = [3u8; 64];
        let manager = SaplingKeyManager::from_seed(&seed, Network::Mainnet)
            .expect("Key derivation should succeed");
        let address = manager.default_address().expect("Default address");
        let encoded = manager.encode_payment_address(&address);

        assert!(validate_address(&encoded, Network::Mainnet));
        assert!(!validate_address(&encoded, Network::Testnet));
    }

    #[test]
    fn test_key_manager_drop_zeros_memory() {
        // Can't assert the memory is zeroed (reading it post-drop is UB); this
        // only exercises that Drop runs without panicking.
        let seed = [4u8; 64];
        {
            let _manager = SaplingKeyManager::from_seed(&seed, Network::Mainnet)
                .expect("Key derivation should succeed");
        }
    }
}
