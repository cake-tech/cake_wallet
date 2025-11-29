import 'dart:async';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cake_wallet/src/widgets/seed_language_picker.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:get_it/get_it.dart';

part 'new_wallet_group_view_model.g.dart';

class WalletGroupNewVM = WalletGroupNewVMBase with _$WalletGroupNewVM;

abstract class WalletGroupNewVMBase with Store {
  WalletGroupNewVMBase(
    this.appStore,
    this.walletCreationService, {
    required this.walletNewVMBuilder,
    required this.args,
  })  : state = InitialExecutionState(),
        name = '';

  final AppStore appStore;
  final WalletCreationService walletCreationService;
  final WalletNewVM Function(NewWalletArguments) walletNewVMBuilder;
  final WalletGroupArguments args;

  static const defaultMoneroOptions = [
    defaultSeedLanguage,
    MoneroSeedType.bip39
  ];

  @observable
  String name;

  @observable
  String? walletPassword;

  @observable
  String? repeatedWalletPassword;

  @observable
  ExecutionState state;

  @observable
  double progress = 0.0;

  @observable
  List<WalletType> done = const [];

  @observable
  String? error;

  Future<bool> nameExists(String name) => walletCreationService.exists(name);

  bool groupNameExists(String name) =>
      walletCreationService.groupNameExists(name);

  Future<String> _uniquePerTypeName(WalletType type) async {
    final base = walletTypeToString(type);
    var i = 1;
    while (await walletCreationService.exists('$base $i')) {
      i++;
    }
    return '$base $i';
  }

  String _uniqueGroupName(String preferred) {
    var base = preferred.trim().isEmpty ? 'Group' : preferred.trim();
    if (!groupNameExists(base)) return base;

    var i = 2;
    while (groupNameExists('$base ($i)')) {
      i++;
    }
    return '$base ($i)';
  }

  @action
  Future<void> createNewGroup({dynamic options}) async {
    try {
      state = IsExecutingState();
      error = null;
      done = [];
      progress = 0;

      final types = args.types;
      final currentType = args.currentType;

      if (types.isEmpty) throw 'No wallet types provided.';
      if (currentType == null) throw 'Current wallet type is not provided.';
      if (!onlyBIP39Selected(types))
        throw 'Only BIP39-based wallet types are supported in a group.';

      final restTypes = types.where((type) => type != currentType).toList();

      var groupNameCandidate =
          name.trim().isEmpty ? await generateName() : name.trim();
      final groupName = _uniqueGroupName(groupNameCandidate);

      final providedMnemonic = args.mnemonic;
      if (providedMnemonic != null && providedMnemonic.isEmpty) {
        throw 'Provided mnemonic is empty.';
      }


      dynamic options;

      // default options for monero
      if (currentType == WalletType.monero) {
        options = defaultMoneroOptions;
      }

      final currentWalletName = await _uniquePerTypeName(currentType);
      await _createSingleWallet(
        type: currentType,
        finalName: currentWalletName,
        isChildWallet: false,
        mnemonic: providedMnemonic,
        options: options,
        makeCurrent: true,
      );
      done = [...done, currentType];
      progress = done.length / types.length;

      final currentWallet = appStore.wallet;
      if (currentWallet == null)
        throw Exception('First wallet was not set as current.');

      final groupKey = currentWallet.walletInfo.hashedWalletIdentifier ?? '';
      if (groupKey.isEmpty)
        throw Exception(
            'Failed to resolve wallet group key from first wallet.');

      String? sharedMnemonic = providedMnemonic;
      sharedMnemonic ??= currentWallet.seed;
      if (sharedMnemonic == null || sharedMnemonic.isEmpty) {
        throw Exception('Failed to resolve mnemonic (shared) for group.');
      }


      final String? sharedPassphrase =
          args.passphrase ?? currentWallet.passphrase;

      await walletCreationService.setGroupNameForKey(groupKey, groupName);

      state = ExecutedSuccessfullyState(
        payload: WalletGroupParams(
          restTypes: restTypes,
          sharedMnemonic: sharedMnemonic,
          sharedPassphrase: sharedPassphrase,
          isChildWallet: true,
          groupKey: groupKey,
        ),
      );
    } catch (e, s) {
      printV('WalletGroupNewVM.create error: $e');
      printV('Stack: $s');
      error = e.toString();
      state = FailureState(error!);
    }
  }

  Future<void> createRestWallets(WalletGroupParams params) async {
    await Future<void>.delayed(Duration.zero); // run on next event loop turn

    for (final type in params.restTypes) {
      final walletName = await _uniquePerTypeName(type);
      dynamic options;

      // default options for monero
      if (type == WalletType.monero) {
        options = defaultMoneroOptions;
      }

      if (params.sharedPassphrase != null &&
          params.sharedPassphrase!.isNotEmpty) {
        final sharedPassphraseMap = {'passphrase': params.sharedPassphrase!};
        if (options is List) {
          options = [...options, sharedPassphraseMap];
        } else {
          options = [sharedPassphraseMap];
        }
      }

      await _createSingleWallet(
        type: type,
        finalName: walletName,
        isChildWallet: params.isChildWallet,
        mnemonic: params.sharedMnemonic,
        options: options,
        makeCurrent: false,
      );
      done = [...done, type];
      progress =
          done.length / (done.length + params.restTypes.length - done.length);
    }
  }

  Future<void> _createSingleWallet({
    required WalletType type,
    required String finalName,
    required bool isChildWallet,
    required String? mnemonic,
    required dynamic options,
    required bool makeCurrent,
  }) async {
    final newArgs = NewWalletArguments(
        type: type, mnemonic: mnemonic, isChildWallet: isChildWallet);

    final walletNewVM = walletNewVMBuilder(newArgs);
    walletNewVM.name = finalName;
    await walletNewVM.create(options: options, makeCurrent: makeCurrent);
  }
}
