class CakePayUnauthorizedException implements Exception {
  const CakePayUnauthorizedException();

  @override
  String toString() => 'Cake Pay session is no longer valid, please log in again.';
}
