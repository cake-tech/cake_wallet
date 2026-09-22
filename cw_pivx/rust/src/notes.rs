//! PIVX Sapling note management.
//!
//! Handles Sapling notes (the fundamental unit of shielded value)
//! including decryption, nullifier computation, and spending.

use sapling::{Note, Nullifier, PaymentAddress};

use crate::error::SaplingError;

pub type SaplingResult<T> = Result<T, SaplingError>;

/// A decrypted Sapling note that can be spent.
#[derive(Clone, Debug)]
pub struct SpendableNote {
    pub note: Note,
    pub address: PaymentAddress,
    pub position: u64,
    pub nullifier: Nullifier,
    pub height: u32,
    pub tx_index: u32,
    pub output_index: u32,
    pub is_spent: bool,
    /// Decrypted memo for received notes; None when empty or on the spend path.
    pub memo: Option<String>,
}

impl SpendableNote {
    /// Value in zatoshis.
    pub fn value(&self) -> u64 {
        self.note.value().inner()
    }

    pub fn mark_spent(&mut self) {
        self.is_spent = true;
    }

    pub fn new(
        note: Note,
        address: PaymentAddress,
        position: u64,
        nullifier: Nullifier,
        height: u32,
        tx_index: u32,
        output_index: u32,
    ) -> Self {
        Self {
            note,
            address,
            position,
            nullifier,
            height,
            tx_index,
            output_index,
            is_spent: false,
            memo: None,
        }
    }
}

/// A compact note for sync (subset of full note data).
#[derive(Clone, Debug)]
pub struct CompactNote {
    pub cmu: [u8; 32],
    pub epk: [u8; 32],
    /// First 52 bytes of the encrypted ciphertext.
    pub enc_ciphertext: [u8; 52],
}

/// Greedily select unspent notes covering target_amount + fee.
pub fn select_notes_for_amount(
    notes: &[SpendableNote],
    target_amount: u64,
    fee: u64,
) -> SaplingResult<Vec<SpendableNote>> {
    let total_needed = target_amount + fee;

    let mut available: Vec<_> = notes.iter().filter(|n| !n.is_spent).cloned().collect();
    available.sort_by(|a, b| b.value().cmp(&a.value()));

    let mut selected = Vec::new();
    let mut selected_total = 0u64;

    for note in available {
        if selected_total >= total_needed {
            break;
        }
        selected_total += note.value();
        selected.push(note);
    }

    if selected_total < total_needed {
        return Err(SaplingError::InsufficientFunds);
    }

    Ok(selected)
}

/// Parse a merkle path from hex-encoded witness data.
///
/// The ElectrumX witness is 32 sibling hashes, 32 bytes each (1024 bytes).
pub fn parse_merkle_path(witness_hex: &str, position: u64) -> SaplingResult<sapling::MerklePath> {
    use incrementalmerkletree::Position;
    use sapling::Node;

    const SAPLING_TREE_DEPTH: usize = 32;
    const NODE_SIZE: usize = 32;

    let witness_bytes = hex::decode(witness_hex).map_err(|_| SaplingError::InvalidWitness)?;

    if witness_bytes.len() != SAPLING_TREE_DEPTH * NODE_SIZE {
        return Err(SaplingError::InvalidWitness);
    }

    let mut path_elems = Vec::with_capacity(SAPLING_TREE_DEPTH);
    for i in 0..SAPLING_TREE_DEPTH {
        let start = i * NODE_SIZE;
        let end = start + NODE_SIZE;
        let node_bytes: [u8; 32] = witness_bytes[start..end]
            .try_into()
            .map_err(|_| SaplingError::InvalidWitness)?;

        let node_opt = Node::from_bytes(node_bytes);
        if bool::from(node_opt.is_none()) {
            return Err(SaplingError::InvalidWitness);
        }
        path_elems.push(node_opt.unwrap()); // Safe: just checked is_none()
    }

    let pos = Position::from(position);
    sapling::MerklePath::from_parts(path_elems, pos).map_err(|_| SaplingError::InvalidWitness)
}

