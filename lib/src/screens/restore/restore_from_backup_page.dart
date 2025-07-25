import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/restore_from_backup_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class RestoreFromBackupPage extends BasePage {
  RestoreFromBackupPage(this.restoreFromBackupViewModel)
      : textEditingController = TextEditingController();

  final RestoreFromBackupViewModel restoreFromBackupViewModel;
  final TextEditingController textEditingController;

  @override
  String get title => S.current.restore_title_from_backup;

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      };

  @override
  Widget body(BuildContext context) {
    reaction((_) => restoreFromBackupViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                  alertTitle: S.of(context).error,
                  alertContent: state.error,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop(),
                );
              });
        });
      }
    });

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
        child: Padding(
          padding: EdgeInsets.only(bottom: 24, left: 8, right: 8),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BaseTextFormField(
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          hintText: S.of(context).enter_backup_password,
                          keyboardType: TextInputType.visiblePassword,
                          controller: textEditingController,
                          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 26,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Observer(
                          builder: (_) {
                            if (restoreFromBackupViewModel.filePath.isNotEmpty) {
                              return Column(
                                children: [
                                  const SizedBox(height: 100),
                                  Row(
                                    children: [
                                      Text(
                                        "File Name: ",
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: titleColor(context),
                                            ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          restoreFromBackupViewModel.filePath.split("/").last,
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                                color: titleColor(context),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        onPressed: () => presentFilePicker(),
                        text: S.of(context).select_backup_file,
                        color: Theme.of(context).colorScheme.error,
                        textColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Observer(
                        builder: (_) {
                          return LoadingPrimaryButton(
                            isLoading: restoreFromBackupViewModel.state is IsExecutingState,
                            onPressed: () => onImportHandler(context),
                            text: S.of(context).import,
                            color: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> presentFilePicker() async {
    final result = await FilePicker.platform.pickFiles();

    if (result?.files.isEmpty ?? true) {
      return;
    }

    restoreFromBackupViewModel.filePath = result!.files.first.path!;
  }

  Future<void> onImportHandler(BuildContext context) async {
    if (textEditingController.text.isEmpty || (restoreFromBackupViewModel.filePath.isEmpty)) {
      await showPopUp<void>(
          context: context,
          builder: (_) {
            return AlertWithOneAction(
                alertTitle: S.current.error,
                alertContent: S.of(context).please_select_backup_file,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });

      return;
    }
    try {
      await restoreFromBackupViewModel.import(textEditingController.text);
    } catch (e) {
      await showPopUp<void>(
        context: context,
        builder: (_) {
          return AlertWithOneAction(
              alertTitle: S.current.error,
              alertContent: e.toString(),
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
    }
    textEditingController.text = '';
  }
}
