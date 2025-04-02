import 'package:reown_walletkit/reown_walletkit.dart';

class SessionRequestModel {
  final ProposalData request;

  SessionRequestModel({
    required this.request,
  });

  @override
  String toString() {
    return 'SessionRequestModel(request: $request)';
  }
}
