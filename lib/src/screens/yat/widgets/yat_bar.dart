import 'package:cake_wallet/src/screens/yat/widgets/yat_close_button.dart';
import 'package:flutter/material.dart';

class YatBar extends StatelessWidget {
  YatBar({this.onClose});

  final VoidCallback? onClose;
  final image = Image.asset('assets/images/yat_logo.png', width: 81, height: 28);

  @override
  Widget build(BuildContext context) {
    return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
              top: 0,
              right: 0,
              child: YatCloseButton(onClose: onClose)
          ),
          Positioned(
              top: 16,
              child: image
          )
        ]
    );
  }
}