import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/core/seed_validator.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/domain/common/mnemonic_item.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/widgets.dart';

class SeedWidget extends StatefulWidget {
  SeedWidget(
      {Key key,
      this.maxLength,
      this.onMnemonicChange,
      this.onFinish,
      this.leading,
      this.middle,
      this.validator})
      : super(key: key);

  final int maxLength;
  final Function(List<MnemonicItem>) onMnemonicChange;
  final Function() onFinish;
  final SeedValidator validator;
  final Widget leading;
  final Widget middle;

  @override
  SeedWidgetState createState() => SeedWidgetState(maxLength: maxLength);
}

class SeedWidgetState extends State<SeedWidget> {
  SeedWidgetState({this.maxLength});

  List<MnemonicItem> items = <MnemonicItem>[];
  final int maxLength;
  final _seedController = TextEditingController();
  final _seedTextFieldKey = GlobalKey();
  MnemonicItem selectedItem;
  bool isValid;
  String errorMessage;

  List<MnemonicItem> currentMnemonics;
  bool isCurrentMnemonicValid;
  String _errorMessage;

  @override
  void initState() {
    super.initState();
    isValid = false;
    isCurrentMnemonicValid = false;
    _seedController
        .addListener(() => changeCurrentMnemonic(_seedController.text));
  }

  void addMnemonic(String text) {
    setState(() => items.add(MnemonicItem(text: text.trim().toLowerCase())));
    _seedController.text = '';

    if (widget.onMnemonicChange != null) {
      widget.onMnemonicChange(items);
    }
  }

  void mnemonicFromText(String text) {
    final splitted = text.split(' ');

    if (splitted.length >= 2) {
      for (final text in splitted) {
        if (text == ' ' || text.isEmpty) {
          continue;
        }

        if (selectedItem != null) {
          editTextOfSelectedMnemonic(text);
        } else {
          addMnemonic(text);
        }
      }
    }
  }

  void selectMnemonic(MnemonicItem item) {
    setState(() {
      selectedItem = item;
      currentMnemonics = [item];

      _seedController
        ..text = item.text
        ..selection = TextSelection.collapsed(offset: item.text.length);
    });
  }

  void onMnemonicTap(MnemonicItem item) {
    if (selectedItem == item) {
      setState(() => selectedItem = null);
      _seedController.text = '';
      return;
    }

    selectMnemonic(item);
  }

  void editTextOfSelectedMnemonic(String text) {
    setState(() => selectedItem.changeText(text));
    selectedItem = null;
    _seedController.text = '';

    if (widget.onMnemonicChange != null) {
      widget.onMnemonicChange(items);
    }
  }

  void clear() {
    setState(() {
      items = [];
      selectedItem = null;
      _seedController.text = '';

      if (widget.onMnemonicChange != null) {
        widget.onMnemonicChange(items);
      }
    });
  }

  void invalidate() => setState(() => isValid = false);

  void validated() => setState(() => isValid = true);

  void setErrorMessage(String errorMessage) =>
      setState(() => this.errorMessage = errorMessage);

  void replaceText(String text) {
    setState(() => items = []);
    mnemonicFromText(text);
  }

  void changeCurrentMnemonic(String text) {
    setState(() {
      final trimmedText = text.trim();
      final splitted = trimmedText.split(' ');
      _errorMessage = null;

      if (text == null) {
        currentMnemonics = [];
        isCurrentMnemonicValid = false;
        return;
      }

      currentMnemonics =
          splitted.map((text) => MnemonicItem(text: text)).toList();

      var isValid = true;

      for (final word in currentMnemonics) {
        isValid = widget.validator.isValid(word);

        if (!isValid) {
          break;
        }
      }

      isCurrentMnemonicValid = isValid;
    });
  }

  void saveCurrentMnemonicToItems() {
    setState(() {
      if (selectedItem != null) {
        selectedItem.changeText(currentMnemonics.first.text.trim());
        selectedItem = null;
      } else {
        items.addAll(currentMnemonics);
      }

      currentMnemonics = [];
      _seedController.text = '';
    });
  }

  void showErrorIfExist() {
    setState(() => _errorMessage =
        !isCurrentMnemonicValid ? S.current.incorrect_seed : null);
  }

