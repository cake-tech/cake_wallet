import "package:cake_wallet/core/morpho/morpho_service.dart";
import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class _MockWalletAddresses extends Mock implements WalletAddresses {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockEVM extends Mock implements EVM {}

class _MockVault extends Mock implements MorphoVault {}

class _MockMorphoService extends Mock implements MorphoService {}

class _MockPendingTransaction extends Mock implements PendingTransaction {}

const _user = "0x15273714bdfed50e922c4cdd35ed50291780b392";
const _approve = (to: "usdc", data: "approve");
const _deposit = (to: "vault", data: "deposit");
const _withdraw = (to: "vault", data: "withdraw");
const _redeem = (to: "vault", data: "redeem");
final _shares = BigInt.parse("95000000000000000000");

Money _usdc(String amount) => Money.parse(amount, MorphoVault.usdcToken);

void main() {
  late _MockWallet wallet;
  late _MockSettingsStore settingsStore;
  late _MockEVM evm;
  late _MockVault vault;
  late _MockMorphoService service;
  late _MockPendingTransaction signed;

  setUpAll(() {
    S.current = const S();
    registerFallbackValue(_usdc("0"));
    registerFallbackValue(BigInt.zero);
    registerFallbackValue((to: "", data: ""));
    registerFallbackValue(_MockWallet());
    registerFallbackValue(WalletType.ethereum);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    wallet = _MockWallet();
    settingsStore = _MockSettingsStore();
    evm = _MockEVM();
    vault = _MockVault();
    service = _MockMorphoService();
    signed = _MockPendingTransaction();
    final addresses = _MockWalletAddresses();

    when(() => wallet.walletAddresses).thenReturn(addresses);
    when(() => addresses.address).thenReturn(_user);
    when(() => wallet.name).thenReturn("Morpho test");
    when(() => wallet.chainId).thenReturn(MorphoVault.chainId);
    when(() => wallet.type).thenReturn(WalletType.ethereum);
    when(() => wallet.updateTransactionsHistory()).thenAnswer((_) async {});
    when(() => wallet.updateBalance()).thenAnswer((_) async {});
    when(() => settingsStore.getPriority(any(), chainId: any(named: "chainId"))).thenReturn(null);
    when(() => settingsStore.useBlinkProtection).thenReturn(true);

    when(() => vault.getShareBalance(any())).thenAnswer((_) async => _shares);
    when(() => vault.getUsdcBalance(any())).thenAnswer((_) async => _usdc("500"));
    when(() => vault.getUsdcAllowance(any())).thenAnswer((_) async => _usdc("0"));
    when(() => vault.getAvailableLiquidity()).thenAnswer((_) async => _usdc("1000000"));
    when(() => vault.previewRedeem(any())).thenAnswer((_) async => _usdc("100"));
    when(() => vault.dryRun(any())).thenAnswer((_) async {});
    when(() => vault.usdcApproveCall()).thenReturn(_approve);
    when(() => vault.depositCall(any(), any())).thenReturn(_deposit);
    when(() => vault.withdrawCall(any(), any())).thenReturn(_withdraw);
    when(() => vault.redeemCall(any(), any())).thenReturn(_redeem);
    when(() => service.getApy()).thenAnswer((_) async => 0.05);
    when(() => service.getEarned(any())).thenAnswer((_) async => _usdc("1"));

    when(() => signed.fee).thenReturn(Money.parse("0.0001", CryptoCurrency.eth));
    when(() => signed.evmTxHashFromRawHex).thenReturn("0x1234");
    when(() => signed.commit()).thenAnswer((_) async {});
    when(
      () => evm.createRawCallDataTransaction(
        any(),
        any(),
        any(),
        any(),
        any(),
        useBlinkProtection: any(named: "useBlinkProtection"),
      ),
    ).thenAnswer((_) async => signed);
    when(() => evm.getTransactionReceipt(any(), any()))
        .thenAnswer((_) => Future<bool?>.value(true));
  });

  Future<MorphoBloc> loadedBloc() async {
    final bloc = MorphoBloc(
      wallet: wallet,
      settingsStore: settingsStore,
      evm: evm,
      vault: vault,
      service: service,
    );
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((state) => state is MorphoReady);
    return bloc;
  }

  Future<MorphoState> settled(MorphoBloc bloc, MorphoEvent event) {
    final result = bloc.stream.firstWhere(
      (state) => state is MorphoPrepared || state is MorphoFailure,
    );
    bloc.add(event);
    return result;
  }

  void verifySigned(ContractCall call) => verify(
        () => evm.createRawCallDataTransaction(
          wallet,
          call.to,
          call.data,
          any(),
          any(),
          useBlinkProtection: any(named: "useBlinkProtection"),
        ),
      ).called(1);

  group("routes funds through the right vault call", () {
    test("approves first when the allowance is short, and only signs the deposit after that",
        () async {
      final bloc = await loadedBloc();

      final approval = await settled(bloc, DepositRequested(_usdc("100")));
      expect((approval as MorphoPrepared).operation.action, MorphoAction.approve);
      verifySigned(_approve);

      final deposit = await settled(bloc, TransactionConfirmed(approval.operation));
      expect((deposit as MorphoPrepared).operation.action, MorphoAction.deposit);
      expect(deposit.operation.amount, _usdc("100"));
      verify(() => vault.depositCall(_usdc("100"), _user)).called(1);
      verifySigned(_deposit);
      verify(() => signed.commit()).called(1);
    });

    test("deposits directly when the allowance covers the amount", () async {
      when(() => vault.getUsdcAllowance(any())).thenAnswer((_) async => _usdc("100"));
      final bloc = await loadedBloc();

      final state = await settled(bloc, DepositRequested(_usdc("100")));

      expect((state as MorphoPrepared).operation.action, MorphoAction.deposit);
      verifyNever(() => vault.usdcApproveCall());
      verifySigned(_deposit);
    });

    test("redeems every share to withdraw the whole position", () async {
      final bloc = await loadedBloc();

      final state = await settled(bloc, const WithdrawAllRequested());

      expect((state as MorphoPrepared).operation.action, MorphoAction.withdrawAll);
      verify(() => vault.redeemCall(_shares, _user)).called(1);
      verifyNever(() => vault.withdrawCall(any(), any()));
      verifySigned(_redeem);
    });

    test("rejects a withdrawal above the vault's free liquidity before signing", () async {
      when(() => vault.getAvailableLiquidity()).thenAnswer((_) async => _usdc("40"));
      final bloc = await loadedBloc();

      final state = await settled(bloc, WithdrawRequested(_usdc("50")));

      expect((state as MorphoFailure).error, S.current.error_text_input_above_maximum_limit);
      verifyNever(
        () => evm.createRawCallDataTransaction(
          any(),
          any(),
          any(),
          any(),
          any(),
          useBlinkProtection: any(named: "useBlinkProtection"),
        ),
      );
    });
  });
}
