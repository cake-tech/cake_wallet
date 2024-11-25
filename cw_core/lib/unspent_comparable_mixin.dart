mixin UnspentComparable {
  String get address;

  String get hash;

  int get value;

  int get vout;

  String? get keyImage;


  bool isFrozen = false;

  bool isSending = true;

  String note = '';

  void updateAdjustableFieldsFrom(UnspentComparable other) {
    isFrozen = other.isFrozen;
    isSending = other.isSending;
    note = other.note;
  }

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
