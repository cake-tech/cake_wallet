class YatRecord {
  YatRecord({
    required this.category,
    required this.address,
  });

  YatRecord.fromJson(Map<String, dynamic> json)
    : address = json['address'] as String,
      category = json['category'] as String;

  String category;
  String address; 
}
