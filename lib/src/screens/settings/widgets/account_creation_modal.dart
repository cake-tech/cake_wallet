import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modal_grab_handle.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_edit_or_create_view_model.dart';
import 'package:cw_core/generate_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class AccountCreationModal extends StatefulWidget {
  const AccountCreationModal({
    required this.viewModel,
    super.key,
  });

  final WalletAccountEditOrCreateViewModel viewModel;

  @override
  State<AccountCreationModal> createState() => _AccountCreationModalState();
}

class _AccountCreationModalState extends State<AccountCreationModal> {
  static const int maxAccountNameLength = 25;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.viewModel.label;
    _controller.addListener(() {
      widget.viewModel.label = _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (widget.viewModel.state is IsExecutingState) return;
    if (_controller.text.isEmpty || _controller.text.length > maxAccountNameLength) return;

    await widget.viewModel.save();

    if (!mounted) return;

    if (widget.viewModel.state is ExecutedSuccessfullyState) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ModalGrabHandle(),
                ModalTopBar(
                  title: widget.viewModel.isEdit
                      ? S.of(context).edit_account
                      : S.of(context).create_account,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    spacing: 50,
                    children: [
                      SizedBox(),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                maxLength: maxAccountNameLength,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(maxAccountNameLength),
                                ],
                                decoration: InputDecoration(
                                  hintText: S.of(context).account_name,
                                  counterText: '',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GestureDetector(
                                onTap: () async {
                                  final generated = await generateName();
                                  _controller.text = generated.length > maxAccountNameLength
                                      ? generated.substring(0, maxAccountNameLength)
                                      : generated;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(5)),
                                  child: CakeImageWidget(
                                    imageUrl: "assets/new-ui/randomize.svg",
                                    colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Observer(
                        builder: (_) => NewPrimaryButton(
                          onPressed: _onSubmit,
                          text: S.of(context).continue_text,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          disabled: _controller.text.isEmpty ||
                              _controller.text.length > maxAccountNameLength,
                          isLoading: widget.viewModel.state is IsExecutingState,
                        ),
                      ),
                      SizedBox(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
}
