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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 25),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Theme.of(context).textTheme.headline6!.backgroundColor!,
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
                      ? Theme.of(context).accentTextTheme.headline2!.backgroundColor!
                      : Theme.of(context).accentTextTheme.headline3!.backgroundColor!,
                ),
                const SizedBox(width: 10),
                AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    color: isEnabled
                        ? Theme.of(context).accentTextTheme.headline2!.backgroundColor!
                        : null,
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
    );
  }
}
