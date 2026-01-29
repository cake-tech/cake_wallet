import 'dart:math';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/viewmodels/lightning_username/lightning_username_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cw_core/generate_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LightningUsernamePage extends StatefulWidget {
  const LightningUsernamePage({super.key, required this.isSetup});

  final bool isSetup;

  @override
  State<LightningUsernamePage> createState() => _LightningUsernamePageState();
}

class _LightningUsernamePageState extends State<LightningUsernamePage> {
  late bool _editMode;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editMode = widget.isSetup;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt.get<LightningUsernameBloc>(),
      child: BlocListener<LightningUsernameBloc, LightningUsernameState>(
        listener: (context, state) {
          if (state is LightningUsernameSaved) {
            if (widget.isSetup) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              Navigator.of(context).pop();
            }
          }
          if (state is LightningUsernameInitial) {
            if (!widget.isSetup) {
              _controller.text = state.username;
            }
          }
        },
        child: BlocBuilder<LightningUsernameBloc, LightningUsernameState>(
          builder: (context, state) {
            return Material(
              child: Container(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
                child: SafeArea(
                  child: Column(
                    children: [
                      ModalTopBar(
                        title: "Lightning ${S.of(context).username}",
                        leadingIcon: Icon(Icons.arrow_back_ios_new),
                        onLeadingPressed: Navigator.of(context).pop,
                      ),
                      Expanded(
                        child: Column(
                          spacing: 24,
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isSetup)
                              Text(
                                S.of(context).lightning_username_desc,
                                textAlign: TextAlign.center,
                              ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _editMode
                                  ? LightningUsernameEditor(
                                      controller: _controller,
                                      onRandomizeButtonTap: () {
                                        randomizeUsername(context);
                                      },
                                      state: state,
                                    )
                                  : LightningUsernameInfo(
                                      username: state.username,
                                    ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          spacing: 12,
                          children: [
                            if (widget.isSetup) ...[
                              Text(
                                S.of(context).lightning_username_setup_later,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              SizedBox(),
                              NewPrimaryButton(
                                  onPressed: () {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                  text: S.of(context).skip,
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  textColor: Theme.of(context).colorScheme.primary),
                            ],
                            NewPrimaryButton(
                              onPressed: () {
                                if (_editMode) {
                                  context
                                      .read<LightningUsernameBloc>()
                                      .add(UsernameSaveRequested());
                                } else {
                                  setState(() {
                                    _editMode = true;
                                  });
                                }
                              },
                              text:
                                  _editMode ? S.of(context).confirm : S.of(context).change_username,
                              color: Theme.of(context).colorScheme.primary,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                              disabled: _editMode && (!(state is LightningUsernameReady)),
                              isLoading: (state is LightningUsernameSaving),
                            ),
                            SizedBox()
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void randomizeUsername(BuildContext context) async {
    final randomNumber = Random.secure().nextInt(9999);
    final randomName = await generateName();
    final username = "${randomName.replaceAll(" ", "")}$randomNumber".toLowerCase();

    context.read<LightningUsernameBloc>().add(UsernameChanged(username));
    _controller.text = username;
  }
}

class LightningUsernameInfo extends StatelessWidget {
  const LightningUsernameInfo({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 24,
      children: [
        SvgPicture.asset("assets/new-ui/lightning_username_setup.svg"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 2,
          children: [
            Text(
              username,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            Text(
              usernameSuffix,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center,
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            S.of(context).lightning_username_desc_completed,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }
}

class LightningUsernameEditor extends StatelessWidget {
  const LightningUsernameEditor(
      {super.key,
      required this.controller,
      required this.onRandomizeButtonTap,
      required this.state});

  final TextEditingController controller;
  final VoidCallback onRandomizeButtonTap;
  final LightningUsernameState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        SvgPicture.asset("assets/new-ui/lightning_username_setup.svg"),
        SizedBox(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16))),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                          child: TextField(
                        onChanged: (val) {
                          context.read<LightningUsernameBloc>().add(UsernameChanged(val));
                        },
                        controller: controller,
                      )),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onRandomizeButtonTap,
                          child: SvgPicture.asset("assets/new-ui/randomize.svg",
                              colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.primary, BlendMode.srcIn)),
                        ),
                      ),
                      SizedBox()
                    ],
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                height: 56,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(16))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    usernameSuffix,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
        if (state is LightningUsernameError)
          Text(
            (state as LightningUsernameError).error.message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: (state as LightningUsernameError).error.isInfo
                    ? Colors.green
                    : Theme.of(context).colorScheme.error),
          )
        else if (state is LightningUsernameReady)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(
                Icons.check,
                color: Colors.green,
                size: 12,
              ),
              Text(
                S.of(context).username_available,
                style: TextStyle(color: Colors.green),
              )
            ],
          )
        else
          Text("")
      ],
    );
  }
}
