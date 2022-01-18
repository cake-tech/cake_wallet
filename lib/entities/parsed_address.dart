enum ParseFrom { unstoppableDomains, openAlias, yatRecord, notParsed }

class ParsedAddress {
  ParsedAddress({
    this.addresses,
    this.name = '',
    this.description = '',
    this.parseFrom = ParseFrom.notParsed,
  });

  final List<String> addresses;
  final String name;
  final String description;
  final ParseFrom parseFrom;
}
