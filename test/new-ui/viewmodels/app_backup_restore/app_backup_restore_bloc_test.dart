import "dart:io";

import "package:cake_wallet/core/backup/app_backup_restorer.dart";
import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup_restore/app_backup_restore_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockRestorer extends Mock implements AppBackupRestorer {}

class _MockStorageService extends Mock implements AppBackupStorageService {}

void main() {
  final file = File("backup.zip");
  late _MockRestorer restorer;
  late _MockStorageService storageService;

  setUpAll(() => registerFallbackValue(File("")));

  setUp(() {
    restorer = _MockRestorer();
    storageService = _MockStorageService();
    when(() => storageService.clearPickedFiles()).thenAnswer((_) async {});
  });

  AppBackupRestoreBloc createBloc() => AppBackupRestoreBloc(restorer, storageService, file);

  void stubRestore(Future<void> Function(Invocation) answer, {bool checkBackupApp = true}) => when(
        () => restorer.restore(file, "Cat1-Dog2", checkBackupApp: checkBackupApp),
      ).thenAnswer(answer);

  Future<List<AppBackupRestoreState>> statesUntil(
    AppBackupRestoreBloc bloc,
    AppBackupRestoreStatus status,
  ) async {
    final states = <AppBackupRestoreState>[];
    await for (final state in bloc.stream) {
      states.add(state);
      if (state.status == status) break;
    }
    return states;
  }

  Future<AppBackupRestoreBloc> blocWithPassword() async {
    final bloc = createBloc();
    bloc.add(RestorePasswordChanged("Cat1-Dog2"));
    await bloc.stream.first;
    return bloc;
  }

  test("does nothing until a password is entered", () async {
    final bloc = createBloc();
    expect(bloc.state.canSubmit, isFalse);

    bloc.add(RestoreSubmitted());
    await Future<void>.delayed(Duration.zero);
    verifyNever(
      () => restorer.restore(any(), any(), checkBackupApp: any(named: "checkBackupApp")),
    );
    await bloc.close();
  });

  test("restores the picked file and clears picked files on close", () async {
    stubRestore((_) async {});
    final bloc = await blocWithPassword();

    bloc.add(RestoreSubmitted());
    final states = await statesUntil(bloc, AppBackupRestoreStatus.restored);
    expect(states.map((state) => state.status),
        [AppBackupRestoreStatus.restoring, AppBackupRestoreStatus.restored]);

    await bloc.close();
    verify(() => storageService.clearPickedFiles()).called(1);
  });

  test("a wrong password goes back to the input and clears once edited", () async {
    stubRestore((_) async => throw const AppBackupWrongPasswordException());
    final bloc = await blocWithPassword();

    bloc.add(RestoreSubmitted());
    final failed = (await statesUntil(bloc, AppBackupRestoreStatus.idle)).last;
    expect(failed.showWrongPassword, isTrue);
    expect(failed.canSubmit, isFalse);

    bloc.add(RestorePasswordChanged("Cat1-Dog3"));
    final edited = await bloc.stream.first;
    expect(edited.showWrongPassword, isFalse);
    expect(edited.canSubmit, isTrue);
    await bloc.close();
  });

  test("a backup from another app restores only after it's confirmed", () async {
    stubRestore(
      (_) async => throw const IncompatibleBackupAppException(
        sourceAppName: "Monero.com",
        currentAppName: "Cake Wallet",
      ),
    );
    stubRestore((_) async {}, checkBackupApp: false);
    final bloc = await blocWithPassword();

    bloc.add(RestoreSubmitted());
    final mismatch = (await statesUntil(bloc, AppBackupRestoreStatus.appMismatch)).last;
    expect(mismatch.appMismatch?.sourceAppName, "Monero.com");

    bloc.add(AppMismatchConfirmed());
    await statesUntil(bloc, AppBackupRestoreStatus.restored);
    verify(() => restorer.restore(file, "Cat1-Dog2", checkBackupApp: false)).called(1);
    await bloc.close();
  });

  test("dismissing the app mismatch goes back to idle without restoring", () async {
    stubRestore(
      (_) async => throw const IncompatibleBackupAppException(
        sourceAppName: "Monero.com",
        currentAppName: "Cake Wallet",
      ),
    );
    final bloc = await blocWithPassword();

    bloc.add(RestoreSubmitted());
    await statesUntil(bloc, AppBackupRestoreStatus.appMismatch);
    bloc.add(AppMismatchDismissed());
    final dismissed = await bloc.stream.first;
    expect(dismissed.status, AppBackupRestoreStatus.idle);
    expect(dismissed.appMismatch, isNull);

    bloc.add(AppMismatchConfirmed());
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => restorer.restore(file, "Cat1-Dog2", checkBackupApp: false));
    await bloc.close();
  });

  test("a failed restore reports the error and goes back to idle", () async {
    stubRestore((_) async => throw StateError("disk full"));
    final bloc = await blocWithPassword();

    bloc.add(RestoreSubmitted());
    final states = await statesUntil(bloc, AppBackupRestoreStatus.idle);
    expect(states.map((state) => state.status), [
      AppBackupRestoreStatus.restoring,
      AppBackupRestoreStatus.failed,
      AppBackupRestoreStatus.idle,
    ]);
    expect(states[1].error, contains("disk full"));
    expect(states.last.canSubmit, isTrue);
    await bloc.close();
  });
}
