import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class DesktopActionButton extends StatelessWidget {
  final String image;
  final String title;
  final bool canShow;
  final bool isEnabled;
  final Function() onTap;

  const DesktopActionButton({
    Key? key,
    required this.title,
    required this.image,
    required this.onTap,
    bool? canShow,
    bool? isEnabled,
  })  : this.isEnabled = isEnabled ?? true,
        this.canShow = canShow ?? true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 25),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    image,
                    height: 30,
                    width: 30,
                    color: isEnabled
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  AutoSizeText(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isEnabled
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
