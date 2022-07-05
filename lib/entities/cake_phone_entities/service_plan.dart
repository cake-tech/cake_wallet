import 'package:flutter/material.dart';

class ServicePlan {
  const ServicePlan({
    @required this.id,
    @required this.duration,
    @required this.price,
    @required this.quantity,
  });

  final String id;
  final int duration;
  final int price;
  final int quantity;

  @override
  bool operator ==(Object other) => other is ServicePlan && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
