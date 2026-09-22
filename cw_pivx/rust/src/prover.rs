//! Sapling prover using Groth16 proofs.
//!
//! This module handles loading proving parameters and generating
//! zero-knowledge proofs for Sapling transactions.

use std::fs;
use std::path::Path;
use std::sync::Mutex;

use lazy_static::lazy_static;
use sha2::{Digest, Sha256};
use zcash_proofs::prover::LocalTxProver;

use crate::error::SaplingError;

lazy_static! {
    /// Global prover instance (expensive to create, reuse across transactions).
    static ref PROVER: Mutex<Option<LocalTxProver>> = Mutex::new(None);
}

/// Expected SHA256 hash of sapling-spend.params (Zcash Sapling parameters).
/// These parameters are the same for PIVX as they are based on the Zcash Sapling protocol.
/// Current wallet download source: https://duddino.com/sapling-spend.params
pub const EXPECTED_SPEND_HASH: &str =
    "8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13";

/// Expected SHA256 hash of sapling-output.params.
/// Current wallet download source: https://duddino.com/sapling-output.params
pub const EXPECTED_OUTPUT_HASH: &str =
    "2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4";

fn verify_param_hash(path: &str, expected: &str) -> Result<(), SaplingError> {
    let data = fs::read(path).map_err(|e| {
        SaplingError::InvalidInput(format!("Failed to read parameter file {}: {}", path, e))
    })?;

    let hash = Sha256::digest(&data);
    let hash_hex = hex::encode(hash);

    if hash_hex != expected {
        return Err(SaplingError::InvalidInput(format!(
            "Parameter file {} hash mismatch.\nExpected: {}\nGot: {}\n\
                This could indicate a corrupted or malicious parameter file. \
                Please re-download the proving parameters.",
            path, expected, hash_hex
        )));
    }

    Ok(())
}

pub fn has_proving_params(params_dir: &str) -> bool {
    let spend_path = format!("{}/sapling-spend.params", params_dir);
    let output_path = format!("{}/sapling-output.params", params_dir);

    Path::new(&spend_path).exists()
        && Path::new(&output_path).exists()
        && verify_param_hash(&spend_path, EXPECTED_SPEND_HASH).is_ok()
        && verify_param_hash(&output_path, EXPECTED_OUTPUT_HASH).is_ok()
}

/// Initialize the prover with parameters from a directory.
///
/// The directory should contain:
/// - sapling-spend.params (47 MB, verified by SHA256)
/// - sapling-output.params (3.6 MB, verified by SHA256)
///
/// Hash verification prevents the use of corrupted or backdoored parameters.
pub fn init_prover(params_dir: &str) -> Result<(), SaplingError> {
    let spend_path = format!("{}/sapling-spend.params", params_dir);
    let output_path = format!("{}/sapling-output.params", params_dir);

    if !Path::new(&spend_path).exists() {
        return Err(SaplingError::InvalidInput(format!(
            "Spend params not found: {}",
            spend_path
        )));
    }
    if !Path::new(&output_path).exists() {
        return Err(SaplingError::InvalidInput(format!(
            "Output params not found: {}",
            output_path
        )));
    }

    // Verify parameter file hashes (CRITICAL SECURITY CHECK)
    verify_param_hash(&spend_path, EXPECTED_SPEND_HASH)?;
    verify_param_hash(&output_path, EXPECTED_OUTPUT_HASH)?;

    let prover = LocalTxProver::new(Path::new(&spend_path), Path::new(&output_path));

    let mut global = PROVER
        .lock()
        .map_err(|_| SaplingError::InvalidInput("Failed to lock prover mutex".into()))?;
    *global = Some(prover);

    Ok(())
}

pub fn is_prover_initialized() -> bool {
    PROVER.lock().map(|p| p.is_some()).unwrap_or(false)
}

pub fn get_prover() -> Result<std::sync::MutexGuard<'static, Option<LocalTxProver>>, SaplingError> {
    let guard = PROVER
        .lock()
        .map_err(|_| SaplingError::InvalidInput("Failed to lock prover mutex".into()))?;

    if guard.is_none() {
        return Err(SaplingError::ProverNotInitialized);
    }

    Ok(guard)
}

pub fn dispose_prover() {
    if let Ok(mut guard) = PROVER.lock() {
        *guard = None;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_expected_param_hashes_are_canonical_sha256() {
        assert_eq!(EXPECTED_SPEND_HASH.len(), 64);
        assert_eq!(EXPECTED_OUTPUT_HASH.len(), 64);
        assert_eq!(
            EXPECTED_SPEND_HASH,
            "8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13"
        );
        assert_eq!(
            EXPECTED_OUTPUT_HASH,
            "2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4"
        );
    }

    #[test]
    fn test_prover_not_initialized() {
        assert!(!is_prover_initialized());
    }
}
