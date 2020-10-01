import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';

class CurrencyPicker extends StatefulWidget {
  CurrencyPicker({
    @required this.selectedAtIndex,
    @required this.items,
    @required this.title,
    @required this.onItemSelected,
  });

  final int selectedAtIndex;
  final List<CryptoCurrency> items;
  final String title;
  final Function(CryptoCurrency) onItemSelected;

  @override
  CurrencyPickerState createState() => CurrencyPickerState(
    selectedAtIndex,
    items,
    title,
    onItemSelected
  );
}

class CurrencyPickerState extends State<CurrencyPicker> {
  CurrencyPickerState(
      this.selectedAtIndex,
      this.items,
      this.title,
      this.onItemSelected): itemsCount = items.length;

  final int selectedAtIndex;
  final List<CryptoCurrency> items;
  final String title;
  final Function(CryptoCurrency) onItemSelected;

  final closeButton = Image.asset('assets/images/close.png',
    color: Palette.darkBlueCraiola,
  );
  final int crossAxisCount = 3;
  final int itemsCount;
  final double backgroundHeight = 280;
  final double thumbHeight = 72;
  ScrollController controller = ScrollController();
  double fromTop = 0;

  @override
  Widget build(BuildContext context) {
    controller.addListener(() {
      fromTop = controller.hasClients
          ? (controller.offset / controller.position.maxScrollExtent * (backgroundHeight - thumbHeight))
          : 0;
      setState(() {});
    });

    return AlertBackground(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(left: 24, right: 24),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        color: Colors.white
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: GestureDetector(
                    onTap: () => null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      child: Container(
                          height: 320,
                          width: 300,
                          color: Theme.of(context).accentTextTheme.title.backgroundColor,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              GridView.count(
                                  controller: controller,
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 1.25,
                                  crossAxisSpacing: 1,
                                  mainAxisSpacing: 1,
                                  children: List.generate(
                                      itemsCount
                                          + getExtraEmptyTilesCount(crossAxisCount, itemsCount),
                                          (index) {

                                        if (index >= itemsCount) {
                                          return Container(
                                            color: Theme.of(context).accentTextTheme.title.color,
                                          );
                                        }

                                        final item = items[index];
                                        final isItemSelected = index == selectedAtIndex;

                                        final color = isItemSelected
                                            ? Theme.of(context).textTheme.body2.color
                                            : Theme.of(context).accentTextTheme.title.color;
                                        final textColor = isItemSelected
                                            ? Palette.blueCraiola
                                            : Theme.of(context).primaryTextTheme.title.color;

                                        return GestureDetector(
                                          onTap: () {
                                            if (onItemSelected == null) {
                                              return;
                                            }
                                            Navigator.of(context).pop();
                                            onItemSelected(item);
                                          },
                                          child: Container(
                                            color: color,
                                            child: Center(
                                              child: Text(
                                                item.toString(),
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.none,
                                                    color: textColor
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                              ),
                              CakeScrollbar(
                                  backgroundHeight: backgroundHeight,
                                  thumbHeight: thumbHeight,
                                  fromTop: fromTop
                              )
                            ],
                          )
                      ),
                    ),
                  ),
                )
              ],
            ),
            AlertCloseButton(image: closeButton)
          ],
        )
    );
  }

  int getExtraEmptyTilesCount(int crossAxisCount, int itemsCount) {
    final int tilesInNewRowCount = itemsCount % crossAxisCount;
    return tilesInNewRowCount == 0 ? 0 : crossAxisCount - tilesInNewRowCount;
  }
}