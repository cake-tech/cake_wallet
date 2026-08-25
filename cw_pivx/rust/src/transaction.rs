//! PIVX Sapling transaction building.
//!
//! Builds shielded transactions using Groth16 proofs.

use rand::rngs::OsRng;
use sapling::{
    builder::{Builder as SaplingBuilder, BundleType},
    note_encryption::Zip212Enforcement,
    value::NoteValue,
    zip32::{DiversifiableFullViewingKey, ExtendedSpendingKey},
    Anchor, MerklePath, Node, PaymentAddress, SaplingVerificationContext,
};
use zcash_primitives::zip32::Scope;
use zcash_protocol::consensus::{BlockHeight, NetworkType, NetworkUpgrade, Parameters};

use crate::error::SaplingError;
use crate::notes::SpendableNote;
use crate::prover;

pub type SaplingResult<T> = Result<T, SaplingError>;

/// PIVX max supply: 21,000,000 coins = 21,000,000,000,000 zatoshis (21 trillion zatoshis).
pub const PIVX_MAX_SUPPLY: u64 = 21_000_000_000_000u64;

/// Shielded dust threshold derived from PIVX Core v5.6.1:
/// 100 * dustRelayFee.GetFee(384-byte spend + 34-byte txout + 64-byte binding sig).
pub const SHIELDED_DUST_THRESHOLD: u64 = 1_446_000u64;

/// Transparent dust threshold derived from PIVX Core v5.6.1:
/// dustRelayFee.GetFee(182) with dust relay fee 30,000 zatoshis/kB.
pub const TRANSPARENT_DUST_THRESHOLD: u64 = 5_460u64;

/// PIVX base58check address prefixes (PIVX Core src/chainparams.cpp).
const PIVX_MAINNET_PUBKEY_PREFIX: u8 = 30; // 'D...'
const PIVX_MAINNET_SCRIPT_PREFIX: u8 = 13; // '6...'
const PIVX_TESTNET_PUBKEY_PREFIX: u8 = 139; // 'x.../y...'
const PIVX_TESTNET_SCRIPT_PREFIX: u8 = 19; // '8.../9...'

/// A transparent output for shielded-to-transparent (deshield) transactions.
#[derive(Debug, Clone)]
pub struct TransparentOutput {
    /// Value in zatoshis.
    pub value: u64,
    /// Raw scriptPubKey bytes.
    pub script_pubkey: Vec<u8>,
}

impl TransparentOutput {
    /// Build a transparent output paying a PIVX base58check address.
    pub fn to_address(address: &str, value: u64, testnet: bool) -> SaplingResult<Self> {
        let script_pubkey = script_pubkey_for_transparent_address(address, testnet)?;
        Ok(TransparentOutput {
            value,
            script_pubkey,
        })
    }

    fn serialize_into(&self, buf: &mut Vec<u8>) {
        buf.extend_from_slice(&self.value.to_le_bytes());
        write_compact_size(buf, self.script_pubkey.len() as u64);
        buf.extend_from_slice(&self.script_pubkey);
    }
}

fn write_compact_size(buf: &mut Vec<u8>, n: u64) {
    if n < 0xfd {
        buf.push(n as u8);
    } else if n <= 0xffff {
        buf.push(0xfd);
        buf.extend_from_slice(&(n as u16).to_le_bytes());
    } else if n <= 0xffffffff {
        buf.push(0xfe);
        buf.extend_from_slice(&(n as u32).to_le_bytes());
    } else {
        buf.push(0xff);
        buf.extend_from_slice(&n.to_le_bytes());
    }
}

/// Serialize transparent outputs exactly as PIVX Core serializes `vout`
/// (compact size count, then per output: value LE64 + scriptPubKey).
pub fn serialize_transparent_outputs(buf: &mut Vec<u8>, outputs: &[TransparentOutput]) {
    write_compact_size(buf, outputs.len() as u64);
    for output in outputs {
        output.serialize_into(buf);
    }
}

/// Decode a PIVX base58check transparent address into its scriptPubKey.
///
/// Supports P2PKH and P2SH for the requested network and rejects
/// wrong-network or malformed addresses.
pub fn script_pubkey_for_transparent_address(
    address: &str,
    testnet: bool,
) -> SaplingResult<Vec<u8>> {
    let payload = base58check_decode(address)?;
    if payload.len() != 21 {
        return Err(SaplingError::InvalidInput(
            "Transparent address payload must be 21 bytes".into(),
        ));
    }
    let (pubkey_prefix, script_prefix) = if testnet {
        (PIVX_TESTNET_PUBKEY_PREFIX, PIVX_TESTNET_SCRIPT_PREFIX)
    } else {
        (PIVX_MAINNET_PUBKEY_PREFIX, PIVX_MAINNET_SCRIPT_PREFIX)
    };
    let version = payload[0];
    let hash = &payload[1..21];
    if version == pubkey_prefix {
        // OP_DUP OP_HASH160 <20 bytes> OP_EQUALVERIFY OP_CHECKSIG
        let mut script = Vec::with_capacity(25);
        script.push(0x76);
        script.push(0xa9);
        script.push(0x14);
        script.extend_from_slice(hash);
        script.push(0x88);
        script.push(0xac);
        Ok(script)
    } else if version == script_prefix {
        // OP_HASH160 <20 bytes> OP_EQUAL
        let mut script = Vec::with_capacity(23);
        script.push(0xa9);
        script.push(0x14);
        script.extend_from_slice(hash);
        script.push(0x87);
        Ok(script)
    } else {
        Err(SaplingError::InvalidInput(
            "Transparent address version does not match the selected PIVX network".into(),
        ))
    }
}

const BASE58_ALPHABET: &[u8; 58] =
    b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

fn base58check_decode(input: &str) -> SaplingResult<Vec<u8>> {
    if input.is_empty() || input.len() > 100 {
        return Err(SaplingError::InvalidInput(
            "Invalid base58 address length".into(),
        ));
    }

    let mut bytes: Vec<u8> = Vec::with_capacity(25);
    for ch in input.bytes() {
        let digit = BASE58_ALPHABET
            .iter()
            .position(|&c| c == ch)
            .ok_or_else(|| {
                SaplingError::InvalidInput("Invalid base58 character in address".into())
            })? as u32;
        let mut carry = digit;
        for byte in bytes.iter_mut() {
            carry += (*byte as u32) * 58;
            *byte = (carry & 0xff) as u8;
            carry >>= 8;
        }
        while carry > 0 {
            bytes.push((carry & 0xff) as u8);
            carry >>= 8;
        }
    }
    // Leading '1' characters encode leading zero bytes.
    for ch in input.bytes() {
        if ch == b'1' {
            bytes.push(0);
        } else {
            break;
        }
    }
    bytes.reverse();

    if bytes.len() < 5 {
        return Err(SaplingError::InvalidInput(
            "Base58 address payload too short".into(),
        ));
    }
    let (payload, checksum) = bytes.split_at(bytes.len() - 4);
    use sha2::{Digest, Sha256};
    let digest = Sha256::digest(Sha256::digest(payload));
    if digest[..4] != checksum[..] {
        return Err(SaplingError::InvalidInput(
            "Base58 address checksum mismatch".into(),
        ));
    }
    Ok(payload.to_vec())
}

/// A transparent UTXO being spent in a transparent-to-shielded (shield)
/// transaction, with its signing key.
pub struct TransparentInput {
    /// Previous output txid in internal byte order (reversed display hex).
    pub prevout_txid: [u8; 32],
    /// Previous output index.
    pub prevout_index: u32,
    /// UTXO value in zatoshis.
    pub value: u64,
    /// The UTXO's scriptPubKey (must be P2PKH).
    pub script_pubkey: Vec<u8>,
    secret_key: secp256k1::SecretKey,
}

impl TransparentInput {
    /// Default Bitcoin/PIVX sequence number.
    pub const SEQUENCE_FINAL: u32 = 0xffff_ffff;

