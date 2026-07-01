import 'package:flutter/foundation.dart';

abstract class ActionListItem {
  ActionListItem({required this.key});

  DateTime get date;
  Key key;
}