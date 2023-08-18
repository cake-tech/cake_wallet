import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

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
