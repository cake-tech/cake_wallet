import "dart:convert";
import "dart:io";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/node.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

class _MockSettingsStore extends Mock implements SettingsStore {}

Future<void> main() async {
  final dataRoot = Directory("./test/data/node_create_or_edit_view_model");

  const formChainId = 57073;
  const wrongChainId = 137;

  late HttpServer server;
  late List<String> requestedPaths;
  late _MockSettingsStore settingsStore;

  NodeCreateOrEditViewModel evmNodeForm(String path) {
    final viewModel = NodeCreateOrEditViewModel(
      false,
      const WalletNetwork.added(formChainId),
      settingsStore,
    );
    viewModel.setAddress("127.0.0.1");
    viewModel.setPort("${server.port}");
    viewModel.setPath(path);
    return viewModel;
  }

  setUpAll(() async {
    S.current = const S();
    registerFallbackValue(Node(uri: "fallback.example", type: WalletType.evm));

    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();

    CakeTor.instance = CakeTorDisabled();

    // /answers/<chainId> answers eth_chainId with that chain, anything else fails with a 500
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requestedPaths.add(request.uri.path);
      final segments = request.uri.pathSegments;

      if (segments.first == "answers") {
        final chainId = int.parse(segments[1]);
        // Slow enough that a second tap lands while the first probe is still out
        await Future<void>.delayed(const Duration(milliseconds: 50));
        request.response.write(
          jsonEncode({"jsonrpc": "2.0", "id": 1, "result": "0x${chainId.toRadixString(16)}"}),
        );
      } else {
        request.response.statusCode = HttpStatus.internalServerError;
      }

      await request.response.close();
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    requestedPaths = [];
    await db!.delete(Node.tableName);
    settingsStore = _MockSettingsStore();
  });

  group("NodeCreateOrEditViewModel.save", () {
    test("a node that answers another chain is refused and not saved", () async {
      final viewModel = evmNodeForm("/answers/$wrongChainId");

      await viewModel.save();

      expect(
        viewModel.state,
        isA<FailureState>().having((s) => s.error, "error", S.current.node_on_another_network),
      );
      expect(
        viewModel.connectionState,
        isA<FailureState>().having((s) => s.error, "error", S.current.node_on_another_network),
      );
      expect(await Node.getAllForEvmChain(formChainId), isEmpty);
    });

    test("a node on the form's chain is saved on that chain", () async {
      final viewModel = evmNodeForm("/answers/$formChainId");

      await viewModel.save();

      expect(viewModel.state, isA<ExecutedSuccessfullyState>());
      final saved = await Node.getAllForEvmChain(formChainId);
      expect(saved, hasLength(1));
      expect(saved.single.type, WalletType.evm);
      expect(saved.single.chainId, formChainId);
      expect(saved.single.uri.toString(), "http://127.0.0.1:${server.port}/answers/$formChainId");
      verifyNever(() => settingsStore.setCurrentNode(any()));
    });

    test("a node that does not answer is still saved", () async {
      final viewModel = evmNodeForm("/down");

      await viewModel.save();

      expect(requestedPaths, ["/down"]);
      expect(viewModel.state, isA<ExecutedSuccessfullyState>());
      expect(await Node.getAllForEvmChain(formChainId), hasLength(1));
    });

    test("a second tap while the chain check runs does not save twice", () async {
      final viewModel = evmNodeForm("/answers/$formChainId");

      final firstTap = viewModel.save();
      final secondTap = viewModel.save();
      await Future.wait([firstTap, secondTap]);

      expect(requestedPaths, hasLength(1));
      expect(await Node.getAllForEvmChain(formChainId), hasLength(1));
      expect(viewModel.state, isA<ExecutedSuccessfullyState>());
    });

    test("saving again after a refusal runs the check again", () async {
      final viewModel = evmNodeForm("/answers/$wrongChainId");
      await viewModel.save();

      viewModel.setPath("/answers/$formChainId");
      await viewModel.save();

      expect(requestedPaths, ["/answers/$wrongChainId", "/answers/$formChainId"]);
      expect(viewModel.state, isA<ExecutedSuccessfullyState>());
      expect(await Node.getAllForEvmChain(formChainId), hasLength(1));
    });

    test("save as current hands the saved node to the settings store", () async {
      when(() => settingsStore.setCurrentNode(any())).thenReturn(null);
      final viewModel = evmNodeForm("/answers/$formChainId");

      await viewModel.save(saveAsCurrent: true);

      final current = verify(() => settingsStore.setCurrentNode(captureAny())).captured.single;
      expect((current as Node).chainId, formChainId);
    });

    test("a built-in network's node is saved without the chain check", () async {
      final viewModel = NodeCreateOrEditViewModel(
        false,
        const WalletNetwork.builtin(WalletType.ethereum),
        settingsStore,
      );
      viewModel.setAddress("127.0.0.1");
      viewModel.setPort("${server.port}");
      viewModel.setPath("/answers/$wrongChainId");

      await viewModel.save();

      expect(requestedPaths, isEmpty);
      expect(viewModel.state, isA<ExecutedSuccessfullyState>());
      expect(await Node.getAllForWalletType(WalletType.ethereum), hasLength(1));
    });
  });
}
