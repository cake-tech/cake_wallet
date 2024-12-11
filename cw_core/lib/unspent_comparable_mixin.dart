mixin UnspentComparable {
  String get address;

  String get hash;

  int get value;

  int get vout;

  String? get keyImage;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnspentComparable &&
        other.hash == hash &&
        other.address == address &&
        other.value == value &&
        other.vout == vout &&
        other.keyImage == keyImage;
  }

  @override
  int get hashCode {
    return Object.hash(address, hash, value, vout, keyImage);
  }
}
