import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/palette.dart';
import 'pickerItem.dart';

class CurrencyPickerWidget extends StatefulWidget {
  CurrencyPickerWidget(
      {@required this.height,
      @required this.width,
      @required this.crossAxisCount,
      @required this.cryptoCurrencyList,
      @required this.selectedAtIndex,
      @required this.itemsCount,
      @required this.onItemSelected,
      this.textFieldValue});

  final double height;
  final double width;
  final int crossAxisCount;
  final List<CryptoCurrency> cryptoCurrencyList;
  int selectedAtIndex;
  final int itemsCount;
  final String textFieldValue;
  final Function onItemSelected;

  List<String> prefixCryptoCurrencyIconList;
  List<String> postfixCryptoCurrencyIconList;

  @override
  _CurrencyPickerWidgetState createState() =>
      _CurrencyPickerWidgetState(height);
}

class _CurrencyPickerWidgetState extends State<CurrencyPickerWidget> {
  _CurrencyPickerWidgetState(this.height) : backgroundHeight = height * 0.95;
  double height;
  double backgroundHeight;
  final double thumbHeight = 170;
  ScrollController controller = ScrollController();
  double fromTop = 0;

  void pickListItem(int index) {
    setState(() {
      widget.selectedAtIndex = index;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    controller.addListener(() {
      fromTop = controller.hasClients
          ? (controller.offset /
              controller.position.maxScrollExtent *
              (backgroundHeight - thumbHeight))
          : 0;
      setState(() {});
    });

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Theme.of(context).accentTextTheme.headline6.backgroundColor,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GridView.count(
              padding: EdgeInsets.all(0),
              controller: controller,
              crossAxisCount: widget.crossAxisCount,
              childAspectRatio: (widget.width * 0.9 / 2) / (widget.height / 9),
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              children: List.generate(
                  widget.itemsCount < 18
                      ? widget.itemsCount + (18 - widget.itemsCount)
                      : widget.itemsCount, (index) {
                if (index < widget.itemsCount) {
                  return GestureDetector(
                    onTap: () {
                      pickListItem(index);
                      widget.onItemSelected(widget.cryptoCurrencyList[index]);
                    },
                    child: Container(
                      color: index == widget.selectedAtIndex
                          ? Theme.of(context).textTheme.bodyText1.color
                          : Theme.of(context).accentTextTheme.headline6.color,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  child: Image.asset(
                                    PickerItem(
                                            currencyIndex: widget
                                                .cryptoCurrencyList[index].raw)
                                        .leftIcon,
                                    height: 32.0,
                                    width: 32.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.cryptoCurrencyList[index].toString(),
                                  style: TextStyle(
                                      color: index == widget.selectedAtIndex
                                          ? Palette.blueCraiola
                                          : Theme.of(context)
                                              .primaryTextTheme
                                              .title
                                              .color,
                                      fontSize: 18.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    color: Colors.white,
                  );
                }
              }),
            ),
            CakeScrollbar(
                backgroundHeight: backgroundHeight,
                thumbHeight: thumbHeight,
                fromTop: fromTop)
          ],
        ),
      ),
    );
  }
}
