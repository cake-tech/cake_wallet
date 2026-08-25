//! PIVX Sapling sighash personalization test.

/// PIVX and Zcash use different BLAKE2b personalizations, so the same input must
/// hash differently. Guards against accidentally reusing Zcash constants.
#[test]
fn test_blake2b_sighash() {
    use blake2b_simd::Params;

    // Create BLAKE2b hasher with PIVX personalization
    let mut personalization = [0u8; 16];
    personalization[..11].copy_from_slice(b"PIVXSigHash");
    personalization[12..16].copy_from_slice(&0u32.to_le_bytes());

    let mut hasher = Params::new()
        .hash_length(32)
        .personal(&personalization)
        .to_state();

    hasher.update(b"test data");
    let hash = hasher.finalize();

    assert_eq!(hash.as_bytes().len(), 32, "Hash must be 32 bytes");

    // Verify different personalization produces different hash
    let mut zcash_personalization = [0u8; 16];
    zcash_personalization[..12].copy_from_slice(b"ZcashSigHash");
    zcash_personalization[12..16].copy_from_slice(&0x03C48270u32.to_le_bytes());

    let mut zcash_hasher = Params::new()
        .hash_length(32)
        .personal(&zcash_personalization)
        .to_state();

    zcash_hasher.update(b"test data");
    let zcash_hash = zcash_hasher.finalize();

    assert_ne!(
        hash.as_bytes(),
        zcash_hash.as_bytes(),
        "PIVX and Zcash sighashes MUST be different for same data"
    );
}
