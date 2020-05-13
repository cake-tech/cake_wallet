import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';

class ProviderPicker extends StatelessWidget {
  ProviderPicker({
    @required this.selectedAtIndex,
    @required this.items,
    @required this.title,
    @required this.onItemSelected,
  });

  final int selectedAtIndex;
  final List<ExchangeProvider> items;
  final String title;
  final Function(ExchangeProvider) onItemSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
              decoration: BoxDecoration(color: PaletteDark.historyPanel.withOpacity(0.75)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 24, right: 24),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                            color: Colors.white
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                      child: GestureDetector(
                        onTap: () => null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          child: Container(
                            height: 233,
                            color: PaletteDark.menuList,
                            child: ListView.separated(
                              separatorBuilder: (context, index) => Divider(
                                color: PaletteDark.mainBackgroundColor,
                                height: 1,
                              ),
                              itemCount: items == null ? 0 : items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final isItemSelected = index == selectedAtIndex;

                                final color = isItemSelected
                                    ? PaletteDark.menuHeader
                                    : Colors.transparent;
                                final textColor = isItemSelected
                                    ? Colors.blue
                                    : Colors.white;

                                return GestureDetector(
                                  onTap: () {
                                    if (onItemSelected == null) {
                                      return;
                                    }
                                    Navigator.of(context).pop();
                                    onItemSelected(item);
                                  },
                                  child: Container(
                                    height: 77,
                                    padding: EdgeInsets.only(left: 24, right: 24),
                                    alignment: Alignment.center,
                                    color: color,
                                    child: Text(
                                      item.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
          ),
        ),
      ),
    );
  }
}