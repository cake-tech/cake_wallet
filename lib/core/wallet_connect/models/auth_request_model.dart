import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class AuthRequestModel {
  final String iss;
  final AuthRequest request;

  AuthRequestModel({
    required this.iss,
    required this.request,
  });

  @override
  String toString() {
    return 'AuthRequestModel(iss: $iss, request: $request)';
  }
}