    /// Parse and validate a UTXO + key pair.
    ///
    /// The private key must be 32-byte hex, and the compressed public key it
    /// derives must hash to the P2PKH hash in `script_pubkey` so a wrong key
    /// fails closed before signing.
    pub fn from_parts(
        txid_hex: &str,
        vout: u32,
        value: u64,
        script_pubkey_hex: &str,
        private_key_hex: &str,
    ) -> SaplingResult<Self> {
        let txid_display = hex::decode(txid_hex)
            .map_err(|_| SaplingError::InvalidInput("Invalid UTXO txid hex".into()))?;
        if txid_display.len() != 32 {
            return Err(SaplingError::InvalidInput(
                "UTXO txid must be 32 bytes".into(),
            ));
        }
        let mut prevout_txid = [0u8; 32];
        prevout_txid.copy_from_slice(&txid_display);
        prevout_txid.reverse();

        let script_pubkey = hex::decode(script_pubkey_hex)
            .map_err(|_| SaplingError::InvalidInput("Invalid UTXO script hex".into()))?;
        if script_pubkey.len() != 25
            || script_pubkey[0] != 0x76
            || script_pubkey[1] != 0xa9
            || script_pubkey[2] != 0x14
            || script_pubkey[23] != 0x88
            || script_pubkey[24] != 0xac
        {
            return Err(SaplingError::InvalidInput(
                "Shield inputs must be P2PKH UTXOs".into(),
            ));
        }

        let key_bytes = hex::decode(private_key_hex).map_err(|_| {
            SaplingError::InvalidInput("UTXO private key must be 32-byte hex".into())
        })?;
        if key_bytes.len() != 32 {
            return Err(SaplingError::InvalidInput(
                "UTXO private key must be 32 bytes".into(),
            ));
        }
        let secret_key = secp256k1::SecretKey::from_slice(&key_bytes)
            .map_err(|_| SaplingError::InvalidInput("Invalid UTXO private key".into()))?;

        let secp = secp256k1::Secp256k1::signing_only();
        let pubkey = secret_key.public_key(&secp).serialize();
        use ripemd::Ripemd160;
        use sha2::{Digest, Sha256};
        let pubkey_hash = Ripemd160::digest(Sha256::digest(pubkey));
        if pubkey_hash[..] != script_pubkey[3..23] {
            return Err(SaplingError::InvalidInput(
                "UTXO private key does not match the script public key hash".into(),
            ));
        }

        Ok(TransparentInput {
            prevout_txid,
            prevout_index: vout,
            value,
            script_pubkey,
            secret_key,
        })
    }

    fn serialize_prevout(&self, buf: &mut Vec<u8>) {
        buf.extend_from_slice(&self.prevout_txid);
        buf.extend_from_slice(&self.prevout_index.to_le_bytes());
    }

    /// Sign the per-input sighash and assemble the P2PKH scriptSig
    /// (push(DER signature + SIGHASH_ALL) push(compressed pubkey)).
    fn script_sig(&self, sighash: [u8; 32]) -> Vec<u8> {
        let secp = secp256k1::Secp256k1::signing_only();
        let message = secp256k1::Message::from_digest(sighash);
        let signature = secp.sign_ecdsa(&message, &self.secret_key);
        let mut der = signature.serialize_der().to_vec();
        der.push(0x01); // SIGHASH_ALL
        let pubkey = self.secret_key.public_key(&secp).serialize();

        let mut script_sig = Vec::with_capacity(2 + der.len() + pubkey.len());
        script_sig.push(der.len() as u8);
        script_sig.extend_from_slice(&der);
        script_sig.push(pubkey.len() as u8);
        script_sig.extend_from_slice(&pubkey);
        script_sig
    }
}

fn pivx_sighash_personalization() -> [u8; 16] {
    let mut personalization = [0u8; 16];
    let prefix = b"PIVXSigHash";
    personalization[..prefix.len()].copy_from_slice(prefix);
    // PIVX uses branch ID 0 (not Zcash's 0x03C48270)
    personalization[12..16].copy_from_slice(&0u32.to_le_bytes());
    personalization
}

/// Validate transaction amounts to prevent overflow and invalid sums.
///
/// Checks:
/// - Integer overflow protection
/// - Max supply limits
/// - Dust threshold
/// - Inputs cover outputs plus fee; change is added later by the builder
pub fn validate_transaction_amounts(
    input_amounts: &[u64],
    output_amounts: &[u64],
    fee: u64,
) -> Result<(), SaplingError> {
    // No absolute fee cap: PIVX Core enforces no fixed maximum (only a relative
    // GetShieldedTxMinFee*100 guard under fRejectAbsurdFee). The planner sets the
    // fee to the exact required minimum, and for a deshield this value carries
    // the transparent output total on top, so a fixed cap here wrongly rejects
    // any deshield above the cap. The min-fee floor is enforced by the network.
    for (i, &amount) in output_amounts.iter().enumerate() {
        if amount < SHIELDED_DUST_THRESHOLD {
            return Err(SaplingError::InvalidInput(format!(
                "Output {} below dust threshold: {} zatoshis (min {} zatoshis)",
                i, amount, SHIELDED_DUST_THRESHOLD
            )));
        }
    }

    let mut input_total: u64 = 0;
    for (i, &amount) in input_amounts.iter().enumerate() {
        input_total = input_total.checked_add(amount).ok_or_else(|| {
            SaplingError::InvalidInput(format!("Input total overflow at input {}", i))
        })?;

        if amount > PIVX_MAX_SUPPLY {
            return Err(SaplingError::InvalidInput(format!(
                "Input {} exceeds max supply: {} > {}",
                i, amount, PIVX_MAX_SUPPLY
            )));
        }
    }

    let mut output_total: u64 = 0;
    for (i, &amount) in output_amounts.iter().enumerate() {
        output_total = output_total.checked_add(amount).ok_or_else(|| {
            SaplingError::InvalidInput(format!("Output total overflow at output {}", i))
        })?;

        if amount > PIVX_MAX_SUPPLY {
            return Err(SaplingError::InvalidInput(format!(
                "Output {} exceeds max supply: {} > {}",
                i, amount, PIVX_MAX_SUPPLY
            )));
        }
    }

    if input_total > PIVX_MAX_SUPPLY {
        return Err(SaplingError::InvalidInput(format!(
            "Input total exceeds max supply: {} > {}",
            input_total, PIVX_MAX_SUPPLY
        )));
    }

    if output_total > PIVX_MAX_SUPPLY {
        return Err(SaplingError::InvalidInput(format!(
            "Output total exceeds max supply: {} > {}",
            output_total, PIVX_MAX_SUPPLY
        )));
    }

    // Verify inputs cover outputs plus fee. The builder adds any remaining
    // value as a shielded change output after this validation.
    let expected_total = output_total
        .checked_add(fee)
        .ok_or_else(|| SaplingError::InvalidInput("Output + fee overflow".into()))?;

    if input_total < expected_total {
        return Err(SaplingError::InvalidInput(format!(
            "Insufficient funds: inputs={}, outputs+fee={}",
            input_total, expected_total
        )));
    }

    Ok(())
}

/// Validate amounts for a transaction that may pay both shielded and
/// transparent outputs (z-to-z and z-to-t routes).
///
/// Shielded outputs use the PIVX shielded dust threshold; transparent
/// outputs use the transparent dust threshold; inputs must cover the
/// combined outputs plus fee.
pub fn validate_route_transaction_amounts(
    input_amounts: &[u64],
    shielded_output_amounts: &[u64],
    transparent_output_amounts: &[u64],
    fee: u64,
) -> Result<(), SaplingError> {
    if shielded_output_amounts.is_empty() && transparent_output_amounts.is_empty() {
        return Err(SaplingError::InvalidInput("No outputs provided".into()));
    }

    for (i, &amount) in transparent_output_amounts.iter().enumerate() {
        if amount < TRANSPARENT_DUST_THRESHOLD {
            return Err(SaplingError::InvalidInput(format!(
                "Transparent output {} below dust threshold: {} zatoshis (min {} zatoshis)",
                i, amount, TRANSPARENT_DUST_THRESHOLD
            )));
        }
        if amount > PIVX_MAX_SUPPLY {
            return Err(SaplingError::InvalidInput(format!(
                "Transparent output {} exceeds max supply: {} > {}",
                i, amount, PIVX_MAX_SUPPLY
            )));
        }
    }

    let mut transparent_total: u64 = 0;
    for &amount in transparent_output_amounts {
        transparent_total = transparent_total.checked_add(amount).ok_or_else(|| {
            SaplingError::InvalidInput("Transparent output total overflow".into())
        })?;
    }

    // Shielded outputs, inputs, and the shielded-side balance reuse the
    // existing validator, then the combined balance including transparent
    // outputs is enforced on top.
    validate_transaction_amounts(
        input_amounts,
        shielded_output_amounts,
        fee.checked_add(transparent_total)
            .ok_or_else(|| SaplingError::InvalidInput("Output + fee overflow".into()))?,
    )?;

    Ok(())
}

