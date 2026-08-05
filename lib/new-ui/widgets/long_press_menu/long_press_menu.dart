import "dart:ui";

import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class LongPressMenuItem {
  LongPressMenuItem({
    required this.label,
    required this.iconPath,
    required this.onSelected,
    this.color,
  });

  final String label;
  final String iconPath;
  final VoidCallback onSelected;
  final Color? color;
}

class LongPressMenu extends StatefulWidget {
  const LongPressMenu({required this.items, super.key});

  final List<LongPressMenuItem> items;

  @override
  State<LongPressMenu> createState() => _LongPressMenuState();
}

class _LongPressMenuState extends State<LongPressMenu> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: _isVisible ? null : 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.primary.withAlpha(60),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.items.map((item) {
                    final color = item.color ?? Theme.of(context).colorScheme.onSurface;
                    return Material(
                      color: Colors.transparent,
                      child: MergeSemantics(
                        child: Semantics(
                          button: true,
                          child: InkWell(
                            onTap: item.onSelected,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                spacing: 8,
                                children: [
                                  ExcludeSemantics(
                                    child: CakeImageWidget(
                                      imageUrl: item.iconPath,
                                      height: 20,
                                      width: 20,
                                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                                    ),
                                  ),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );
}
