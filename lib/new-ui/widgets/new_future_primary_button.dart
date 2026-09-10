import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class NewFuturePrimaryButton extends StatefulWidget {
  const NewFuturePrimaryButton({
    required this.onPressed,
    required this.text,
    required this.color,
    required this.textColor,
    this.borderColor = Colors.transparent,
    this.disabled = false,
    this.image,
    super.key,
  });

  final Future<void> Function() onPressed;
  final bool disabled;
  final SvgPicture? image;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final String text;

  @override
  State<StatefulWidget> createState() => _NewFuturePrimaryButtonState();
}

class _NewFuturePrimaryButtonState extends State<NewFuturePrimaryButton> {
  bool isLoading = false;

  Future<void> _onPressed() async {
    if (isLoading) {
      return;
    }
    setState(() => isLoading = true);
    try {
      await widget.onPressed.call();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => NewPrimaryButton(
        onPressed: _onPressed,
        image: widget.image,
        text: widget.text,
        color: widget.color,
        textColor: widget.textColor,
        isLoading: isLoading,
        borderColor: widget.borderColor,
        disabled: widget.disabled,
      );
}
