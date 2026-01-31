import 'package:flutter/material.dart';

class ModalGrabHandle extends StatelessWidget {
  const ModalGrabHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(9999999)),
          height: 5,
          width: 48),
    );
  }
}
