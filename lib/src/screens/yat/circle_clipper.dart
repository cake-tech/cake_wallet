import 'package:flutter/material.dart';

class CircleClipper extends CustomClipper<Path> {
  CircleClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
    Path()..addOval(Rect.fromCircle(radius: radius, center: center));

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}