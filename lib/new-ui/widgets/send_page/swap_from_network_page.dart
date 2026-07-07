import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

class SwapFromNetworkPage extends StatelessWidget {
  const SwapFromNetworkPage({
    super.key,
    required this.title,
    required this.primaryButtonText,
    required this.destinationNetworkName,
    required this.destinationNetworkIconPath,
    required this.currentNetworkName,
    required this.currentNetworkIconPath,
    this.primaryHasSwapIcon = false,
  });

  final String title;
  final String primaryButtonText;
  final bool primaryHasSwapIcon;
  final String destinationNetworkName;
  final String destinationNetworkIconPath;
  final String currentNetworkName;
  final String currentNetworkIconPath;

  static Future<bool?> push({
    required BuildContext context,
    required String title,
    required String primaryButtonText,
    required String destinationtNetworkName,
    required String destinationNetworkIconPath,
    required String currentNetworkName,
    required String currentNetworkIconPath,
    bool primaryHasSwapIcon = false,
  }) {
    return Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => SwapFromNetworkPage(
          title: title,
          primaryButtonText: primaryButtonText,
          destinationNetworkName: destinationtNetworkName,
          destinationNetworkIconPath: destinationNetworkIconPath,
          currentNetworkName: currentNetworkName,
          currentNetworkIconPath: currentNetworkIconPath,
          primaryHasSwapIcon: primaryHasSwapIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              title: '',
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              onLeadingPressed: () => Navigator.of(context).maybePop(),
              trailingIcon: const Icon(Icons.close),
              onTrailingPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          CakeImageWidget(
                            imageUrl: currentNetworkIconPath,
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                          Icon(Icons.arrow_forward, color: colors.primary, size: 28),
                          CakeImageWidget(
                            imageUrl: destinationNetworkIconPath,
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).swap_from_network_description(
                              destinationNetworkName,
                              currentNetworkName,
                            ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.07),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NewPrimaryButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    image: primaryHasSwapIcon
                        ? SvgPicture(
                            AssetBytesLoader('assets/new-ui/swap_arrows.svg.vec'),
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(colors.onPrimary, BlendMode.srcIn),
                          )
                        : null,
                    text: primaryButtonText,
                    color: colors.primary,
                    textColor: colors.onPrimary,
                  ),
                  const SizedBox(height: 12),
                  NewPrimaryButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    text: S.of(context).cancel,
                    color: colors.surfaceContainer,
                    textColor: colors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
