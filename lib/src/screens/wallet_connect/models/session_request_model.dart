import 'package:wallet_connect_v2/wallet_connect_v2.dart';

class SessionRequestModel {
  final SessionProposal? request;
  final SessionRequest? sessionRequest;

  SessionRequestModel({
    this.request,
    this.sessionRequest,
  });

  @override
  String toString() {
    return 'SessionRequestModel(request: $request, sessionRequest: $sessionRequest)';
  }
}