/// PIVX Sapling activation height.
pub const PIVX_SAPLING_ACTIVATION: u32 = 2_700_500;
pub const PIVX_TESTNET_SAPLING_ACTIVATION: u32 = 201;

/// PIVX mainnet consensus parameters.
#[derive(Clone, Copy, Debug)]
pub struct PivxMainnet;

impl Parameters for PivxMainnet {
    fn network_type(&self) -> NetworkType {
        NetworkType::Main
    }

    fn activation_height(&self, nu: NetworkUpgrade) -> Option<BlockHeight> {
        match nu {
            NetworkUpgrade::Sapling => Some(BlockHeight::from_u32(PIVX_SAPLING_ACTIVATION)),
            _ => None,
        }
    }
}

/// PIVX testnet consensus parameters.
#[derive(Clone, Copy, Debug)]
pub struct PivxTestnet;

impl Parameters for PivxTestnet {
    fn network_type(&self) -> NetworkType {
        NetworkType::Test
    }

    fn activation_height(&self, nu: NetworkUpgrade) -> Option<BlockHeight> {
        match nu {
            NetworkUpgrade::Sapling => Some(BlockHeight::from_u32(PIVX_TESTNET_SAPLING_ACTIVATION)),
            _ => None,
        }
    }
}

/// Transaction output destination.
#[derive(Clone, Debug)]
pub enum TransactionOutput {
    /// Shielded output to a Sapling address.
    Shielded {
        address: PaymentAddress,
        amount: u64,
        memo: Option<[u8; 512]>,
    },
}

/// Options for building a transaction.
#[derive(Clone, Debug)]
pub struct TransactionOptions {
    /// Target height for the transaction.
    pub target_height: u32,
    /// Fee in zatoshis.
    pub fee: u64,
    /// Outputs to create.
    pub outputs: Vec<TransactionOutput>,
    /// Whether this is testnet.
    pub is_testnet: bool,
}

/// Built transaction ready for broadcast.
#[derive(Clone, Debug)]
pub struct BuiltTransaction {
    /// Serialized transaction bytes.
    pub raw_tx: Vec<u8>,
    /// Transaction ID (hash).
    pub txid: [u8; 32],
    /// Fee paid.
    pub fee: u64,
}

/// Sapling transaction builder.
pub struct TransactionBuilder {
    esk: ExtendedSpendingKey,
    dfvk: DiversifiableFullViewingKey,
    is_testnet: bool,
}

impl TransactionBuilder {
    pub fn new(
        esk: ExtendedSpendingKey,
        dfvk: DiversifiableFullViewingKey,
        is_testnet: bool,
    ) -> Self {
        Self {
            esk,
            dfvk,
            is_testnet,
        }
    }

    pub fn extended_spending_key(&self) -> &ExtendedSpendingKey {
        &self.esk
    }

    pub fn dfvk(&self) -> &DiversifiableFullViewingKey {
        &self.dfvk
    }

    pub fn is_testnet(&self) -> bool {
        self.is_testnet
    }

    pub fn validate_inputs(
        &self,
        notes: &[SpendableNote],
        merkle_paths: &[MerklePath],
        options: &TransactionOptions,
    ) -> SaplingResult<()> {
        if notes.len() != merkle_paths.len() {
            return Err(SaplingError::InvalidInput(
                "notes and paths length mismatch".into(),
            ));
        }

        let input_total: u64 = notes.iter().map(|n| n.value()).sum();
        let output_total: u64 = options
            .outputs
            .iter()
            .map(|o| match o {
                TransactionOutput::Shielded { amount, .. } => *amount,
            })
            .sum();

        if input_total < output_total + options.fee {
            return Err(SaplingError::InsufficientFunds);
        }

        Ok(())
    }

    pub fn calculate_change(notes: &[SpendableNote], options: &TransactionOptions) -> u64 {
        let input_total: u64 = notes.iter().map(|n| n.value()).sum();
        let output_total: u64 = options
            .outputs
            .iter()
            .map(|o| match o {
                TransactionOutput::Shielded { amount, .. } => *amount,
            })
            .sum();

        input_total.saturating_sub(output_total + options.fee)
    }

    pub fn change_address(&self) -> PaymentAddress {
        let (_, addr) = self.dfvk.default_address();
        addr
    }

    /// Build a z-to-z Sapling transaction. Thin wrapper over
    /// build_route_transaction with no transparent outputs.
    pub fn build_transaction(
        &self,
        notes: Vec<SpendableNote>,
        merkle_paths: Vec<MerklePath>,
        anchor: Anchor,
        outputs: Vec<(PaymentAddress, u64, Option<[u8; 512]>)>,
        fee: u64,
    ) -> SaplingResult<BuiltTransaction> {
        self.build_route_transaction(notes, merkle_paths, anchor, outputs, Vec::new(), fee)
    }

    /// Build a transparent-to-shielded (t-to-z, shield) transaction.
    ///
    /// Spends P2PKH UTXOs into Sapling outputs, with optional transparent
    /// change. Amounts must balance exactly: inputs = shielded outputs +
    /// change + fee; the caller plans fees and dust absorption.
    pub fn build_shield_transaction(
        &self,
        inputs: Vec<TransparentInput>,
        outputs: Vec<(PaymentAddress, u64, Option<[u8; 512]>)>,
        transparent_change: Option<TransparentOutput>,
        fee: u64,
    ) -> SaplingResult<BuiltTransaction> {
        if inputs.is_empty() {
            return Err(SaplingError::InvalidInput("No input UTXOs provided".into()));
        }
        if outputs.is_empty() {
            return Err(SaplingError::InvalidInput("No outputs provided".into()));
        }
        if !prover::is_prover_initialized() {
            return Err(SaplingError::ProverNotInitialized);
        }

        let input_amounts: Vec<u64> = inputs.iter().map(|input| input.value).collect();
        let output_amounts: Vec<u64> = outputs.iter().map(|(_, amount, _)| *amount).collect();
        let change_amounts: Vec<u64> = transparent_change
            .iter()
            .map(|output| output.value)
            .collect();
        validate_route_transaction_amounts(
            &input_amounts,
            &output_amounts,
            &change_amounts,
            fee,
        )?;

        let input_total: u64 = input_amounts.iter().sum();
        let output_total: u64 =
            output_amounts.iter().sum::<u64>() + change_amounts.iter().sum::<u64>();
        if input_total != output_total + fee {
            return Err(SaplingError::InvalidInput(format!(
                "Shield transaction amounts must balance exactly: inputs={}, outputs+fee={}",
                input_total,
                output_total + fee
            )));
        }

        // outputs-only shield, no spends. keep bundle_required false: with true,
        // num_spends pads to max(0,1)=1 and adds a dummy spend anchored to
        // empty_tree() that the node rejects (bad-txns-shielded-requirements-not-met).
        let bundle_type = BundleType::Transactional {
            bundle_required: false,
        };
        let mut builder = SaplingBuilder::new(
            Zip212Enforcement::Off,
            bundle_type,
            Anchor::empty_tree(),
        );
        let ovk = self.dfvk.to_ovk(Scope::External);
        for (address, amount, memo) in outputs {
            builder
                .add_output(Some(ovk.clone()), address, NoteValue::from_raw(amount), memo)
                .map_err(|_| SaplingError::TransactionBuild)?;
        }

        let mut rng = OsRng;
        let extsks: &[ExtendedSpendingKey] = &[];
        let build_result = builder
            .build::<zcash_proofs::prover::LocalTxProver, zcash_proofs::prover::LocalTxProver, _, i64>(extsks, &mut rng)
            .map_err(|e| SaplingError::ProofError(format!("Bundle build failed: {:?}", e)))?;
        let (unproven_bundle, _sapling_meta) = match build_result {
            Some(b) => b,
            None => return Err(SaplingError::TransactionBuild),
        };

        let prover_guard = prover::get_prover()?;
        let local_prover = prover_guard
            .as_ref()
            .ok_or(SaplingError::ProverNotInitialized)?;
        let proven_bundle =
            unproven_bundle.create_proofs(local_prover, local_prover, &mut rng, ());

        // Binding signature and every transparent input signature share the
        // common sighash legs over the real vin/vout and the Sapling bundle.
        let change_outputs: Vec<TransparentOutput> =
            transparent_change.iter().cloned().collect();
        let sighash_state =
            self.sighash_common_state(&proven_bundle, &inputs, &change_outputs);
        let binding_sighash = Self::finalize_binding_sighash(&sighash_state);

        let authorized_bundle = proven_bundle
            .apply_signatures(&mut rng, binding_sighash, &[])
            .map_err(|e| SaplingError::ProofError(format!("Signing failed: {:?}", e)))?;
        self.verify_authorized_bundle(&authorized_bundle, binding_sighash, local_prover)?;

        let script_sigs: Vec<Vec<u8>> = inputs
            .iter()
            .map(|input| {
                input.script_sig(Self::finalize_input_sighash(&sighash_state, input))
            })
            .collect();

        let raw_tx = self.serialize_pivx_transaction(
            &authorized_bundle,
            &inputs,
            &script_sigs,
            &change_outputs,
        )?;

        use sha2::{Digest, Sha256};
        let first_hash = Sha256::digest(&raw_tx);
        let txid_bytes = Sha256::digest(first_hash);
        let mut txid = [0u8; 32];
        txid.copy_from_slice(&txid_bytes);
        txid.reverse();

        Ok(BuiltTransaction { raw_tx, txid, fee })
    }

