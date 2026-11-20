part of "restore_multi_sig_bloc.dart";

sealed class RestoreMultiSigEvent {}

final class SetOptions extends RestoreMultiSigEvent {
  final String walletName;
  final int threshold;
  final int signers;

  SetOptions(this.walletName, this.threshold, this.signers);
}
