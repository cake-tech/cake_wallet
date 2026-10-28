import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class GeneratingTransactionOverlay extends StatelessWidget {
  const GeneratingTransactionOverlay({required this.sendViewModel, required this.child, super.key});

  final SendViewModel sendViewModel;
  final Widget child;

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ExcludeSemantics(
              excluding: sendViewModel.state.runtimeType == IsExecutingState,
              child: child,
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: sendViewModel.state.runtimeType != IsExecutingState,
                child: ExcludeSemantics(
                  excluding: sendViewModel.state.runtimeType != IsExecutingState,
                  child: AnimatedOpacity(
                    opacity: sendViewModel.state.runtimeType == IsExecutingState ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Semantics(
                          container: true,
                          liveRegion: true,
                          label: "${S.of(context).generating_transaction}...",
                          excludeSemantics: true,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 12,
                            children: [
                              CupertinoActivityIndicator(
                                radius: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              Text(
                                "${S.of(context).generating_transaction}...",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
