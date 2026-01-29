import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ModalHeader extends StatelessWidget {
  const ModalHeader(
      {super.key, required this.iconPath, required this.message, required this.title});

  final String iconPath;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
        decoration: BoxDecoration(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(iconPath, width:36,height:36),
          ),
        ),
      ),
    );
  }
}
