const _ipfsGateway = "https://ipfs.io/ipfs/";
const _ipfsScheme = "ipfs://";

String? tryNormalizeIpfsUrl(String? url) {
  if (url == null) {
    return null;
  }

  if (!url.toLowerCase().startsWith(_ipfsScheme)) {
    return url.toLowerCase().startsWith("https://") ? url : null;
  }

  var cid = url.substring(_ipfsScheme.length);

  // Some minters write ipfs://ipfs/<cid>, which would double the gateway path.
  if (cid.toLowerCase().startsWith("ipfs/")) {
    cid = cid.substring(5);
  }

  if (cid.isEmpty) {
    return null;
  }

  return "$_ipfsGateway$cid";
}
