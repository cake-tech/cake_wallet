part of "seed_settings_cubit.dart";

class SeedSettingsState extends Equatable {
  const SeedSettingsState({
    required this.moneroSeedType,
    required this.bitcoinSeedType,
    required this.nanoSeedType,
    this.passphrase,
  });

  final MoneroSeedType moneroSeedType;
  final BitcoinSeedType bitcoinSeedType;
  final NanoSeedType nanoSeedType;
  final String? passphrase;

  SeedSettingsState copyWith({
    MoneroSeedType? moneroSeedType,
    BitcoinSeedType? bitcoinSeedType,
    NanoSeedType? nanoSeedType,
    String? Function()? passphrase,
  }) =>
      SeedSettingsState(
        moneroSeedType: moneroSeedType ?? this.moneroSeedType,
        bitcoinSeedType: bitcoinSeedType ?? this.bitcoinSeedType,
        nanoSeedType: nanoSeedType ?? this.nanoSeedType,
        passphrase: passphrase != null ? passphrase() : this.passphrase,
      );

  @override
  List<Object?> get props => [moneroSeedType, bitcoinSeedType, nanoSeedType, passphrase];
}