    /// Build a shielded transaction that may also pay transparent outputs
    /// (z-to-z when `transparent_outputs` is empty, z-to-t otherwise).
    ///
    /// Change always returns to the wallet's own shielded change address, so
    /// deshielding only exposes the explicitly requested payment value.
    pub fn build_route_transaction(
        &self,
        notes: Vec<SpendableNote>,
        merkle_paths: Vec<MerklePath>,
        anchor: Anchor,
        outputs: Vec<(PaymentAddress, u64, Option<[u8; 512]>)>,
        transparent_outputs: Vec<TransparentOutput>,
        fee: u64,
    ) -> SaplingResult<BuiltTransaction> {
        if notes.len() != merkle_paths.len() {
            return Err(SaplingError::InvalidInput(
                "Notes and merkle paths count mismatch".into(),
            ));
        }

        if notes.is_empty() {
            return Err(SaplingError::InvalidInput("No input notes provided".into()));
        }

        if outputs.is_empty() && transparent_outputs.is_empty() {
            return Err(SaplingError::InvalidInput("No outputs provided".into()));
        }

        // SECURITY: every spend's witness must recompute to the anchor being
        // signed. This runs before any proving work so a server-supplied
        // witness that is not anchored to the selected root can never enter
        // proof construction.
        for (idx, (note, path)) in notes.iter().zip(merkle_paths.iter()).enumerate() {
            let witness_root = Anchor::from(path.root(Node::from_cmu(&note.note.cmu())));
            if witness_root.to_bytes() != anchor.to_bytes() {
                return Err(SaplingError::InvalidInput(format!(
                    "witness_anchor_mismatch: spend {} witness root does not match the spend anchor",
                    idx
                )));
            }
        }

        if !prover::is_prover_initialized() {
            return Err(SaplingError::ProverNotInitialized);
        }

        let input_amounts: Vec<u64> = notes.iter().map(|n| n.value()).collect();
        let output_amounts: Vec<u64> = outputs.iter().map(|(_, amount, _)| *amount).collect();
        let transparent_amounts: Vec<u64> = transparent_outputs
            .iter()
            .map(|output| output.value)
            .collect();
        validate_route_transaction_amounts(
            &input_amounts,
            &output_amounts,
            &transparent_amounts,
            fee,
        )?;

        // Calculate totals (already validated above, but needed for change)
        let input_total: u64 = input_amounts.iter().sum();
        let output_total: u64 =
            output_amounts.iter().sum::<u64>() + transparent_amounts.iter().sum::<u64>();

        let change = input_total - output_total - fee;

        if change > 0 && change <= SHIELDED_DUST_THRESHOLD {
            return Err(SaplingError::InvalidInput(format!(
                "Change amount {} below dust threshold {}",
                change, SHIELDED_DUST_THRESHOLD
            )));
        }

        // PIVX is pre-ZIP-212, so Zip212Enforcement::Off.
        let bundle_type = BundleType::Transactional {
            bundle_required: true,
        };

        let mut builder = SaplingBuilder::new(
            Zip212Enforcement::Off,
            bundle_type,
            anchor,
        );

        let fvk = self.dfvk.fvk();

        for (note, path) in notes.iter().zip(merkle_paths.into_iter()) {
            builder
                .add_spend(fvk.clone(), note.note.clone(), path)
                .map_err(|_e| SaplingError::TransactionBuild)?;
        }

        // OVK lets the sender decrypt its own outputs later.
        let ovk = self.dfvk.to_ovk(Scope::External);

        for (address, amount, memo) in outputs {
            builder
                .add_output(
                    Some(ovk.clone()),
                    address,
                    NoteValue::from_raw(amount),
                    memo,
                )
                .map_err(|_| SaplingError::TransactionBuild)?;
        }

        if change > 0 {
            let change_address = self.change_address();
            builder
                .add_output(
                    Some(ovk.clone()),
                    change_address,
                    NoteValue::from_raw(change),
                    None,
                )
                .map_err(|_| SaplingError::TransactionBuild)?;
        }

        let mut rng = OsRng;
        let extsks = &[self.esk.clone()];

        let build_result = builder
            .build::<zcash_proofs::prover::LocalTxProver, zcash_proofs::prover::LocalTxProver, _, i64>(extsks, &mut rng)
            .map_err(|e| SaplingError::ProofError(format!("Bundle build failed: {:?}", e)))?;

        let (unproven_bundle, _sapling_meta) = match build_result {
            Some(b) => b,
            None => return Err(SaplingError::TransactionBuild),
        };

        let prover_guard = prover::get_prover()?;
        let local_prover = prover_guard
            .as_ref()
            .ok_or(SaplingError::ProverNotInitialized)?;

        let proven_bundle = unproven_bundle.create_proofs(
            local_prover,
            local_prover,
            &mut rng,
            (), // no progress notification
        );

        let ask = self.esk.expsk.ask.clone();
        let sighash = self.compute_sighash(&proven_bundle, &transparent_outputs);

        let authorized_bundle = proven_bundle
            .apply_signatures(&mut rng, sighash, &[ask])
            .map_err(|e| SaplingError::ProofError(format!("Signing failed: {:?}", e)))?;

        self.verify_authorized_bundle(&authorized_bundle, sighash, local_prover)?;

        let raw_tx =
            self.serialize_sapling_transaction(&authorized_bundle, &transparent_outputs)?;

        use sha2::{Digest, Sha256};
        let first_hash = Sha256::digest(&raw_tx);
        let txid_bytes = Sha256::digest(&first_hash);
        let mut txid = [0u8; 32];
        txid.copy_from_slice(&txid_bytes);
        txid.reverse(); // txid is displayed in reverse byte order

        Ok(BuiltTransaction { raw_tx, txid, fee })
    }

