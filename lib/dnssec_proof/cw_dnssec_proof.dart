part of "dnssec_proof.dart";

class CWDnssecProof extends DnssecProof {
  CWDnssecProof();

  Future<String?> fetchDnsProof(String bip353Name) async {
    if (bip353Name.startsWith('₿')) {
      bip353Name = bip353Name.substring(1);
    }
    final parts = bip353Name.split('@');
    if (parts.length != 2) return null;
    final userPart = parts[0];
    final domainPart = parts[1];
    final bip353Domain = '$userPart.user._bitcoin-payment.$domainPart.';
    final proof = await Isolate.run(() => DnsProver.getTxtProof(bip353Domain));
    return base64.encode(proof);
  }
}
