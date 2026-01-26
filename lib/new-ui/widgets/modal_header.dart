import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ModalHeader extends StatelessWidget {
  const ModalHeader({super.key, required this.iconPath, required this.message, required this.title});

  final String iconPath;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16)
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(iconPath, width:36,height:36),
              Text(title, style: TextStyle(fontSize:16,fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),),
              Padding(padding:EdgeInsets.symmetric(horizontal: 64),child: Text(message, style: TextStyle(fontSize:12,fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center,))
            ],
          ),
        ),
      ),
    );
  }
}
