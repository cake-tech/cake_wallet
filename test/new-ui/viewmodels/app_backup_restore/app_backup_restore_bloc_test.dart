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
  const mismatch = IncompatibleBackupAppException(
    sourceAppName: "Monero.com",
    currentAppName: "Cake Wallet",
  );
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

  Future<AppBackupRestoreBloc> blocWithPassword() async {
    final bloc = createBloc();
    bloc.add(RestorePasswordChanged("Cat1-Dog2"));
    await bloc.stream.first;
    return bloc;
  }

  Future<AppBackupRestoreState> restoreFinished(AppBackupRestoreBloc bloc) =>
      bloc.stream.firstWhere((state) => !state.isRestoring);

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
    final restoring = await bloc.stream.first;
    expect(restoring.isRestoring, isTrue);
    expect(restoring.canSubmit, isFalse);
    await Future<void>.delayed(Duration.zero);
    verify(() => restorer.restore(file, "Cat1-Dog2", checkBackupApp: true)).called(1);
    expect(bloc.state.isRestoring, isTrue);

    await bloc.close();
    verify(() => storageService.clearPickedFiles()).called(1);
  });

  test("a wrong password goes back to the input and clears once edited", () async {
    stubRestore((_) async => throw const AppBackupWrongPasswordException());
    final bloc = await blocWithPassword();

    bloc.add(RestoreSubmitted());
    final failed = await restoreFinished(bloc);
    expect(failed.showWrongPassword, isTrue);
    expect(failed.canSubmit, isFalse);

    bloc.add(RestorePasswordChanged("Cat1-Dog3"));
    final edited = await bloc.stream.first;
    expect(edited.showWrongPassword, isFalse);
    expect(edited.canSubmit, isTrue);
    await bloc.close();
  });

  test("a backup from another app is presented and restored only once confirmed", () async {
    stubRestore((_) async => throw mismatch);
    stubRestore((_) async {}, checkBackupApp: false);
    final bloc = await blocWithPassword();
    final presented = bloc.presentation.first;

    bloc.add(RestoreSubmitted());
    final event = await presented;
    expect(event, isA<AppMismatchDetected>());
    expect((event as AppMismatchDetected).mismatch.sourceAppName, "Monero.com");
    expect(bloc.state.canSubmit, isTrue);
    verifyNever(() => restorer.restore(file, "Cat1-Dog2", checkBackupApp: false));

    bloc.add(AppMismatchConfirmed());
    expect((await bloc.stream.first).isRestoring, isTrue);
    await Future<void>.delayed(Duration.zero);
    verify(() => restorer.restore(file, "Cat1-Dog2", checkBackupApp: false)).called(1);
    await bloc.close();
  });

  test("a failed restore is presented and goes back to the input", () async {
    stubRestore((_) async => throw StateError("disk full"));
    final bloc = await blocWithPassword();
    final presented = bloc.presentation.first;

    bloc.add(RestoreSubmitted());
    final event = await presented;
    expect(event, isA<RestoreFailed>());
    expect((event as RestoreFailed).error, contains("disk full"));
    expect(bloc.state.isRestoring, isFalse);
    expect(bloc.state.canSubmit, isTrue);
    await bloc.close();
  });
}