/// Recompute the Sapling Merkle root from a witness and compare it to an
/// expected anchor.
///
/// The witness is parsed with [`parse_merkle_path`], the same routine used to
/// build spend `MerklePath`s, so verification covers exactly the bytes that
/// would enter proof construction. Non-canonical cmu or anchor bytes are
/// errors, not mismatches.
///
/// Returns `Ok(true)` when the recomputed root equals `expected_anchor`,
/// `Ok(false)` on a clean mismatch.
pub fn verify_witness_root(
    witness_hex: &str,
    position: u64,
    cmu: [u8; 32],
    expected_anchor: [u8; 32],
) -> SaplingResult<bool> {
    use sapling::note::ExtractedNoteCommitment;
    use sapling::{Anchor, Node};

    let path = parse_merkle_path(witness_hex, position)?;

    let cmu = match ExtractedNoteCommitment::from_bytes(&cmu).into_option() {
        Some(cmu) => cmu,
        None => {
            return Err(SaplingError::InvalidInput(
                "Non-canonical note commitment bytes".into(),
            ))
        }
    };
    let expected = match Anchor::from_bytes(expected_anchor).into_option() {
        Some(anchor) => anchor,
        None => return Err(SaplingError::InvalidAnchor),
    };

    let root = Anchor::from(path.root(Node::from_cmu(&cmu)));
    Ok(root.to_bytes() == expected.to_bytes())
}

