use thiserror::Error;

#[derive(Error, Debug)]
pub enum MinotariError {
    #[error("Invalid mnemonic: {0}")]
    InvalidMnemonic(String),

    #[error("Wallet error: {0}")]
    WalletError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Network error: {0}")]
    NetworkError(String),

    #[error("Serialization error: {0}")]
    SerializationError(String),

    #[error("Key derivation error: {0}")]
    KeyDerivationError(String),
}
