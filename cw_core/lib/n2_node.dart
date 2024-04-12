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

  factory N2Node.fromJson(Map<String, dynamic> json) => N2Node(
        weight: double.tryParse((json['weight'] as num?).toString()),
        uptime: json['uptime'] as String?,
        score: json['score'] as int?,
        account: json['rep_address'] as String?,
        alias: json['alias'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uptime': uptime,
        'weight': weight,
        'score': score,
        'rep_address': account,
        'alias': alias,
      };
}