/// Reconstruct a Note from serialized data.
///
/// This is used when loading saved notes from storage for spending.
pub fn note_from_parts(
    diversifier_hex: &str,
    pk_d_hex: &str,
    value: u64,
    rseed_hex: &str,
) -> SaplingResult<(Note, PaymentAddress)> {
    use sapling::{value::NoteValue, Rseed};

    let diversifier_bytes: [u8; 11] = hex::decode(diversifier_hex)
        .map_err(|_| SaplingError::InvalidInput("invalid diversifier hex".into()))?
        .try_into()
        .map_err(|_| SaplingError::InvalidInput("diversifier must be 11 bytes".into()))?;

    let pk_d_bytes: [u8; 32] = hex::decode(pk_d_hex)
        .map_err(|_| SaplingError::InvalidInput("invalid pk_d hex".into()))?
        .try_into()
        .map_err(|_| SaplingError::InvalidInput("pk_d must be 32 bytes".into()))?;

    // Construct the 43-byte payment address: diversifier (11) + pk_d (32)
    let mut addr_bytes = [0u8; 43];
    addr_bytes[..11].copy_from_slice(&diversifier_bytes);
    addr_bytes[11..].copy_from_slice(&pk_d_bytes);

    let address = PaymentAddress::from_bytes(&addr_bytes).ok_or(SaplingError::InvalidAddress)?;

    // Parse rseed (32 bytes); for pre-ZIP-212 this is rcm
    let rseed_bytes: [u8; 32] = hex::decode(rseed_hex)
        .map_err(|_| SaplingError::InvalidInput("invalid rseed hex".into()))?
        .try_into()
        .map_err(|_| SaplingError::InvalidInput("rseed must be 32 bytes".into()))?;

    // For PIVX (pre-ZIP-212), rseed is the commitment randomness directly
    let fr_opt = jubjub::Fr::from_bytes(&rseed_bytes);
    if bool::from(fr_opt.is_none()) {
        return Err(SaplingError::InvalidInput("invalid rseed scalar".into()));
    }
    let rseed = Rseed::BeforeZip212(fr_opt.unwrap()); // Safe: just checked is_none()

    let note = Note::from_parts(address.clone(), NoteValue::from_raw(value), rseed);

    Ok((note, address))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_note_selection_insufficient() {
        let notes: Vec<SpendableNote> = vec![];
        let result = select_notes_for_amount(&notes, 1000, 100);
        assert!(result.is_err());
    }

    /// 32 canonical sibling nodes (value 1, little-endian) as witness hex.
    pub(crate) fn test_witness_hex() -> String {
        let mut node = [0u8; 32];
        node[0] = 1;
        hex::encode(node).repeat(32)
    }

    /// Canonical cmu bytes (value 2, little-endian).
    pub(crate) fn test_cmu_bytes() -> [u8; 32] {
        let mut cmu = [0u8; 32];
        cmu[0] = 2;
        cmu
    }

    /// The anchor that test_witness_hex + test_cmu_bytes recompute to.
    pub(crate) fn test_expected_anchor() -> [u8; 32] {
        use sapling::note::ExtractedNoteCommitment;
        use sapling::{Anchor, Node};

        let path = parse_merkle_path(&test_witness_hex(), 0).unwrap();
        let cmu = ExtractedNoteCommitment::from_bytes(&test_cmu_bytes())
            .into_option()
            .unwrap();
        Anchor::from(path.root(Node::from_cmu(&cmu))).to_bytes()
    }

    #[test]
    fn test_verify_witness_root_accepts_matching_anchor() {
        let result = verify_witness_root(
            &test_witness_hex(),
            0,
            test_cmu_bytes(),
            test_expected_anchor(),
        );
        assert!(matches!(result, Ok(true)));
    }

    #[test]
    fn test_verify_witness_root_rejects_tampered_sibling() {
        // Flip one sibling from value 1 to value 3 (still canonical) so the
        // failure is a clean root mismatch, not a parse error.
        let mut witness = test_witness_hex();
        witness.replace_range(0..2, "03");

        let result =
            verify_witness_root(&witness, 0, test_cmu_bytes(), test_expected_anchor());
        assert!(matches!(result, Ok(false)));
    }

    #[test]
    fn test_verify_witness_root_position_changes_root() {
        // Same siblings and leaf at a different position must not verify.
        let result = verify_witness_root(
            &test_witness_hex(),
            1,
            test_cmu_bytes(),
            test_expected_anchor(),
        );
        assert!(matches!(result, Ok(false)));
    }

    #[test]
    fn test_verify_witness_root_rejects_non_canonical_bytes() {
        // Non-canonical cmu is an error, not a mismatch.
        assert!(verify_witness_root(
            &test_witness_hex(),
            0,
            [0xff; 32],
            test_expected_anchor()
        )
        .is_err());

        // Non-canonical anchor is an error, not a mismatch.
        assert!(
            verify_witness_root(&test_witness_hex(), 0, test_cmu_bytes(), [0xff; 32])
                .is_err()
        );

        // Non-canonical sibling node in the witness is an error.
        let mut witness = test_witness_hex();
        witness.replace_range(0..64, &"ff".repeat(32));
        assert!(verify_witness_root(
            &witness,
            0,
            test_cmu_bytes(),
            test_expected_anchor()
        )
        .is_err());

        // Truncated witness is an error.
        assert!(verify_witness_root(
            &test_witness_hex()[..64 * 31],
            0,
            test_cmu_bytes(),
            test_expected_anchor()
        )
        .is_err());
    }

    // Real spendable witness captured from electrum02.chainster.org
    // (pivx.sapling.electrumx.v1, hex_byte_order=display), global_position 0.
    // Determines empirically which byte order the prover needs.
    fn chainster_fixture() -> (String, [u8; 32], [u8; 32]) {
        const CMU_DISPLAY: &str =
            "219abc22220f9e133c4414d9462b9d86e3c8fb1b6ccda36ff0d919c5f6588a95";
        const ANCHOR_DISPLAY: &str =
            "23ad2c39c720e69af6cf5c7cca8aa501d7a36964ba7d9755659b242fb6dd06db";
        const PATH: [&str; 32] = [
            "7352fa42ff23e572387ba965db04bdc6fd6cab74b97338c4c79948c6dc4bc33c",
            "ce75b04ebdcf92ea0cab93bf5fc2cd675fc867accacb42550f357950b8fc3a14",
            "6875488967e1008d7fec44841dab10a7c244266bdb936a9fad10e798da1a5b39",
            "76fe6c77f4f4603669b1159e519329f97744e69dcffef6b6266cf5c3c916eb31",
            "61022337bf970d2de80803684e0fe6248c3c6a7ad581433ffda690cdc8ec0a42",
            "938988a2c5c64733c988336bff7b5d8416277036363aeaad0968afffe665de1b",
            "30d3896b4ead5b4c9db948361c6466acc6bc0a6d44af52b5ce75a107ff186b51",
            "ac787541cd73929dca61aff447c2995ac74ec0c59f3a769ce02553162ea9162c",
            "3ec002c09ed73b1133790de0cf66a847ba5495e2568e0c05d4a07ce691b14d0a",
            "273e391d61d8df4c83d402ed2e46702c81841092e3a9499bc72082d0c5fc241c",
            "e401f0174fefa0bd37301482536d9541ef16b48d2a5f75077bc9c55eaf35ac4e",
            "53925b451d437417eb98769352a43b8456f444c7e6374a25d6872be946090134",
            "b9e09e33386178a9254c48f516a17321a282fba02d4b77bce690be8563ee3122",
            "10c0eec61907cef40126df0126ff8d0605643116f62aaa6b8cc0b2839ed4af1e",
            "49453ebd0c7871ff489ffc45714ef15cdd027053bcf94c4a64a220d473b7a10a",
            "af1e4b9097509e5be5765725c27ae59e0819e64649aee556c72d773b08ea500a",
            "1ea6675f9551eeb9dfaaa9247bc9858270d3d3a4c5afa7177a984d5ed1be2451",
            "6edb16d01907b759977d7650dad7e3ec049af1a3d875380b697c862c9ec5d51c",
            "cd1c8dbf6e3acc7a80439bc4962cf25b9dce7c896f3a5bd70803fc5a0e33cf00",
            "6aca8448d8263e547d5ff2950e2ed3839e998d31cbc6ac9fd57bc6002b159216",
            "8d5fa43e5a10d11605ac7430ba1f5d81fb1b68d29a640405767749e841527673",
            "08eeab0c13abd6069e6310197bf80f9c1ea6de78fd19cbae24d4a520e6cf3023",
            "0769557bc682b1bf308646fd0b22e648e8b9e98f57e29f5af40f6edb833e2c49",
            "4c6937d78f42685f84b43ad3b7b00f81285662f85c6a68ef11d62ad1a3ee0850",
            "fee0e52802cb0c46b1eb4d376c62697f4759f6c8917fa352571202fd778fd712",
            "16d6252968971a83da8521d65382e61f0176646d771c91528e3276ee45383e4a",
            "d2e1642c9a462229289e5b0e3b7f9008e0301cbb93385ee0e21da2545073cb58",
            "a5122c08ff9c161d9ca6fc462073396c7d7d38e8ee48cdb3bea7e2230134ed6a",
            "28e7b841dcbc47cceb69d7cb8d94245fb7cb2ba3a7a6bc18f13f945f7dbd6e2a",
            "e1f34b034d4a3cd28557e2907ebf990c918f64ecb50a94f01d6fda5ca5c7ef72",
            "12935f14b676509b81eb49ef25f39269ed72309238b4c145803544b646dca62d",
            "b2eed031d4d6a4f02a097f80b54cc1541d4163c6b6f5971f88b6e41d35c53814",
        ];
        let to32 = |s: &str| -> [u8; 32] {
            hex::decode(s).unwrap().try_into().unwrap()
        };
        (PATH.join(""), to32(CMU_DISPLAY), to32(ANCHOR_DISPLAY))
    }

    fn rev(mut b: [u8; 32]) -> [u8; 32] {
        b.reverse();
        b
    }

    #[test]
    fn chainster_v1_witness_needs_display_to_serialization_reversal() {
        let (path, cmu_disp, anchor_disp) = chainster_fixture();
        // Try every cmu/anchor byte-order combination against the raw path.
        let combos: [(&str, [u8; 32], [u8; 32]); 4] = [
            ("display/display", cmu_disp, anchor_disp),
            ("reversed/reversed", rev(cmu_disp), rev(anchor_disp)),
            ("reversed/display", rev(cmu_disp), anchor_disp),
            ("display/reversed", cmu_disp, rev(anchor_disp)),
        ];
        let mut winner = None;
        for (label, cmu, anchor) in combos {
            let r = verify_witness_root(&path, 0, cmu, anchor);
            if matches!(r, Ok(true)) {
                winner = Some(label);
            }
        }
        // The wallet currently passes display order as-is; prove that fails and
        // that reversing cmu+anchor (display -> serialization) is what works.
        assert!(
            matches!(verify_witness_root(&path, 0, cmu_disp, anchor_disp), Ok(false))
                || verify_witness_root(&path, 0, cmu_disp, anchor_disp).is_err(),
            "display-as-is must NOT verify (that is the send regression)"
        );
        assert_eq!(
            winner,
            Some("reversed/reversed"),
            "reversing cmu+anchor from display to serialization order must verify"
        );
    }
}
