import 'package:flutter/material.dart';

class SettingActionButton extends StatelessWidget {
  final bool isLastTile;
  final bool isSelected;
  final bool isArrowVisible;
  final bool selectionActive;
  final VoidCallback onTap;
  final String image;
  final String title;
  final double fromBottomEdge;
  final double fromTopEdge;
  final double tileHeight;
  const SettingActionButton({
    super.key,
    this.isLastTile = false,
    this.isSelected = false,
    this.selectionActive = true,
    this.isArrowVisible = false,
    required this.onTap,
    required this.image,
    required this.title,
    this.tileHeight = 60,
    this.fromTopEdge = 50,
    this.fromBottomEdge = 25,
  });

  @override
  Widget build(BuildContext context) {
    Color? color = isSelected
        ? Theme.of(context).colorScheme.primary
        : selectionActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface;
    return Container(
      //padding: EdgeInsets.only(top: 5, left: 15, bottom: 5),
      margin: EdgeInsets.only(top: 10, left: 20, bottom: 0, right: 20),
      child: TextButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainer,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        onPressed: onTap,
        //hoverColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: 12, left: 20, bottom: 12, right: 15),
          //margin: EdgeInsets.only(top: 5, left: 15, bottom: 5),
          alignment: isLastTile ? Alignment.topLeft : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                image,
                height: 16,
                width: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontSize: 16,
                      ),
                ),
              ),
              if (isArrowVisible)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                )
            ],
          ),
        ),
      ),
    );
  }
}
