//! Common types used across the library.

use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

/// Network type for PIVX
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub enum Network {
    Mainnet = 0,
    Testnet = 1,
}

impl Network {
    pub fn coin_type(&self) -> u32 {
        match self {
            Network::Mainnet => 119,
            Network::Testnet => 1,
        }
    }

    pub fn hrp_sapling_payment_address(&self) -> &'static str {
        match self {
            Network::Mainnet => "ps",
            Network::Testnet => "ptestsapling",
        }
    }

    pub fn hrp_sapling_extended_spending_key(&self) -> &'static str {
        match self {
            Network::Mainnet => "p-secret-extended-key-main",
            Network::Testnet => "p-secret-extended-key-test",
        }
    }

    pub fn hrp_sapling_extended_full_viewing_key(&self) -> &'static str {
        match self {
            Network::Mainnet => "pviews",
            Network::Testnet => "pviewtestsapling",
        }
    }

    pub fn hrp_sapling_incoming_viewing_key(&self) -> &'static str {
        match self {
            Network::Mainnet => "pivks",
            Network::Testnet => "pivktestsapling",
        }
    }

    pub fn sapling_activation_height(&self) -> u32 {
        match self {
            Network::Mainnet => 2_700_500,
            Network::Testnet => 201,
        }
    }
}

impl From<bool> for Network {
    fn from(is_testnet: bool) -> Self {
        if is_testnet {
            Network::Testnet
        } else {
            Network::Mainnet
        }
    }
}

/// Represents a spendable note with all required data.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpendableNoteData {
    /// Diversifier (11 bytes, hex encoded)
    pub diversifier: String,
    /// Diversified transmission key pk_d (32 bytes, hex encoded)
    pub pk_d: String,
    /// Note value in zatoshis
    pub value: u64,
    /// Commitment randomness (32 bytes, hex encoded)
    pub rcm: String,
    /// Note randomness seed (32 bytes, hex encoded)
    pub rseed: String,
    /// Incremental witness path (hex encoded concatenated 32-byte hashes)
    pub witness: String,
    /// Position in the commitment tree (from witness response)
    #[serde(default)]
    pub witness_position: u64,
    /// Nullifier (32 bytes, hex encoded)
    pub nullifier: String,
    /// Note commitment (cmu) for validation
    #[serde(default)]
    pub cmu: Option<String>,
    /// Optional memo
    pub memo: Option<String>,
}

impl SpendableNoteData {
    fn zeroize_sensitive_fields(&mut self) {
        self.diversifier.zeroize();
        self.pk_d.zeroize();
        self.rcm.zeroize();
        self.rseed.zeroize();
        self.witness.zeroize();
        self.nullifier.zeroize();
        if let Some(cmu) = self.cmu.as_mut() {
            cmu.zeroize();
        }
        if let Some(memo) = self.memo.as_mut() {
            memo.zeroize();
        }
    }
}

impl Drop for SpendableNoteData {
    fn drop(&mut self) {
        self.zeroize_sensitive_fields();
    }
}

/// Result of creating a transaction.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionResult {
    /// Transaction ID
    pub txid: String,
    /// Signed transaction as hex
    pub tx_hex: String,
    /// Nullifiers of spent notes
    pub nullifiers: Vec<String>,
    /// Transaction fee in zatoshis
    pub fee: u64,
}

impl TransactionResult {
    fn zeroize_sensitive_fields(&mut self) {
        self.txid.zeroize();
        self.tx_hex.zeroize();
        for nullifier in &mut self.nullifiers {
            nullifier.zeroize();
        }
        self.nullifiers.clear();
    }
}

impl Drop for TransactionResult {
    fn drop(&mut self) {
        self.zeroize_sensitive_fields();
    }
}

/// Transparent UTXO for shielding transactions.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransparentUtxoData {
    /// Transaction ID
    pub txid: String,
    /// Output index
    pub vout: u32,
    /// Value in zatoshis
    pub value: u64,
    /// Script pubkey (hex encoded)
    pub script_pubkey: String,
    /// Private key (WIF or hex)
    pub private_key: String,
}

