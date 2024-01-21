import 'package:cw_solana/spl_token.dart';

class DefaultSPLTokens {
  final List<SPLToken> initialSPLTokens = [
    SPLToken(
      name: 'Solana',
      symbol: 'SOL',
      mintAddress: 'So11111111111111111111111111111111111111112',
      decimal: 9,
      mint: 'sol',
      logoUrl: "https://solana.com/src/img/branding/solanaLogoMark.png",
    ),
  ];
}
