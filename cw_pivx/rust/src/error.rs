//! Error types for the PIVX Sapling library.

use thiserror::Error;

#[derive(Error, Debug)]
pub enum SaplingError {
    #[error("Invalid seed")]
    InvalidSeed,

    #[error("Invalid key")]
    InvalidKey,

    #[error("Invalid address")]
    InvalidAddress,

    #[error("Invalid diversifier")]
    InvalidDiversifier,

    #[error("Invalid input: {0}")]
    InvalidInput(String),

    #[error("Key derivation failed")]
    KeyDerivation,

    #[error("Encoding error")]
    Encoding,

    #[error("Decoding error")]
    Decoding,

    #[error("Note decryption failed")]
    NoteDecryption,

    #[error("Transaction building failed")]
    TransactionBuild,

    #[error("Proof error: {0}")]
    ProofError(String),

    #[error("Invalid witness")]
    InvalidWitness,

    #[error("Witness not found")]
    WitnessNotFound,

    #[error("Tree error")]
    TreeError,

    #[error("Invalid anchor")]
    InvalidAnchor,

    #[error("Insufficient funds")]
    InsufficientFunds,

    #[error("Prover not initialized")]
    ProverNotInitialized,

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Hex decoding error: {0}")]
    Hex(#[from] hex::FromHexError),

    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("Internal error: {0}")]
    Internal(String),
}

pub type Result<T> = std::result::Result<T, SaplingError>;
