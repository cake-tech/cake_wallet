import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/palette.dart';

class CurrencyPickerWidget extends StatefulWidget {
  CurrencyPickerWidget(
      {@required this.height,
      @required this.width,
      @required this.crossAxisCount,
      @required this.cryptoCurrencyList,
      @required this.selectedAtIndex,
      @required this.subCryptoCurrencyList,
      @required this.itemsCount,
      @required this.textFieldValue,
      @required this.subItems,
      @required this.onItemSelected});

  final double height;
  final double width;
  final int crossAxisCount;
  final List<CryptoCurrency> cryptoCurrencyList;
  final List<CryptoCurrency> subCryptoCurrencyList;
  int selectedAtIndex;
  final int itemsCount;
  final String textFieldValue;
  final List<String> subItems;
  final Function onItemSelected;

  @override
  _CurrencyPickerWidgetState createState() => _CurrencyPickerWidgetState();
}

class _CurrencyPickerWidgetState extends State<CurrencyPickerWidget> {
  final double backgroundHeight = 280;
  final double thumbHeight = 72;
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
                      : widget.itemsCount,
                  (index) => index < widget.itemsCount
                      ? GestureDetector(
                          onTap: () {
                            pickListItem(index);
                            widget.onItemSelected(widget.textFieldValue.isEmpty
                                ? widget.cryptoCurrencyList[index]
                                : widget.subCryptoCurrencyList[index]);
                          },
                          child: Container(
                            color: index == widget.selectedAtIndex
                                ? Theme.of(context).textTheme.bodyText1.color
                                : Theme.of(context)
                                    .accentTextTheme
                                    .headline6
                                    .color,
                            child: Center(
                              child: Text(
                                widget.textFieldValue.isEmpty
                                    ? '${widget.cryptoCurrencyList[index]}'
                                        .toString()
                                    : widget.subItems[index].toString(),
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
                          ),
                        )
                      : Container(
                          color: Colors.white,
                        )),
            ),
            if (widget.itemsCount > 18)
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
