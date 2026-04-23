import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/generate_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class NetworkPathPill extends StatelessWidget {
  const NetworkPathPill({
    required this.sourceChainName,
    required this.destChainName,
    this.showBackground = true,
  });

  final String sourceChainName;
  final String destChainName;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CakeImageWidget(
          imageUrl: 'assets/new-ui/chain_badges/${sourceChainName.toLowerCase()}.svg',
          width: 24,
          height: 24,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          sourceChainName.capitalized(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                letterSpacing: -0.08,
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: scheme.primary,
          ),
        ),
        CakeImageWidget(
          imageUrl: 'assets/new-ui/chain_badges/${destChainName.toLowerCase()}.svg',
          width: 24,
          height: 24,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          destChainName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                letterSpacing: -0.08,
              ),
        ),
      ],
    );
    return Observer(
      builder: (_) {
        return showBackground
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(80),
                ),
                child: body,
              )
            : body;
      },
    );
  }
}
