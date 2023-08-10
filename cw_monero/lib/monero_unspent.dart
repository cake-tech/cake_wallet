class MoneroUnspent {
  MoneroUnspent(this.address, this.hash, this.value, this.vout);

  final String address;
  final String hash;
  final int value;
  final int vout;
}