  bool isSeedValid() {
    bool isValid;

    for (final item in items) {
      isValid = widget.validator.isValid(item);

      if (!isValid) {
        break;
      }
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        Flexible(
          fit: FlexFit.tight,
          flex: 2,
          child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.all(0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24)),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).primaryTextTheme.subhead.color,
                    Theme.of(context).primaryTextTheme.subhead.decorationColor,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(
                children: <Widget>[
                  CupertinoNavigationBar(
                    leading: widget.leading,
                    middle: widget.middle,
                    backgroundColor: Colors.transparent,
                    border: null,
                  ),
                  Expanded(
                      child: Container(
                    padding: EdgeInsets.all(24),
                    alignment: Alignment.topLeft,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            S.of(context).restore_active_seed,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .textTheme
                                    .overline
                                    .backgroundColor),
                          ),
                          Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Wrap(
                                children: items.map((item) {
                                  final isValid =
                                      widget.validator.isValid(item);
                                  final isSelected = selectedItem == item;

                                  return InkWell(
                                    onTap: () => onMnemonicTap(item),
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: isValid
                                                ? Colors.transparent
                                                : Palette.red),
                                        margin: EdgeInsets.only(
                                            right: 7, bottom: 8),
                                        child: Text(
                                          item.toString(),
                                          style: TextStyle(
                                              color: isValid
                                                  ? Colors.white
                                                  : Colors.grey,
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.w900
                                                  : FontWeight.w600,
                                              decoration: isSelected
                                                  ? TextDecoration.underline
                                                  : TextDecoration.none),
                                        )),
                                  );
                                }).toList(),
                              ))
                        ],
                      ),
                    ),
                  ))
                ],
              )),
        ),
        Flexible(
            fit: FlexFit.tight,
            flex: 3,
            child: Padding(
              padding:
                  EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 24),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      S.of(context).restore_new_seed,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color:
                              Theme.of(context).primaryTextTheme.title.color),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: TextFormField(
                        key: _seedTextFieldKey,
                        onFieldSubmitted: (text) => isCurrentMnemonicValid
                            ? saveCurrentMnemonicToItems()
                            : null,
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.normal,
                            color:
                                Theme.of(context).primaryTextTheme.title.color),
                        controller: _seedController,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                            suffixIcon: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 145),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Text('${items.length}/$maxLength',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .accentTextTheme
                                                .display2
                                                .decorationColor,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 16)),
                                    SizedBox(width: 10),
                                    InkWell(
                                      onTap: () async =>
                                          Clipboard.getData('text/plain').then(
                                              (clipboard) =>
                                                  replaceText(clipboard.text)),
                                      child: Container(
                                          height: 35,
                                          padding: EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .accentTextTheme
                                                  .caption
                                                  .color,
                                              borderRadius:
                                                  BorderRadius.circular(10.0)),
                                          child: Text(
                                            S.of(context).paste,
                                            style: TextStyle(
                                                color: Palette.blueCraiola),
                                          )),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .display2
                                    .decorationColor,
                                fontWeight: FontWeight.normal,
                                fontSize: 16),
                            hintText:
                                S.of(context).restore_from_seed_placeholder,
                            errorText: _errorMessage,
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .accentTextTheme
                                        .subtitle
                                        .backgroundColor,
                                    width: 1.0)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .accentTextTheme
                                        .subtitle
                                        .backgroundColor,
                                    width: 1.0))),
                        enableInteractiveSelection: false,
                      ),
                    )
                  ]),
            )),
        Padding(
            padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Row(
              children: <Widget>[
                Flexible(
                    child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: PrimaryButton(
                    onPressed: clear,
                    text: S.of(context).clear,
                    color: Colors.red,
                    textColor: Colors.white,
                    isDisabled: items.isEmpty,
                  ),
                )),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: (selectedItem == null && items.length == maxLength)
                        ? PrimaryButton(
                            text: S.of(context).restore_next,
                            isDisabled: !isSeedValid(),
                            onPressed: () => widget.onFinish != null
                                ? widget.onFinish()
                                : null,
                            color: Palette.blueCraiola,
                            textColor: Colors.white)
                        : PrimaryButton(
                            text: selectedItem != null
                                ? S.of(context).save
                                : S.of(context).add_new_word,
                            onPressed: () => isCurrentMnemonicValid
                                ? saveCurrentMnemonicToItems()
                                : null,
                            onDisabledPressed: () => showErrorIfExist(),
                            isDisabled: !isCurrentMnemonicValid,
                            color: Palette.blueCraiola,
                            textColor: Colors.white),
                  ),
                )
              ],
            ))
      ]),
    );
  }
}
