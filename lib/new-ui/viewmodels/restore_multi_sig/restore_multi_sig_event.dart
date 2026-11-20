part of "restore_multi_sig_bloc.dart";

sealed class RestoreMultiSigEvent {}

final class SetOptions extends RestoreMultiSigEvent {
  SetOptions(this.walletName, this.threshold, this.signers);

  final String walletName;
  final int threshold;
  final int signers;
}

final class ConnectSigner extends RestoreMultiSigEvent {
  ConnectSigner(this.signer);

  final MultisigSigner signer;
}
