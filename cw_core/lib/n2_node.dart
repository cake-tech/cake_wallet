double? _toDouble(num v) {
  return double.tryParse(v.toString());
}

class N2Node {
  N2Node({
    this.weight,
    this.uptime,
    this.score,
    this.account,
    this.alias,
  });

  String? uptime;
  double? weight;
  int? score;
  String? account;
  String? alias;


  Nfactory N2Node.fromJson(Map<String, dynamic> json) => N2Node(
    weight: _toDouble(json['weight'] as num),
    uptime: json['uptime'] as String?,
    score: json['score'] as int?,
    account: json['rep_address'] as String?,
    alias: json['alias'] as String?,
  );
  
  Map<String, dynamic> toJson() => <String, dynamic>{
    'uptime': instance.uptime,
    'weight': instance.weight,
    'score': instance.score,
    'rep_address': instance.account,
    'alias': instance.alias,
  };
}
