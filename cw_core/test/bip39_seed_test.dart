import "package:cw_core/utils/bip39_seed.dart";
import "package:flutter_test/flutter_test.dart";

// Expected seeds come from the anicdh/bip39 fork (3633daa) the app used before this helper.
// Non-ASCII is written as escapes so NFC/NFD and invisible characters survive editors.
final _vectors = <(String, String, String, String)>[
  (
    "BIP39 reference vector 1 (abandon...about, TREZOR)",
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
    "TREZOR",
    "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04",
  ),
  (
    "BIP39 reference vector 2 (legal winner, TREZOR)",
    "legal winner thank year wave sausage worth useful legal winner thank yellow",
    "TREZOR",
    "2e8905819b8723fe2c1d161860e5ee1830318dbf49a83bd451cfb8440c28bd6fa457fe1296106559a3c80937a1c1069be3a3a5bd381ee6260e8d9739fce1f607",
  ),
  (
    "BIP39 reference vector 24 words (zoo...vote, TREZOR)",
    "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
    "TREZOR",
    "dd48c104698c30cfe2b6142103248622fb7bb0ff692eebb00089b32d22484e1613912f0a5b694407be899ffd31ed3992c456cdf60f5d4564b8ba3f05a69890ad",
  ),
  (
    "12 words, no passphrase",
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
    "",
    "5eb00bbddcf069084889a8ab9155568165f5c453ccb85e70811aaed6f6da5fc19a5ac40b389cd370d086206dec8aa6c43daea6690f20ad3d8d48b2d2ce9e38e4",
  ),
  (
    "12 words",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "",
    "4da7517731e772905678260a8643e9f9e166ade16ed3cc44e8d68edbacffc18ba0e5e42750cf02fb525b99f41d7c67559ccd937fe13b8bf279e412ffb4fcf3fd",
  ),
  (
    "24 words",
    "dance puzzle basic eternal ride alcohol best announce hint time level salute deer minimum glass kind corn athlete unusual mushroom because tomorrow game quiz",
    "",
    "084fb98f94346353c502d4938c3a903e0f7057564becdcc2f97ce101f07253eca9523f941eb8fc5c66f61c15b448e7d0f897ad467dfce8c9b97ea9c68dfb273a",
  ),
  (
    "24 words, ascii passphrase",
    "dance puzzle basic eternal ride alcohol best announce hint time level salute deer minimum glass kind corn athlete unusual mushroom because tomorrow game quiz",
    "correct horse battery staple",
    "fb56021fb17dacae79c7d4240bce48a7387114e54355957636ad09edfaafa79317c521a091c5c6c41e48f15f236db6f3ee815ffa433a195d7b985def82b6198d",
  ),
  (
    "electrum seed through the bip39 function (derivation discovery)",
    "will hedgehog multiply duck blood marble little asset eagle online clock soap",
    "",
    "e2a33f8be2ebb262a542a4623c4b96624ff98e3482a15b51f1186a093d26d1106f632e8a668a4cc8a7a4c9aae914e78f1316bb8bd06676892b5b22ac7687672b",
  ),
  (
    "electrum seed, passphrase",
    "will hedgehog multiply duck blood marble little asset eagle online clock soap",
    "TREZOR",
    "2bd74194201fd47d6be8b24353dbdac742f6c8f7a96113d514aa1480295ebb3496f293c2a222492c66cf202c42334da70b48afbf0f152bc16d9b9a749d68c249",
  ),
  (
    "passphrase: printable ascii",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    " !\u0022#\u0024%&'()*+,-./0123456789:;<=>?@ABCXYZ[\u005C]^_`abcxyz{|}~",
    "7297b44e9b1aeeeefe80f9938a1c0672568edbeb637724d2683f27fbd08150a17b096d99a1bf10a2d8a9453886a877b692be70198eab0cdfe4ecf7470a54d20f",
  ),
  (
    "passphrase: leading and trailing spaces",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    " pass ",
    "6dc4ada6bbd10d08dda6af2619a7189d48aee62459d431c6f767f3087744f9fe6f272043158af4b91376fe79b224572ef5123cfbcbf41f94ad48d27d52c593c2",
  ),
  (
    "passphrase: newline and tab",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "pa\u000Ass\u0009word",
    "70cbd66b7837ee304f7f876a22e38024eeb9a3548359421d84fa02fb50a8da6561a4c5a42943b04b91e58cf8b1cfe6d6d8209e52644c9914cd1cf23f177f8c59",
  ),
  (
    "passphrase: precomposed accents (NFC, not NFKD-normalised)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "p\u00E4ssw\u00F6rd",
    "9feac44dbec67d0712f7a7addd5f75490bba1f6bf9d7de7723efe96835ba552309cb3ccc11d41ad912219b662f690bcaa760efb55b41cf8d86f99e466e41c2b1",
  ),
  (
    "passphrase: decomposed accents (NFD)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "pa\u0308sswo\u0308rd",
    "9f39d98813742b332e42334137e8f5ccfb549f7e639811eba9b56d1c220c7da2008f9227f2be5492355738797b861a62d2ee7438c849745189e4bbc94bceeab2",
  ),
  (
    "passphrase: german sharp s",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "stra\u00DFe",
    "1027e4cb54dffe5d2d4dbbd106301f6af32c2af87a6657ee40f481617c48ce2a4067ff6706890cf5bb3353325fecf4c1b44625f42d7e98f501e812060330c725",
  ),
  (
    "passphrase: ligature fi (not NFKD-normalised)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\uFB01nance",
    "6c9b433ac0be41e6475f77a33361480d14dd52b7dc34af4ef3f38b65cc3ae69fadddaac6418611159ff0be7b1064c84afc48cb2b28328ad2729e41d5d0357731",
  ),
  (
    "passphrase: fullwidth latin (not NFKD-normalised)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\uFF34\uFF32\uFF25\uFF3A\uFF2F\uFF32",
    "31887488fd9d4e64d4010ee6567d6f722946960f07407fb76e53cd98a79a33bfc27aad51b1f8ac6dd85bb1b216f2f65f47c42d6ec4e33f8b6fbe7b60be6e9135",
  ),
  (
    "passphrase: japanese BIP39 test passphrase (not NFKD-normalised)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\u334D\u30AC\u30D0\u30F4\u30A1\u3071\u3070\u3050\u309E\u3061\u3062\u5341\u4EBA\u5341\u8272",
    "9eb067b2a3c26901a3b48a6a856cc284927a445f07f7f12441fcddd57615cba293b6f23bc0183edca6b7e3bd08a7a34a883b5510519c5de24ea9d2ff70bc9699",
  ),
  (
    "passphrase: korean hangul (not NFKD-normalised)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\uBE44\uBC00\uBC88\uD638",
    "7bf1bd9a4190d4fc9cb44c16d706a9e1d4b03095e05f43e439a444d2ee6c64379674ca7444550dd2a92eb41b076b47d34886fe5dcdce68824a4af7be3e147cc5",
  ),
  (
    "passphrase: chinese",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\u5BC6\u7801\u77ED\u8BED\u6D4B\u8BD5",
    "8c5e6dd4bae7fed236efd94b6c51216bc0499b8cd91539d65ab46eb038e42b9f1f7450388e96024e3f90d23eb68e103599d9d7fdd63bfeb5d8c674f2ab287606",
  ),
  (
    "passphrase: cyrillic",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\u043F\u0430\u0440\u043E\u043B\u044C",
    "7a56b5d58dbd6af5e4a45cc393862f33fda06dd4b20d0a94eca5415d40349356110a65cb16c22fb1784b8878f2aace061ffc86c56b903af84e7265ddb0268ba9",
  ),
  (
    "passphrase: greek with tonos (not NFKD-normalised)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\u03BA\u03C9\u03B4\u03B9\u03BA\u03CC\u03C2",
    "0683a8329b0a4ac5640e27d650e72db1a179d54b94fb5667c19fef8a1fb133312e144478f55754f94919244561508fb35bc806467c5f78040170463f15214295",
  ),
  (
    "passphrase: arabic",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\u0643\u0644\u0645\u0629 \u0627\u0644\u0633\u0631",
    "0b63245ecec1407fef264875fddb0768d66ddc9b4f2f07b78ca27238c0ccce751535b830ed4ba6258fb6846a89ea6f4b502532b7532aa723963fbfccb631fc4a",
  ),
  (
    "passphrase: emoji surrogate pairs",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\uD83D\uDD11\uD83D\uDE80\uD83D\uDC8E",
    "7ef53e74ea2791d67a0d87fd52b2d08a87de9f1bda7f8d24577beac28fdeecd4424eef144cce52c54e9d78b8652677195546e187fedb3a78c20982f1b3ed5769",
  ),
  (
    "passphrase: emoji ZWJ sequence",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\uD83D\uDC68\u200D\uD83D\uDC69\u200D\uD83D\uDC67\u200D\uD83D\uDC66",
    "db038c57d85e8b864f02510c55758d37e4a1246fdd6663bc2ad1eee1da8957c473b0240ab283ca06c07adea56484d40c56a27c69abbb78108ea796d7121c9355",
  ),
  (
    "passphrase: zero-width space",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "pass\u200Bword",
    "79c534bbb56f7bb219eb85151d94f0ee26666ba46cb8276f4eca0e2cb02f734a3066e826fe1f3f643c46feb1b1478a3006f2d430bf5c1faf39016061311e6957",
  ),
  (
    "passphrase: no-break space (not NFKD-normalised)",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "pass\u00A0word",
    "46ae8ef85368282d6f482f06c81ee4f8b8824912848ee79b9e37e2d609a0ea6af581f6f1002358098c6e00cd2220f58724609e491f8c6447b1fcb16f5c9dad9c",
  ),
  (
    "passphrase: NUL character",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "pa\u0000ss",
    "6f2f9b3284f65048734c0ece7b81e953ba76e06413ed4644ffd5fc6319c46fa8589a186c033da9a11c415b2839f00e9a269ef29807eaa294e21c316f757c01de",
  ),
  (
    "passphrase: lone surrogate",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "pa\uD800ss",
    "dcf34b77fb5638e8f216815ff53037c9cae6ecb2314dd061646007e883361bb8be5c4a70b9dc1ec0e8b0939756cc0a8e82c589cba1c95c53ca6950ff33ff3d87",
  ),
  (
    "passphrase: byte order mark",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\uFEFFpass",
    "25d536412299561451e536bd5eb803bf3fac90beefbf5bc6e3d33bf7b3aa6461e9ae87950f30ec6f8aca6714d74d3417a1f8079b968641bb928d3a9505e635d8",
  ),
  (
    "passphrase: 1000 characters",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "x" * 1000,
    "53fe285f6eb736f45b35c5ab62eba15c092292f40492ed8731530941de32a7b814f9362aef0867da3e7cbe7b9de8e4657450b80ffebca90c3cfda17d139c7e7c",
  ),
  (
    "passphrase: 300 CJK characters",
    "infant degree salmon unfold must oil focus legal improve forget tattoo snap",
    "\u5BC6" * 300,
    "95e58d6974f998821f3e7a2a52cf6f30dad9d5678c7ad9cf9fe1f6e968fe539561baad8fa7d4348168d6c8d7de197a843a1d89636f6104e8f2f22a4ce68be5a6",
  ),
  (
    "mnemonic: uppercase",
    "INFANT DEGREE SALMON UNFOLD MUST OIL FOCUS LEGAL IMPROVE FORGET TATTOO SNAP",
    "",
    "536e8c0a32b02200373423c055753ab47247282fbd79d1b2a176a8550e4af1fd3c2a59df5ad33eaca074b0bf0f39808bfa75171587e33ac2bd9d46aabc802c7d",
  ),
  (
    "mnemonic: double spaces",
    "infant  degree  salmon  unfold  must  oil  focus  legal  improve  forget  tattoo  snap",
    "",
    "0dac2d137e74fc78e8fadbea8b47c3c60466554634da35c8c4fc575cb5e1bf16b361feab97cab996eef03ffab35c8b815f5d2ed79bf9ece80ecaeab8d217ef7f",
  ),
  (
    "mnemonic: leading and trailing spaces",
    " infant degree salmon unfold must oil focus legal improve forget tattoo snap ",
    "",
    "35d250c6dd6d0e5c381abeeed490411334a64f067ed2e5f8b752a18a5b9064eefbc787781b3b5cd3c3636206612cd29243bcf69ff74934e498074090fbcc50f0",
  ),
  (
    "mnemonic: newline separated",
    "infant\u000Adegree\u000Asalmon\u000Aunfold\u000Amust\u000Aoil\u000Afocus\u000Alegal\u000Aimprove\u000Aforget\u000Atattoo\u000Asnap",
    "",
    "8695b39c10a3598c91fa115a3a8071ee21088650b7fa7960f05d9a367c3a75f5427ad7f9afa6ddaf981612009633b20af6b229b2b17bcb4e2e2c3c13ad71ab33",
  ),
  (
    "mnemonic: no-break space separated",
    "infant\u00A0degree\u00A0salmon\u00A0unfold\u00A0must\u00A0oil\u00A0focus\u00A0legal\u00A0improve\u00A0forget\u00A0tattoo\u00A0snap",
    "",
    "99f62381c4292efb7c633114a2076532f198c863eacd372ed07318218d6e213a5d675e7d5ae3b5de46467f188381a84cf68b84bb20b4d796c4d38108fb2df0eb",
  ),
  (
    "mnemonic: ideographic space separated",
    "infant\u3000degree\u3000salmon\u3000unfold\u3000must\u3000oil\u3000focus\u3000legal\u3000improve\u3000forget\u3000tattoo\u3000snap",
    "",
    "fcd7eb56ddcd30d716bed06080f674fbcc3964bf72cf9d2c21f00e4ee43c5611c45a8a19b2f9260c214200bff3254e98b7a3fcf233e5974ae9301b1f89a2f612",
  ),
  (
    "mnemonic: japanese wordlist, ideographic spaces",
    "\u3048\u304B\u3099\u304A\u3000\u306F\u3044\u305B\u3093\u3000\u307F\u3068\u3081\u308B\u3000\u304B\u3075\u3099\u304B\u3000\u3042\u308F\u305B\u308B\u3000\u3055\u304D\u3099\u3087\u3046\u3000\u306B\u308F\u3068\u308A\u3000\u3055\u3068\u3057\u3000\u306B\u305B\u3082\u306E\u3000\u3055\u3068\u308B\u3000\u304D\u305B\u3064\u3000\u305B\u3093\u306C\u304D",
    "\u334D\u30AC\u30D0\u30F4\u30A1\u3071\u3070\u3050\u309E\u3061\u3062\u5341\u4EBA\u5341\u8272",
    "926db930e88d63a1d7cdcb369efc437d60cf94fbc22c26a781650b6d98a3cf3cac9e29022317df85da7515b7cf4e6bbd6fe88388fac1788d8aefb4942360bd87",
  ),
  (
    "mnemonic: japanese wordlist, ascii spaces",
    "\u3048\u304B\u3099\u304A \u306F\u3044\u305B\u3093 \u307F\u3068\u3081\u308B \u304B\u3075\u3099\u304B \u3042\u308F\u305B\u308B \u3055\u304D\u3099\u3087\u3046 \u306B\u308F\u3068\u308A \u3055\u3068\u3057 \u306B\u305B\u3082\u306E \u3055\u3068\u308B \u304D\u305B\u3064 \u305B\u3093\u306C\u304D",
    "",
    "02c2b6becf2f292952226eb8f989a5fc972386316c295d74680344b2a45669a52af268501eb10e5f05db662ec407d987280f6474814db4ab3e541228561fdb3f",
  ),
  (
    "mnemonic: spanish wordlist NFC",
    "perico imagen olivo l\u00E1piz seguir semilla audaz cuesta relleno gavil\u00E1n lancha ocurrir",
    "",
    "43300a0f0aa6c3ed53f644b751e9d56dc6b32c620e6e9947d938fa5a14b27b4777ad849e1e2f55923a6f943c15f987f48291f7c15182055d8483812d39c30bf0",
  ),
  (
    "mnemonic: spanish wordlist NFD",
    "perico imagen olivo la\u0301piz seguir semilla audaz cuesta relleno gavila\u0301n lancha ocurrir",
    "",
    "aa02a320acabbdf85c919dadb87b706560d85408fc8971d4bc8416918b29817b1ea62f77846c5afe2534258364be1000a8b8598bfa6889886882882ef2032ac1",
  ),
  (
    "mnemonic: french wordlist",
    "mascotte infusion tailler e\u0301cume tailler chenille mouche vorace justice infini substrat cubique",
    "TREZOR",
    "d4fac24db32d00bb1f8df9360c54dfb1266dc17fc87a79b88259ace89fe46cc1da5541e0fa04eea67cd5e429cb46c600750303be3bd17d55ab176a89f857ab35",
  ),
  (
    "mnemonic: chinese wordlist",
    "\u6B66 \u5EAD \u7EA7 \u6000 \u848B \u5FEB \u7684 \u91CA \u57FA \u8D76 \u732E \u903B",
    "",
    "d7c630a61c84f73882624c53a4ab8248915158c925baa7ea9dbfdd7a6dbaeeff02eaa6cf7950c7b1c25ed23b271f0c1b86fde63e805b2b8500c3fd272b019011",
  ),
  (
    "mnemonic: korean wordlist",
    "\u1109\u1169\u1112\u1167\u11BC \u110E\u1169\u11BC\u1105\u1175 \u1109\u116E\u1103\u1161\u11AB \u1109\u116E\u11A8\u1102\u1167 \u1109\u1165\u11AF\u1110\u1161\u11BC \u1112\u1167\u11AF\u110B\u1162\u11A8 \u1107\u1165\u11B7\u110C\u116C \u1112\u1167\u11AB\u110C\u1175 \u1102\u1161\u1106\u116E\u11AF \u110B\u1167\u110C\u1165\u11AB\u1112\u1175 \u1106\u1162\u11A8\u110C\u116E \u1112\u1161\u11B7\u1101\u1166",
    "",
    "70de5f094062d4dbebcf1512390aea9eb5e96483df86d0883a960735054f621bf545ba4c11830ca6450b9113c360f02ab7ca809c20c3a506bd64afd6a01a7901",
  ),
  (
    "mnemonic: empty",
    "",
    "",
    "4ed8d4b17698ddeaa1f1559f152f87b5d472f725ca86d341bd0276f1b61197e21dd5a391f9f5ed7340ff4d4513aab9cce44f9497a5e7ed85fd818876b6eb402e",
  ),
  (
    "mnemonic: 127 bytes",
    "a" * 127,
    "",
    "a69c3d03fc62bff17455af98a7b1a3c77d7939550e905a30f9237207c7992a7b4fe3b5ef77befcbc49ff3716efb5f65d3807e1a8b9f53e94ceb80dc204c81c63",
  ),
  (
    "mnemonic: 128 bytes",
    "a" * 128,
    "",
    "e03cb086c2fd2795ac49a6f9e5130be066f5f0efe131fc79d5219ed652f5faec69a3a9d13270d5d580846ce0e6e56716c6de27151b0d107e2b443c9d7f3b7e33",
  ),
  (
    "mnemonic: 129 bytes",
    "a" * 129,
    "",
    "c56e21da2e04cb3687c915c4997bff79a469cff09fee004eb30c655ddf2580c23ad96723207f00dcaab84c2e642e876ac326cffdab71f79fb18755c53d21455d",
  ),
  (
    "mnemonic: 128 CJK code units",
    "\u5BC6" * 128,
    "",
    "4cb23ca53f5bde8fabc190b61222cc3b0bf6a72a6916f9068ef733fa9fa54b395e4ad04a7e5652e70316fe6566d252f641d262de44fb647fdb9b3bac6a6a592a",
  ),
  (
    "mnemonic: 64 emoji (128 code units)",
    "\uD83D\uDE00" * 64,
    "",
    "d3ac13d601b7ebfb399a434b1d7f861843d1adf66ad01f518f55f398aaffc780b6d50f88e3d4b39153e492d33fc5bab914e534facc2c4116245faaf7d10c9c03",
  ),
  (
    "mnemonic: lone surrogates",
    "\uD800\uDBFF\uDC00",
    "",
    "1219f6e97b044678a0031f7cf262abab00977e09a73dfec5626000a7aae99fca64e8793370d319c7db642c0559960d7351cbae68893d83930751d2d8b8cfe39f",
  ),
];

void main() {
  group("bip39MnemonicToSeed matches the previous bip39 fork", () {
    for (final (label, mnemonic, passphrase, seed) in _vectors) {
      test(label, () => expect(_hex(bip39MnemonicToSeed(mnemonic, passphrase: passphrase)), seed));
    }
  });
}

String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join();
