import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    required this.onPressed,
    this.image,
    this.icon,
    required this.title,
    required this.description,
    this.tag,
    super.key,
  }) : assert(image != null || icon != null);

  final VoidCallback onPressed;
  final Image? image;
  final Icon? icon;
  final String title;
  final String description;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ElevatedButton(
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.all(24),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            icon ?? image!,
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 220),
                          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        if (tag != null) Container(
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).colorScheme.onSurfaceVariant
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            margin: EdgeInsets.only(left: 5),
                            child: Text(tag!))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
