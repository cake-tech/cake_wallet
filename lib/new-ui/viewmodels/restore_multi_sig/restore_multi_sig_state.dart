part of "restore_multi_sig_bloc.dart";

sealed class RestoreMultiSigState {}

class RestoreMultiSigInitial extends RestoreMultiSigState {}

class RestoreMultiSigConnectSigners extends RestoreMultiSigState {
  RestoreMultiSigConnectSigners(this.walletName, this.threshold, this.signers, this.connectedSigners);

  final String walletName;
  final int threshold;
  final int signers;
  final List<MultisigSigner> connectedSigners;
}
