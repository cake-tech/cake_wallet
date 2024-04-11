import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int min;
  final int max;
  final int step;
  final double arrowsWidth;
  final double arrowsHeight;
  final EdgeInsets contentPadding;
  final double borderWidth;
  final ValueChanged<int?>? onChanged;

  const NumberTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.arrowsWidth = 24,
    this.arrowsHeight = kMinInteractiveDimension,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.borderWidth = 2,
    this.onChanged,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NumberTextFieldState();
}

class _NumberTextFieldState extends State<NumberTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _canGoUp = false;
  bool _canGoDown = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _updateArrows(int.tryParse(_controller.text));
  }

  @override
  void didUpdateWidget(covariant NumberTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller = widget.controller ?? _controller;
    _focusNode = widget.focusNode ?? _focusNode;
    _updateArrows(int.tryParse(_controller.text));
  }

  @override
  Widget build(BuildContext context) => TextField(
      style: TextStyle(
          color: Theme.of(context).extension<PickerTheme>()!.searchHintColor,
          fontWeight: FontWeight.w600,
          fontSize: 24),
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      maxLength: widget.max.toString().length + (widget.min.isNegative ? 1 : 0),
      decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).extension<PickerTheme>()!.searchBorderColor ??
                    Colors.transparent,
              )),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.transparent,
              )),
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).extension<PickerTheme>()!.searchBackgroundFillColor,
          contentPadding: widget.contentPadding.copyWith(right: 0),
          suffixIconConstraints: BoxConstraints(
              maxHeight: widget.arrowsHeight,
              maxWidth: widget.arrowsWidth + widget.contentPadding.right),
          suffixIcon: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(widget.borderWidth),
                      bottomRight: Radius.circular(widget.borderWidth))),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.centerRight,
              margin: EdgeInsets.only(
                  top: widget.borderWidth,
                  right: widget.borderWidth,
                  bottom: widget.borderWidth,
                  left: widget.contentPadding.right),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                    child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                            child: Opacity(
                                opacity: _canGoUp ? 1 : .5, child: const Icon(Icons.arrow_drop_up)),
                            onTap: _canGoUp ? () => _update(true) : null))),
                Expanded(
                    child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                            child: Opacity(
                                opacity: _canGoDown ? 1 : .5,
                                child: const Icon(Icons.arrow_drop_down)),
                            onTap: _canGoDown ? () => _update(false) : null))),
              ]))),
      maxLines: 1,
      onChanged: (value) {
        final intValue = int.tryParse(value);
        widget.onChanged?.call(intValue);
        _updateArrows(intValue);
      },
      inputFormatters: [_NumberTextInputFormatter(widget.min, widget.max)]);

  void _update(bool up) {
    var intValue = int.tryParse(_controller.text);
    intValue == null ? intValue = widget.min : intValue += up ? widget.step : -widget.step;
    intValue = intValue.clamp(widget.min, widget.max); // Ensure intValue is within range
    _controller.text = intValue.toString();

    // Manually call the onChanged callback after updating the controller's text
    widget.onChanged?.call(intValue);

    _updateArrows(intValue);
    _focusNode.requestFocus();
  }

  void _updateArrows(int? value) {
    final canGoUp = value == null || value < widget.max;
    final canGoDown = value == null || value > widget.min;
    if (_canGoUp != canGoUp || _canGoDown != canGoDown)
      setState(() {
        _canGoUp = canGoUp;
        _canGoDown = canGoDown;
      });
  }
}

class _NumberTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumberTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (const ['-', ''].contains(newValue.text)) return newValue;
    final intValue = int.tryParse(newValue.text);
    if (intValue == null) return oldValue;
    if (intValue < min) return newValue.copyWith(text: min.toString());
    if (intValue > max) return newValue.copyWith(text: max.toString());
    return newValue.copyWith(text: intValue.toString());
  }
}
