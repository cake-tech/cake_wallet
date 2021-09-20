enum ParseFrom {unstoppableDomains, openAlias, yatRecord, notParsed}

class ParsedAddress {
  ParsedAddress({
    this.addresses,
    this.name = '',
    this.parseFrom = ParseFrom.notParsed});

  final List<String> addresses;
  final String name;
  final ParseFrom parseFrom;
}