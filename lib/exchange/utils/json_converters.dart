
import "package:cake_wallet/exchange/trade_state.dart";
import "package:json_annotation/json_annotation.dart";

class MillisDateTimeConverter implements JsonConverter<DateTime, int> {
  const MillisDateTimeConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);

  @override
  int toJson(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
}


class TradeStateConverter implements JsonConverter<TradeState, String> {
  const TradeStateConverter();

  @override
  TradeState fromJson(String json) => TradeState.deserialize(raw: json);

  @override
  String toJson(TradeState state) => state.serialize();
}


class SecondsDateTimeConverter implements JsonConverter<DateTime, int> {
  const SecondsDateTimeConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json * 1000);

  @override
  int toJson(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
}



class StringBoolConverter implements JsonConverter<bool, String> {
  const StringBoolConverter();

  @override
  bool fromJson(String json) => json.toLowerCase() == "true";

  @override
  String toJson(bool value) => value.toString();
}
