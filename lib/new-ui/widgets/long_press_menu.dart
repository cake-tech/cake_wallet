import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LongPressMenuItem {
  final String label;
  final String iconPath;
  final VoidCallback onSelected;
  final Color? color;

  LongPressMenuItem({required this.label, required this.iconPath, required this.onSelected, this.color});
}

class LongPressMenu extends StatefulWidget {
  const LongPressMenu({super.key, required this.items});

  final List<LongPressMenuItem> items;

  @override
  State<LongPressMenu> createState() => _LongPressMenuState();
}

class _LongPressMenuState extends State<LongPressMenu> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // 2. Trigger the change AFTER the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: _isVisible ? null : 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
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
                    child: InkWell(
                      onTap: item.onSelected,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Container(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 8,
                            children: [
                              SvgPicture.asset(
                                item.iconPath,
                                height: 20,
                                width: 20,
                                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                              ),
                              Text(item.label,
                                  style: TextStyle(
                                      color: color, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
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
}
