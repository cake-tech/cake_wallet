/// Where a hardware-wallet signing session is, for the screen that is
/// telling the user what to do.
///
/// A device shows nothing until the whole transaction has reached it, and the
/// phone has work of its own before that (planning the transaction, talking
/// to the server), so "proceed on your device" is only true at
/// [awaitingDevice]. The stages before it are the wait the user sees.
enum HardwareSigningStage {
  /// The transaction is being planned on the phone.
  preparing,

  /// The transaction is being streamed to the device.
  sendingToDevice,

  /// The device is showing its review; the user must act on it.
  awaitingDevice,

  /// The user approved; the device is producing signatures.
  signing,

  /// The phone is completing the transaction (proofs, binding signature).
  finalizing,
}
