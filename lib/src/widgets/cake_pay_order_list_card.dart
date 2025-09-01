import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';

class CakePayOrderListCard extends StatelessWidget {
  const CakePayOrderListCard({
    Key? key,
    required this.id,
    required this.create,
    this.quantity,
    this.price,
    required this.pair,
    required this.onTap,
    required this.currentTheme,
    this.backgroundImage,
    this.aspectRatio = 16 / 9,
  }) : super(key: key);

  final String id;
  final String create;
  final String? quantity;
  final String? price;
  final String pair;
  final ThemeType currentTheme;
  final void Function(BuildContext) onTap;
  final String? backgroundImage;
  final double aspectRatio;

  ImageProvider? _imageProviderFor(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return NetworkImage(path);
    return AssetImage(path);
  }

  Color _labelBackground(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return surface.withOpacity(0.75);
  }

  Color _titleLabelBackground(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return surface.withOpacity(0.85);
  }

  Widget _labelBox(
    BuildContext context, {
    required String text,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    double radius = 10,
    Color? background,
    TextStyle? style,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? _labelBackground(context),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: style ??
            Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _imageProviderFor(backgroundImage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image(image: image, fit: BoxFit.cover)
                else
                  Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                if (image != null)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.6, 1.0],
                        colors: [Colors.transparent, Colors.black26, Colors.black54],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _labelBox(
                                context,
                                text: 'Create • $create',
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                radius: 8,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              _labelBox(
                                context,
                                text: 'Qty • $quantity   Total • $price',
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                radius: 8,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          _labelBox(
                            context,
                            text: pair,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            radius: 12,
                            background: _titleLabelBackground(context),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _labelBox(
                        context,
                        text: 'Order • $id',
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        radius: 10,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(currentTheme == ThemeType.dark ? 0.08 : 0.12),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
