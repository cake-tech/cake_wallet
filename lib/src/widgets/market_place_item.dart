import 'package:flutter/material.dart';

class MarketPlaceItem extends StatelessWidget {


  MarketPlaceItem({
    required this.onTap,
    required this.title,
    required this.subTitle,
  });

  final VoidCallback onTap;
  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme!.titleLarge!.backgroundColor!,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context)
                            .accentTextTheme!
                            .displayMedium!
                            .backgroundColor!,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subTitle,
                      style: TextStyle(
                          color:  Theme.of(context)
                            .accentTextTheme!
                            .displayMedium!
                            .backgroundColor!,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Lato'),
                    )
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

