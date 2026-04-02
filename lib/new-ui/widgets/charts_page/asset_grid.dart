import 'package:flutter/material.dart';

class ChartsAssetGrid extends StatelessWidget {
  const ChartsAssetGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,           
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,       
    ), itemBuilder: (context, index){});
  }
}
