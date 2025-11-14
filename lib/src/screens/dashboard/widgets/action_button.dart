import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  ActionButton({
    required this.image,
    required this.title,
    this.route,
    this.onClick,
    this.alignment = Alignment.center,
    this.textColor,
    super.key,
  });

  final Image image;
  final String title;
  final String? route;
  final Alignment alignment;
  final VoidCallback? onClick;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        if (route?.isNotEmpty ?? false) {
          Navigator.of(context, rootNavigator: true).pushNamed(route!);
        } else {
          onClick?.call();
        }
      },
      child: SizedBox.expand(
        child: Container(
          color: Colors.transparent,
          alignment: alignment,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              image,
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor ??
                            Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
