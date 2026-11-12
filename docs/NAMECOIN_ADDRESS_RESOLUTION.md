# Namecoin address resolution

Cake Wallet can resolve a Namecoin identifier into addresses for any currency in
`CryptoCurrency.all`. This is a Cake Wallet payment-value convention; it is not an
OpenAlias record and is not presented as an established Namecoin payment standard.

## Identifiers and values

Accepted identifiers are `d/name`, `id/name`, and `name.bit`. Identifiers are
case-normalized, and `.bit` is converted to the corresponding `d/` name.

The name value must be a JSON object keyed by Cake Wallet's unique, case-insensitive
`CryptoCurrency.name`, **not** its display title or network tag. For example:

```json
{
  "btc": "bc1...",
  "xmr": "4...",
  "usdterc20": "0x..."
}
```

A currency can alternatively map to an object containing an `address` string:

```json
{
  "btc": {"address": "bc1..."},
  "usdterc20": {"address": "0x..."}
}
```

Unknown keys, empty or non-string addresses, malformed JSON, and non-object JSON values
produce no usable entry. Resolution does not narrow currencies to OpenAlias's subset or
to `AddressValidator.reliableValidateCurrencies`. Normal wallet and form address
validation still applies after a currency is selected.

## Currency selection

- Contact creation can resolve an identifier before choosing a currency. The confirmation
  shows the currencies present in the value, and the picker contains only those currencies.
  A single-currency value is selected automatically; a multi-currency value requires an
  explicit choice.
- If a currency was already selected, it is used only when present in the value.
- Sending resolves only for the active wallet currency. An absent or empty entry returns no
  resolved address; Cake Wallet must not substitute an address from another chain.
- Changing the send currency invalidates the extracted recipient. Transaction creation checks
  that the extracted address still belongs to the active currency, and unresolved Namecoin
  identifiers are not treated as raw recipient addresses.
- Address edits and currency changes invalidate in-flight lookups. Results are checked again
  before showing and applying the confirmation so an older lookup cannot replace newer input.

## ElectrumX compatibility and failure behavior

The resolver uses Cake Wallet's `ProxyWrapper` / `ProxySocket`, including its existing Tor
routing and socket policy. It does not create an independent HTTP, proxy, or TLS stack.

For each server it:

1. Queries `blockchain.scripthash.get_history` for the Namecoin name-index script.
2. Selects the latest confirmed history entry; unconfirmed-only values are not returned.
3. Fetches `blockchain.transaction.get` with verbose output and decodes the matching
   `NAME_FIRSTUPDATE` or `NAME_UPDATE` output.
4. Reads the tip with `blockchain.headers.subscribe` and rejects values at or beyond the
   36,000-block Namecoin expiry depth.

A resolution requires at least two successful servers and one unique leading consensus
group agreeing on the transaction ID, height, and complete value. Ties, a single response,
unavailable servers, malformed responses, and expired values fail closed. This is transport
and multi-server consistency checking, not a cryptographic SPV proof or a guarantee that
multiple endpoints have independent operators.

The defaults are the three endpoints used for live compatibility checks:

- `electrumx.testls.space:50002`
- `nmc2.bitcoins.sk:57002`
- `electrumx2.testls.space:50012`

The servers learn which Namecoin identifier is being resolved. Users can disable Namecoin
lookup in the address-lookup settings. DNS TXT lookup and `blockchain.name.get_value_proof`
are not used by this implementation.