    /// Serialize a Sapling bundle into PIVX transaction format.
    ///
    /// PIVX transaction structure for Sapling:
    /// - Version: 4 bytes (version 3 with overwinter flag)
    /// - Version group ID: 4 bytes
    /// - Transparent inputs: varint count + inputs
    /// - Transparent outputs: varint count + outputs
    /// - Lock time: 4 bytes
    /// - Expiry height: 4 bytes
    /// - Value balance: 8 bytes (signed)
    /// - Sapling spends: varint count + serialized spends
    /// - Sapling outputs: varint count + serialized outputs
    /// - Binding signature: 64 bytes
    fn serialize_sapling_transaction(
        &self,
        bundle: &sapling::Bundle<sapling::bundle::Authorized, i64>,
        transparent_outputs: &[TransparentOutput],
    ) -> SaplingResult<Vec<u8>> {
        self.serialize_pivx_transaction(bundle, &[], &[], transparent_outputs)
    }

    fn serialize_pivx_transaction(
        &self,
        bundle: &sapling::Bundle<sapling::bundle::Authorized, i64>,
        transparent_inputs: &[TransparentInput],
        script_sigs: &[Vec<u8>],
        transparent_outputs: &[TransparentOutput],
    ) -> SaplingResult<Vec<u8>> {
        use std::io::Write;

        let mut tx = Vec::new();

        // PIVX Transaction Header (4 bytes total):
        // - nVersion (2 bytes, int16_t): 3 for Sapling
        // - nType (2 bytes, int16_t): 0 for Normal transaction
        //
        // PIVX does NOT use Zcash's transaction format:
        //   Zcash: version (4 bytes with overwinter bit) + version group ID (4 bytes) = 8 bytes
        //   PIVX:  nVersion (2 bytes) + nType (2 bytes) = 4 bytes
        //
        // Reference: PIVX Core src/primitives/transaction.h
        //   class CTransaction {
        //       const int16_t nVersion;  // 1=Legacy, 3=Sapling
        //       const int16_t nType;     // 0=Normal, 1+=Special (ProReg, etc.)
        //   };
        //
        // Verified against: PIVX Core commit 0cbf7b89 (December 2025)
        tx.write_all(&3i16.to_le_bytes())
            .map_err(|_| SaplingError::TransactionBuild)?; // nVersion = 3 (Sapling)
        tx.write_all(&0i16.to_le_bytes())
            .map_err(|_| SaplingError::TransactionBuild)?; // nType = 0 (Normal)

        // Transparent inputs (empty for shielded-only routes, the signed
        // UTXOs for t-to-z), serialized exactly as PIVX Core serializes vin.
        if transparent_inputs.len() != script_sigs.len() {
            return Err(SaplingError::TransactionBuild);
        }
        {
            let mut vin = Vec::new();
            write_compact_size(&mut vin, transparent_inputs.len() as u64);
            for (input, script_sig) in transparent_inputs.iter().zip(script_sigs) {
                input.serialize_prevout(&mut vin);
                write_compact_size(&mut vin, script_sig.len() as u64);
                vin.extend_from_slice(script_sig);
                vin.extend_from_slice(&TransparentInput::SEQUENCE_FINAL.to_le_bytes());
            }
            tx.write_all(&vin)
                .map_err(|_| SaplingError::TransactionBuild)?;
        }

        // Transparent outputs (empty for z-to-z, the deshield payments for
        // z-to-t, change for t-to-z), serialized exactly as PIVX Core
        // serializes vout
        serialize_transparent_outputs(&mut tx, transparent_outputs);

        // Lock time (4 bytes, 0 = immediate)
        tx.write_all(&0u32.to_le_bytes())
            .map_err(|_| SaplingError::TransactionBuild)?;

        // CRITICAL: PIVX does NOT serialize expiry height (Zcash-specific feature removed)
        // Reference: PIVX Core src/primitives/transaction.h SerializeTransaction()
        //   s << tx.nVersion;
        //   s << tx.nType;
        //   s << tx.vin;
        //   s << tx.vout;
        //   s << tx.nLockTime;
        //   if (tx.isSaplingVersion()) {
        //       s << tx.sapData;  // Goes DIRECTLY to Sapling data, no expiry height!
        //   }
        //
        // no expiry-height field in PIVX (unlike Zcash)

        // Sapling data optional marker.
        //
        // PIVX serializes Sapling payloads as Optional<SaplingTxData> after
        // nLockTime. Normal transactions do not serialize extraPayload, but the
        // sapData presence byte is required before valueBalance.
        tx.push(0x01);

        // Value balance (8 bytes, signed little endian)
        // This is the net value flow: sum(spend values) - sum(output values)
        // A positive value means value is flowing from shielded to transparent
        // For a pure shielded tx, this equals the fee
        let value_balance: i64 = *bundle.value_balance();
        tx.write_all(&value_balance.to_le_bytes())
            .map_err(|_| SaplingError::TransactionBuild)?;

        // Sapling spends
        let spends = bundle.shielded_spends();
        self.write_varint(&mut tx, spends.len() as u64);
        for spend in spends {
            // cv (32 bytes): value commitment
            tx.write_all(&spend.cv().to_bytes())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // anchor (32 bytes)
            tx.write_all(&spend.anchor().to_bytes())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // nullifier (32 bytes)
            tx.write_all(&spend.nullifier().0)
                .map_err(|_| SaplingError::TransactionBuild)?;
            // rk (32 bytes): randomized public key
            let rk_bytes: [u8; 32] = spend.rk().clone().into();
            tx.write_all(&rk_bytes)
                .map_err(|_| SaplingError::TransactionBuild)?;
            // zkproof (192 bytes for Groth16)
            tx.write_all(spend.zkproof())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // spend_auth_sig (64 bytes)
            tx.write_all(&<[u8; 64]>::from(*spend.spend_auth_sig()))
                .map_err(|_| SaplingError::TransactionBuild)?;
        }

        // Sapling outputs
        let outputs = bundle.shielded_outputs();
        self.write_varint(&mut tx, outputs.len() as u64);
        for output in outputs {
            // cv (32 bytes): value commitment
            tx.write_all(&output.cv().to_bytes())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // cmu (32 bytes): note commitment
            tx.write_all(&output.cmu().to_bytes())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // ephemeral_key (32 bytes)
            tx.write_all(output.ephemeral_key().as_ref())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // enc_ciphertext (580 bytes)
            tx.write_all(output.enc_ciphertext())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // out_ciphertext (80 bytes)
            tx.write_all(output.out_ciphertext())
                .map_err(|_| SaplingError::TransactionBuild)?;
            // zkproof (192 bytes)
            tx.write_all(output.zkproof())
                .map_err(|_| SaplingError::TransactionBuild)?;
        }

        // Binding signature (64 bytes)
        let binding_sig = bundle.authorization().binding_sig;
        tx.write_all(&<[u8; 64]>::from(binding_sig))
            .map_err(|_| SaplingError::TransactionBuild)?;

        Ok(tx)
    }

