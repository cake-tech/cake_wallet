import 'dart:ui';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class NewSearchBar extends StatelessWidget {
  const NewSearchBar({
    super.key,
    required this.controller,
    this.enableOuterBlur = false,
    this.height = 40,
  });

  final TextEditingController controller;
  final bool enableOuterBlur;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SizedBox(
          height: height,
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(128),
                border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest, width: 1),
                borderRadius: BorderRadius.circular(99999)),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: S.of(context).search,
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(Icons.search),
                filled: false,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99999),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: (height - 28) / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
