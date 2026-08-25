//! PIVX Sapling blockchain synchronization.
//!
//! Manages sync state including the commitment tree and note witnesses.

use sapling::Nullifier;

use crate::error::SaplingError;
use crate::notes::SpendableNote;

pub type SaplingResult<T> = Result<T, SaplingError>;

pub const SAPLING_TREE_DEPTH: u8 = 32;

pub struct SyncState {
    sync_height: u32,
    nullifier_set: Vec<Nullifier>,
    notes: Vec<SpendableNote>,
    commitment_count: u64,
}

impl SyncState {
    pub fn new() -> Self {
        Self {
            sync_height: 0,
            nullifier_set: Vec::new(),
            notes: Vec::new(),
            commitment_count: 0,
        }
    }

    pub fn from_height(height: u32) -> Self {
        let mut state = Self::new();
        state.sync_height = height;
        state
    }

    pub fn sync_height(&self) -> u32 {
        self.sync_height
    }

    pub fn tree_position(&self) -> u64 {
        self.commitment_count
    }

    pub fn increment_commitment_count(&mut self) {
        self.commitment_count += 1;
    }

    pub fn add_note(&mut self, note: SpendableNote) -> SaplingResult<()> {
        // dedupe by tree position (globally unique per output). a resume can
        // restore a note then re-scan its block and decrypt it again; without
        // this the native list gets duplicate rows and a multi-input send can
        // pick the same nullifier twice.
        if self.notes.iter().any(|n| n.position == note.position) {
            return Ok(());
        }
        self.notes.push(note);
        Ok(())
    }

    pub fn is_nullifier_spent(&self, nullifier: &Nullifier) -> bool {
        self.nullifier_set.iter().any(|n| n == nullifier)
    }

    pub fn add_spent_nullifier(&mut self, nullifier: Nullifier) {
        if !self.is_nullifier_spent(&nullifier) {
            self.nullifier_set.push(nullifier);

            for note in &mut self.notes {
                if note.nullifier == nullifier {
                    note.is_spent = true;
                }
            }
        }
    }

    pub fn unspent_notes(&self) -> Vec<&SpendableNote> {
        self.notes.iter().filter(|n| !n.is_spent).collect()
    }

    pub fn shielded_balance(&self) -> u64 {
        self.notes
            .iter()
            .filter(|n| !n.is_spent)
            .map(|n| n.value())
            .sum()
    }

    pub fn set_sync_height(&mut self, height: u32) {
        self.sync_height = height;
    }
}

impl Default for SyncState {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Clone, Debug)]
pub struct SyncProgress {
    pub current_block: u32,
    pub target_block: u32,
    pub notes_found: usize,
    pub eta_seconds: Option<u32>,
}

impl SyncProgress {
    pub fn progress_percent(&self) -> f64 {
        if self.target_block == 0 {
            return 100.0;
        }
        (self.current_block as f64 / self.target_block as f64) * 100.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sync_state_new() {
        let state = SyncState::new();
        assert_eq!(state.sync_height(), 0);
        assert_eq!(state.shielded_balance(), 0);
    }

    #[test]
    fn test_sync_progress() {
        let progress = SyncProgress {
            current_block: 50,
            target_block: 100,
            notes_found: 5,
            eta_seconds: Some(60),
        };

        assert!((progress.progress_percent() - 50.0).abs() < 0.01);
    }
}