    fn verify_authorized_bundle(
        &self,
        bundle: &sapling::Bundle<sapling::bundle::Authorized, i64>,
        sighash: [u8; 32],
        prover: &zcash_proofs::prover::LocalTxProver,
    ) -> SaplingResult<()> {
        use bellman::groth16::Proof;
        use bls12_381::Bls12;
        use group::GroupEncoding;

        let (spend_vk, output_vk) = prover.verifying_keys();
        let spend_pvk = spend_vk.prepare();
        let output_pvk = output_vk.prepare();
        let mut ctx = SaplingVerificationContext::new();

        for (idx, spend) in bundle.shielded_spends().iter().enumerate() {
            if spend.rk().verify(&sighash, spend.spend_auth_sig()).is_err() {
                return Err(SaplingError::ProofError(format!(
                    "Local Sapling spend auth signature verification failed for spend {}",
                    idx
                )));
            }

            let proof = Proof::<Bls12>::read(&spend.zkproof()[..]).map_err(|e| {
                SaplingError::ProofError(format!(
                    "Local Sapling spend proof parse failed for spend {}: {}",
                    idx, e
                ))
            })?;

            if !ctx.check_spend(
                spend.cv(),
                *spend.anchor(),
                &spend.nullifier().0,
                *spend.rk(),
                &sighash,
                *spend.spend_auth_sig(),
                proof,
                &spend_pvk,
            ) {
                return Err(SaplingError::ProofError(format!(
                    "Local Sapling spend proof verification failed for spend {}",
                    idx
                )));
            }
        }

        for (idx, output) in bundle.shielded_outputs().iter().enumerate() {
            let proof = Proof::<Bls12>::read(&output.zkproof()[..]).map_err(|e| {
                SaplingError::ProofError(format!(
                    "Local Sapling output proof parse failed for output {}: {}",
                    idx, e
                ))
            })?;
            let epk_bytes: [u8; 32] =
                output
                    .ephemeral_key()
                    .as_ref()
                    .try_into()
                    .map_err(|_| {
                        SaplingError::ProofError(format!(
                            "Local Sapling output ephemeral key length invalid for output {}",
                            idx
                        ))
                    })?;
            let epk = jubjub::ExtendedPoint::from_bytes(&epk_bytes)
                .into_option()
                .ok_or_else(|| {
                    SaplingError::ProofError(format!(
                        "Local Sapling output ephemeral key parse failed for output {}",
                        idx
                    ))
                })?;

            if !ctx.check_output(output.cv(), *output.cmu(), epk, proof, &output_pvk) {
                return Err(SaplingError::ProofError(format!(
                    "Local Sapling output proof verification failed for output {}",
                    idx
                )));
            }
        }

        if !ctx.final_check(
            *bundle.value_balance(),
            &sighash,
            bundle.authorization().binding_sig,
        ) {
            return Err(SaplingError::ProofError(
                "Local Sapling binding signature verification failed".into(),
            ));
        }

        Ok(())
    }

    /// Write a variable-length integer (Bitcoin-style varint).
    fn write_varint(&self, buf: &mut Vec<u8>, n: u64) {
        if n < 0xfd {
            buf.push(n as u8);
        } else if n <= 0xffff {
            buf.push(0xfd);
            buf.extend_from_slice(&(n as u16).to_le_bytes());
        } else if n <= 0xffffffff {
            buf.push(0xfe);
            buf.extend_from_slice(&(n as u32).to_le_bytes());
        } else {
            buf.push(0xff);
            buf.extend_from_slice(&n.to_le_bytes());
        }
    }

    /// Compute sighash for Sapling transaction signing.
    ///
    /// PIVX uses BLAKE2b-256 with personalization: "PIVXSigHash" + branch ID (0).
    /// The sighash format is based on ZIP 243 but adapted for PIVX's transaction structure.
    ///
    /// Reference: PIVX Core src/script/interpreter.cpp SignatureHash()
    ///   ss << txTo.nVersion;  // int16_t (2 bytes)
    ///   ss << txTo.nType;     // int16_t (2 bytes)
    ///   ss << hashPrevouts;
    ///   ss << hashSequence;
    ///   ss << hashOutputs;
    ///   ss << hashShieldedSpends;
    ///   ss << hashShieldedOutputs;
    ///   ss << txTo.sapData->valueBalance;
    ///   // ... input being signed, locktime, hashtype
    fn compute_sighash(
        &self,
        bundle: &sapling::Bundle<
            sapling::builder::InProgress<sapling::builder::Proven, sapling::builder::Unsigned>,
            i64,
        >,
        transparent_outputs: &[TransparentOutput],
    ) -> [u8; 32] {
        let state = self.sighash_common_state(bundle, &[], transparent_outputs);
        Self::finalize_binding_sighash(&state)
    }

    /// Finalize the transaction-level (binding/spend-auth) sighash: the
    /// common legs followed by locktime and SIGHASH_ALL, with no input leg
    /// (PIVX Core's NOT_AN_INPUT case).
    fn finalize_binding_sighash(state: &blake2b_simd::State) -> [u8; 32] {
        use std::io::Write;
        let mut hasher = state.clone();
        hasher.write_all(&0u32.to_le_bytes()).unwrap(); // nLockTime
        hasher.write_all(&1u32.to_le_bytes()).unwrap(); // SIGHASH_ALL
        let result = hasher.finalize();
        let mut sighash = [0u8; 32];
        sighash.copy_from_slice(result.as_bytes());
        sighash
    }

    /// Finalize the per-input sighash for a transparent input: the common
    /// legs, then prevout + scriptCode + amount + nSequence, then locktime
    /// and SIGHASH_ALL. Reference: PIVX Core interpreter.cpp SignatureHash
    /// (the `nIn != NOT_AN_INPUT` branch).
    fn finalize_input_sighash(
        state: &blake2b_simd::State,
        input: &TransparentInput,
    ) -> [u8; 32] {
        use std::io::Write;
        let mut hasher = state.clone();
        let mut input_leg = Vec::with_capacity(36 + 1 + input.script_pubkey.len() + 12);
        input.serialize_prevout(&mut input_leg);
        // scriptCode for P2PKH is the UTXO's scriptPubKey, serialized like a
        // CScript (compact size + bytes).
        write_compact_size(&mut input_leg, input.script_pubkey.len() as u64);
        input_leg.extend_from_slice(&input.script_pubkey);
        input_leg.extend_from_slice(&input.value.to_le_bytes());
        input_leg.extend_from_slice(&TransparentInput::SEQUENCE_FINAL.to_le_bytes());
        hasher.write_all(&input_leg).unwrap();
        hasher.write_all(&0u32.to_le_bytes()).unwrap(); // nLockTime
        hasher.write_all(&1u32.to_le_bytes()).unwrap(); // SIGHASH_ALL
        let result = hasher.finalize();
        let mut sighash = [0u8; 32];
        sighash.copy_from_slice(result.as_bytes());
        sighash
    }

