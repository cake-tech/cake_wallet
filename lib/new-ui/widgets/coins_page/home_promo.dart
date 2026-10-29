import "package:auto_size_text/auto_size_text.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class HomePromo extends StatelessWidget {
  const HomePromo({
    required this.title,
    required this.description,
    required this.iconPath,
    required this.onTap,
    required this.onDismiss,
    super.key,
  });

  final String title;
  final String description;
  final String iconPath;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CakeImageWidget(imageUrl: iconPath, width: 24, height: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AutoSizeText(
                              title,
                              maxLines: 1,
                              minFontSize: 8,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            AutoSizeText(
                              description,
                              maxLines: 1,
                              minFontSize: 8,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    S.of(context).do_not_show_anymore,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({required this.promos, super.key});

  final List<HomePromo> promos;

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.promos.length) {
        0 => const SizedBox.shrink(),
        1 => widget.promos.single,
        _ => Column(
            spacing: 8,
            children: [
              Stack(
                children: [
                  for (final promo in widget.promos)
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: promo,
                    ),
                  Positioned.fill(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        for (final promo in widget.promos)
                          Align(alignment: Alignment.topCenter, child: promo),
                      ],
                    ),
                  ),
                ],
              ),
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.promos.length,
                    (index) => AnimatedContainer(
                      key: ValueKey("home-promo-dot-$index"),
                      duration: const Duration(milliseconds: 200),
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _page.clamp(0, widget.promos.length - 1)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      };
}
