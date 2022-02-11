class YatRecord {
  String category;
  String address;

  YatRecord({
    this.category,
    this.address,
  });

  YatRecord.fromJson(Map<String, dynamic> json) {
    address = json['address'] as String;
    category = json['category'] as String;
  }

  
}