impl TransparentUtxoData {
    fn zeroize_sensitive_fields(&mut self) {
        self.txid.zeroize();
        self.script_pubkey.zeroize();
        self.private_key.zeroize();
    }
}

impl Drop for TransparentUtxoData {
    fn drop(&mut self) {
        self.zeroize_sensitive_fields();
    }
}

/// Options for creating a transaction.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionOptions {
    /// Destination address (shielded or transparent)
    pub to_address: String,
    /// Amount in zatoshis
    pub amount: u64,
    /// Optional memo (max 512 bytes)
    pub memo: Option<String>,
    /// Change address (defaults to own shielded address)
    pub change_address: Option<String>,
    /// Current block height
    pub block_height: u32,
}

impl TransactionOptions {
    fn zeroize_sensitive_fields(&mut self) {
        self.to_address.zeroize();
        if let Some(memo) = self.memo.as_mut() {
            memo.zeroize();
        }
        if let Some(change_address) = self.change_address.as_mut() {
            change_address.zeroize();
        }
    }
}

impl Drop for TransactionOptions {
    fn drop(&mut self) {
        self.zeroize_sensitive_fields();
    }
}

/// Sync status information.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatus {
    /// Last synced block height
    pub last_synced_block: u32,
    /// Current chain tip
    pub current_block: u32,
    /// Sync progress (0.0 to 1.0)
    pub progress: f32,
    /// Whether sync is in progress
    pub is_syncing: bool,
    /// Error message if any
    pub error: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn spendable_note_data_zeroizes_sensitive_strings() {
        let mut note = SpendableNoteData {
            diversifier: "0102030405060708090a0b".to_string(),
            pk_d: "11".repeat(32),
            value: 42,
            rcm: "22".repeat(32),
            rseed: "33".repeat(32),
            witness: "44".repeat(1024),
            witness_position: 7,
            nullifier: "55".repeat(32),
            cmu: Some("66".repeat(32)),
            memo: Some("sensitive memo".to_string()),
        };

        note.zeroize_sensitive_fields();

        assert!(note.diversifier.is_empty());
        assert!(note.pk_d.is_empty());
        assert_eq!(note.value, 42);
        assert!(note.rcm.is_empty());
        assert!(note.rseed.is_empty());
        assert!(note.witness.is_empty());
        assert_eq!(note.witness_position, 7);
        assert!(note.nullifier.is_empty());
        assert_eq!(note.cmu.as_deref(), Some(""));
        assert_eq!(note.memo.as_deref(), Some(""));
    }

    #[test]
    fn transaction_result_zeroizes_sensitive_strings() {
        let mut result = TransactionResult {
            txid: "aa".repeat(32),
            tx_hex: "bb".repeat(1200),
            nullifiers: vec!["cc".repeat(32), "dd".repeat(32)],
            fee: 10000,
        };

        result.zeroize_sensitive_fields();

        assert!(result.txid.is_empty());
        assert!(result.tx_hex.is_empty());
        assert!(result.nullifiers.is_empty());
        assert_eq!(result.fee, 10000);
    }

    #[test]
    fn transparent_utxo_data_zeroizes_sensitive_strings() {
        let mut utxo = TransparentUtxoData {
            txid: "aa".repeat(32),
            vout: 1,
            value: 12345,
            script_pubkey: "76a914".to_string(),
            private_key: "secret-wif".to_string(),
        };

        utxo.zeroize_sensitive_fields();

        assert!(utxo.txid.is_empty());
        assert_eq!(utxo.vout, 1);
        assert_eq!(utxo.value, 12345);
        assert!(utxo.script_pubkey.is_empty());
        assert!(utxo.private_key.is_empty());
    }

    #[test]
    fn transaction_options_zeroizes_sensitive_strings() {
        let mut options = TransactionOptions {
            to_address: "ps1recipient".to_string(),
            amount: 42,
            memo: Some("memo".to_string()),
            change_address: Some("ps1change".to_string()),
            block_height: 123,
        };

        options.zeroize_sensitive_fields();

        assert!(options.to_address.is_empty());
        assert_eq!(options.amount, 42);
        assert_eq!(options.memo.as_deref(), Some(""));
        assert_eq!(options.change_address.as_deref(), Some(""));
        assert_eq!(options.block_height, 123);
    }
}