    /// Build the sighash legs shared by the binding signature and every
    /// transparent input signature: header, hashPrevouts, hashSequence,
    /// hashOutputs, shielded spend/output legs, and value balance.
    fn sighash_common_state(
        &self,
        bundle: &sapling::Bundle<
            sapling::builder::InProgress<sapling::builder::Proven, sapling::builder::Unsigned>,
            i64,
        >,
        transparent_inputs: &[TransparentInput],
        transparent_outputs: &[TransparentOutput],
    ) -> blake2b_simd::State {
        use blake2b_simd::Params;
        use std::io::Write;

        // PIVX Sapling personalization: "PIVXSigHash" + padding + branch_id (4 bytes)
        // Verified against PIVX Core: src/script/interpreter.cpp:1228-1234
        let personalization = pivx_sighash_personalization();

        let mut hasher = Params::new()
            .hash_length(32)
            .personal(&personalization)
            .to_state();

        // Hash transaction header data
        // PIVX format: nVersion (2 bytes) + nType (2 bytes)
        // Verified against PIVX Core: interpreter.cpp:1238-1240
        //   ss << txTo.nVersion;  // int16_t
        //   ss << txTo.nType;     // int16_t
        hasher.write_all(&3i16.to_le_bytes()).unwrap(); // nVersion = 3 (Sapling)
        hasher.write_all(&0i16.to_le_bytes()).unwrap(); // nType = 0 (Normal)

        // Hash transparent prevouts/sequence over the real vin (empty for
        // shielded-only transactions). For SIGHASH_ALL with no transparent
        // inputs, PIVX commits to the personalized BLAKE2b hash of the empty
        // vector, not 32 zero bytes.
        let mut prevouts_bytes = Vec::with_capacity(transparent_inputs.len() * 36);
        let mut sequence_bytes = Vec::with_capacity(transparent_inputs.len() * 4);
        for input in transparent_inputs {
            input.serialize_prevout(&mut prevouts_bytes);
            sequence_bytes
                .extend_from_slice(&TransparentInput::SEQUENCE_FINAL.to_le_bytes());
        }
        hasher
            .write_all(
                Params::new()
                    .hash_length(32)
                    .personal(b"PIVXPrevoutHash")
                    .hash(&prevouts_bytes)
                    .as_bytes(),
            )
            .unwrap();
        hasher
            .write_all(
                Params::new()
                    .hash_length(32)
                    .personal(b"PIVXSequencHash")
                    .hash(&sequence_bytes)
                    .as_bytes(),
            )
            .unwrap();
        // hashOutputs commits to the serialized transparent vout vector
        // (empty for z-to-z, the deshield payments for z-to-t).
        // Reference: PIVX Core interpreter.cpp GetOutputsHash().
        let mut vout_bytes = Vec::new();
        for output in transparent_outputs {
            output.serialize_into(&mut vout_bytes);
        }
        hasher
            .write_all(
                Params::new()
                    .hash_length(32)
                    .personal(b"PIVXOutputsHash")
                    .hash(&vout_bytes)
                    .as_bytes(),
            )
            .unwrap();

        // Hash shielded spends. PIVX Core only computes the personalized
        // hash when the spend vector is non-empty; an empty vector commits
        // to 32 zero bytes (default-constructed uint256), unlike the
        // transparent legs above. Reference: interpreter.cpp SignatureHash.
        if bundle.shielded_spends().is_empty() {
            hasher.write_all(&[0u8; 32]).unwrap();
        } else {
            let mut spend_hash = Params::new()
                .hash_length(32)
                .personal(b"PIVXSSpendsHash")
                .to_state();
            for spend in bundle.shielded_spends() {
                spend_hash.write_all(&spend.cv().to_bytes()).unwrap();
                spend_hash.write_all(&spend.anchor().to_bytes()).unwrap();
                spend_hash.write_all(&spend.nullifier().0).unwrap();
                let rk_bytes: [u8; 32] = spend.rk().clone().into();
                spend_hash.write_all(&rk_bytes).unwrap();
                spend_hash.write_all(spend.zkproof()).unwrap();
            }
            hasher.write_all(spend_hash.finalize().as_bytes()).unwrap();
        }

        // Hash shielded outputs, with the same empty-vector zero-bytes rule.
        if bundle.shielded_outputs().is_empty() {
            hasher.write_all(&[0u8; 32]).unwrap();
        } else {
            let mut output_hash = Params::new()
                .hash_length(32)
                .personal(b"PIVXSOutputHash")
                .to_state();
            for output in bundle.shielded_outputs() {
                output_hash.write_all(&output.cv().to_bytes()).unwrap();
                output_hash.write_all(&output.cmu().to_bytes()).unwrap();
                output_hash
                    .write_all(output.ephemeral_key().as_ref())
                    .unwrap();
                output_hash.write_all(output.enc_ciphertext()).unwrap();
                output_hash.write_all(output.out_ciphertext()).unwrap();
                output_hash.write_all(output.zkproof()).unwrap();
            }
            hasher.write_all(output_hash.finalize().as_bytes()).unwrap();
        }

        // Value balance
        let value_balance: i64 = *bundle.value_balance();
        hasher.write_all(&value_balance.to_le_bytes()).unwrap();

        hasher
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pivx_params() {
        let params = PivxMainnet;
        assert_eq!(params.network_type(), NetworkType::Main);

        let activation = params.activation_height(NetworkUpgrade::Sapling);
        assert!(activation.is_some());
        assert_eq!(
            activation.unwrap(),
            BlockHeight::from_u32(PIVX_SAPLING_ACTIVATION)
        );
    }

    #[test]
    fn test_pivx_testnet_params() {
        let params = PivxTestnet;
        assert_eq!(params.network_type(), NetworkType::Test);
    }

    #[test]
    fn test_sighash_personalization() {
        // Verify we use PIVX-specific personalization, not Zcash's
        // Reference: PIVX Core src/script/interpreter.cpp:1228-1234
        let mut personalization = [0u8; 16];
        // "PIVXSigHash" is 11 bytes, padded with null to 12 bytes
        let pivx_str = b"PIVXSigHash";
        personalization[..pivx_str.len()].copy_from_slice(pivx_str);
        personalization[12..16].copy_from_slice(&0u32.to_le_bytes());

        assert_eq!(
            &personalization[..11],
            b"PIVXSigHash",
            "Sighash personalization must start with 'PIVXSigHash' for PIVX consensus"
        );

        assert_eq!(personalization[11], 0, "12th byte should be null padding");

        // Branch ID is 0 (not Zcash's 0x03C48270).
        let branch_id = u32::from_le_bytes([
            personalization[12],
            personalization[13],
            personalization[14],
            personalization[15],
        ]);
        assert_eq!(branch_id, 0, "Branch ID must be 0 for PIVX consensus");
    }

    #[test]
    fn test_transaction_version() {
        // PIVX uses a different transaction header format than Zcash
        // PIVX: nVersion (2 bytes, int16_t) + nType (2 bytes, int16_t)
        // Zcash: version with overwinter bit (4 bytes) + version group ID (4 bytes)
        //
        // Reference: PIVX Core src/primitives/transaction.h
        //   class CTransaction {
        //       const int16_t nVersion;  // 1=Legacy, 3=Sapling
        //       const int16_t nType;     // 0=Normal, 1+=Special
        //   };

        let n_version: i16 = 3; // Sapling
        let n_type: i16 = 0; // Normal transaction

        assert_eq!(n_version, 3, "Sapling transactions must use nVersion = 3");
        assert_eq!(n_type, 0, "Normal transactions must use nType = 0");

        let mut header = Vec::new();
        header.extend_from_slice(&n_version.to_le_bytes()); // 2 bytes
        header.extend_from_slice(&n_type.to_le_bytes()); // 2 bytes
        assert_eq!(
            header.len(),
            4,
            "Transaction header must be exactly 4 bytes"
        );

        assert_eq!(
            header,
            vec![0x03, 0x00, 0x00, 0x00],
            "Header must be [0x03, 0x00, 0x00, 0x00] for Sapling Normal transaction"
        );
    }

    #[test]
    fn test_activation_heights() {
        // Reference: PIVX Core src/chainparams.cpp:285
        let mainnet = PivxMainnet;
        let mainnet_activation = mainnet.activation_height(NetworkUpgrade::Sapling);
        assert_eq!(
            mainnet_activation,
            Some(BlockHeight::from_u32(2_700_500)),
            "Mainnet Sapling activation must be block 2,700,500"
        );

        // Reference: PIVX Core src/chainparams.cpp:445
        let testnet = PivxTestnet;
        let testnet_activation = testnet.activation_height(NetworkUpgrade::Sapling);
        assert_eq!(
            testnet_activation,
            Some(BlockHeight::from_u32(201)),
            "Testnet Sapling activation must be block 201"
        );
    }

    #[test]
    fn test_shielded_dust_threshold() {
        assert_eq!(SHIELDED_DUST_THRESHOLD, 1_446_000);
        assert!(validate_transaction_amounts(&[3_000_000], &[1_445_999], 1_554_001).is_err());
        assert!(validate_transaction_amounts(&[3_000_000], &[1_446_000], 1_554_000).is_ok());
    }

    fn base58check_encode(payload: &[u8]) -> String {
        use sha2::{Digest, Sha256};
        let digest = Sha256::digest(Sha256::digest(payload));
        let mut data = payload.to_vec();
        data.extend_from_slice(&digest[..4]);

        let mut digits: Vec<u8> = Vec::new();
        for &byte in &data {
            let mut carry = byte as u32;
            for digit in digits.iter_mut() {
                carry += (*digit as u32) << 8;
                *digit = (carry % 58) as u8;
                carry /= 58;
            }
            while carry > 0 {
                digits.push((carry % 58) as u8);
                carry /= 58;
            }
        }
        for &byte in &data {
            if byte == 0 {
                digits.push(0);
            } else {
                break;
            }
        }
        digits
            .iter()
            .rev()
            .map(|&d| BASE58_ALPHABET[d as usize] as char)
            .collect()
    }

    #[test]
    fn test_transparent_address_script_p2pkh() {
        let hash: [u8; 20] = [0x11; 20];
        let mut payload = vec![PIVX_MAINNET_PUBKEY_PREFIX];
        payload.extend_from_slice(&hash);
        let address = base58check_encode(&payload);
        assert!(address.starts_with('D'));

        let script = script_pubkey_for_transparent_address(&address, false).unwrap();
        assert_eq!(script.len(), 25);
        assert_eq!(&script[..3], &[0x76, 0xa9, 0x14]);
        assert_eq!(&script[3..23], &hash);
        assert_eq!(&script[23..], &[0x88, 0xac]);

        // Wrong network must be rejected.
        assert!(script_pubkey_for_transparent_address(&address, true).is_err());
    }

    #[test]
    fn test_transparent_address_script_p2sh_and_testnet() {
        let hash: [u8; 20] = [0x22; 20];
        let mut payload = vec![PIVX_MAINNET_SCRIPT_PREFIX];
        payload.extend_from_slice(&hash);
        let address = base58check_encode(&payload);
        let script = script_pubkey_for_transparent_address(&address, false).unwrap();
        assert_eq!(script.len(), 23);
        assert_eq!(&script[..2], &[0xa9, 0x14]);
        assert_eq!(&script[2..22], &hash);
        assert_eq!(script[22], 0x87);

        let mut testnet_payload = vec![PIVX_TESTNET_PUBKEY_PREFIX];
        testnet_payload.extend_from_slice(&hash);
        let testnet_address = base58check_encode(&testnet_payload);
        assert!(script_pubkey_for_transparent_address(&testnet_address, true).is_ok());
        assert!(script_pubkey_for_transparent_address(&testnet_address, false).is_err());
    }

    #[test]
    fn test_transparent_address_rejects_corruption() {
        let hash: [u8; 20] = [0x33; 20];
        let mut payload = vec![PIVX_MAINNET_PUBKEY_PREFIX];
        payload.extend_from_slice(&hash);
        let address = base58check_encode(&payload);

        // Flip one character: checksum must fail.
        let mut corrupted: Vec<char> = address.chars().collect();
        let last = corrupted.len() - 1;
        corrupted[last] = if corrupted[last] == '2' { '3' } else { '2' };
        let corrupted: String = corrupted.into_iter().collect();
        assert!(script_pubkey_for_transparent_address(&corrupted, false).is_err());

        // Sapling bech32 addresses are not valid transparent addresses.
        assert!(script_pubkey_for_transparent_address(
            "ps1invalidnotbase58_0OIl",
            false
        )
        .is_err());
    }

    #[test]
    fn test_transparent_output_serialization() {
        let output = TransparentOutput {
            value: 123_456_789,
            script_pubkey: vec![0x76, 0xa9, 0x14, 0xaa, 0x88, 0xac],
        };
        let mut buf = Vec::new();
        serialize_transparent_outputs(&mut buf, &[output]);
        assert_eq!(buf[0], 1); // vout count
        assert_eq!(&buf[1..9], &123_456_789u64.to_le_bytes());
        assert_eq!(buf[9], 6); // script length
        assert_eq!(&buf[10..], &[0x76, 0xa9, 0x14, 0xaa, 0x88, 0xac]);

        let mut empty = Vec::new();
        serialize_transparent_outputs(&mut empty, &[]);
        assert_eq!(empty, vec![0x00]);
    }

    #[test]
    fn test_route_amount_validation_transparent_dust() {
        assert_eq!(TRANSPARENT_DUST_THRESHOLD, 5_460);
        // Transparent output below transparent dust is rejected.
        assert!(
            validate_route_transaction_amounts(&[3_000_000], &[], &[5_459], 10_000).is_err()
        );
        // Transparent output at the threshold is accepted (z-to-t).
        assert!(
            validate_route_transaction_amounts(&[3_000_000], &[], &[5_460], 10_000).is_ok()
        );
        // Shielded outputs still use the shielded dust threshold.
        assert!(validate_route_transaction_amounts(&[3_000_000], &[1_445_999], &[], 10_000)
            .is_err());
        // Inputs must cover shielded + transparent outputs + fee.
        assert!(validate_route_transaction_amounts(
            &[1_000_000],
            &[],
            &[995_000],
            10_000
        )
        .is_err());
        // No outputs at all is invalid.
        assert!(validate_route_transaction_amounts(&[3_000_000], &[], &[], 10_000).is_err());
    }

    #[test]
    fn test_amount_validation_allows_builder_change() {
        assert!(validate_transaction_amounts(&[20_000_000], &[12_000_000], 365_000).is_ok());
        assert!(validate_transaction_amounts(&[12_364_999], &[12_000_000], 365_000).is_err());
    }

    #[test]
    fn large_deshield_is_not_rejected_as_fee_too_large() {
        // z->t: the transparent output total is folded into the fee arg passed to
        // validate_transaction_amounts. A deshield above 10 PIV used to trip a
        // fabricated `fee > 1_000_000_000` cap even though the real fee is tiny.
        // PIVX Core has no absolute fee cap; this must be accepted.
        let amount: u64 = 2_000_000_000; // 20 PIV transparent output
        let fee: u64 = 1_417_000;
        assert!(
            validate_route_transaction_amounts(&[amount + fee], &[], &[amount], fee).is_ok()
        );
    }

    fn route_transaction_fixture() -> (
        TransactionBuilder,
        Vec<crate::notes::SpendableNote>,
        Vec<MerklePath>,
        Vec<(PaymentAddress, u64, Option<[u8; 512]>)>,
    ) {
        use sapling::{value::NoteValue, Note, Nullifier, Rseed};

        let manager =
            crate::keys::SaplingKeyManager::from_seed(&[7u8; 64], crate::types::Network::Mainnet)
                .unwrap();
        let address = manager.default_address().unwrap();

        let mut rseed_bytes = [0u8; 32];
        rseed_bytes[0] = 1;
        let rseed = Rseed::BeforeZip212(jubjub::Fr::from_bytes(&rseed_bytes).unwrap());
        let note = Note::from_parts(address.clone(), NoteValue::from_raw(20_000_000), rseed);
        let spendable = crate::notes::SpendableNote::new(
            note,
            address.clone(),
            0,
            Nullifier([0u8; 32]),
            0,
            0,
            0,
        );

        // 32 canonical sibling nodes (value 1, little-endian).
        let mut sibling = [0u8; 32];
        sibling[0] = 1;
        let witness_hex = hex::encode(sibling).repeat(32);
        let path = crate::notes::parse_merkle_path(&witness_hex, 0).unwrap();

        let builder = TransactionBuilder::new(
            manager.extended_spending_key().clone(),
            manager.diversifiable_full_viewing_key().clone(),
            false,
        );
        let outputs = vec![(address, 12_000_000u64, None)];

        (builder, vec![spendable], vec![path], outputs)
    }

    #[test]
    fn test_build_route_transaction_rejects_witness_anchor_mismatch() {
        let (builder, notes, paths, outputs) = route_transaction_fixture();

        // The empty-tree anchor cannot match a witness with nonzero siblings.
        let err = builder
            .build_route_transaction(
                notes,
                paths,
                Anchor::empty_tree(),
                outputs,
                Vec::new(),
                365_000,
            )
            .unwrap_err();
        assert!(
            err.to_string().contains("witness_anchor_mismatch"),
            "expected witness_anchor_mismatch, got: {}",
            err
        );
    }

    #[test]
    fn test_build_route_transaction_witness_check_runs_before_proving() {
        let (builder, notes, paths, outputs) = route_transaction_fixture();

        // With the matching anchor the witness gate passes and the build
        // stops at the prover check instead, proving the root comparison
        // happens before any proving work.
        let leaf = Node::from_cmu(&notes[0].note.cmu());
        let anchor = Anchor::from(paths[0].root(leaf));
        let err = builder
            .build_route_transaction(notes, paths, anchor, outputs, Vec::new(), 365_000)
            .unwrap_err();
        assert!(
            matches!(err, SaplingError::ProverNotInitialized),
            "expected ProverNotInitialized, got: {}",
            err
        );
    }

    #[test]
    fn test_pivx_sighash_personalization_is_padded() {
        let personalization = pivx_sighash_personalization();
        assert_eq!(&personalization[..11], b"PIVXSigHash");
        assert_eq!(personalization[11], 0);
        assert_eq!(&personalization[12..16], &0u32.to_le_bytes());
    }
}
