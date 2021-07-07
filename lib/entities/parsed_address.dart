enum ParseFrom {unstoppableDomains, openAlias, notParsed}

class ParsedAddress {
  ParsedAddress(this.address, this.parseFrom);

  final String address;
  final ParseFrom parseFrom;
}