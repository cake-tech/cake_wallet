import 'package:flutter/material.dart';

class ThemeChanger with ChangeNotifier {
  
  ThemeChanger(this._themeData);

  ThemeData _themeData;

  ThemeData getTheme() => _themeData;

  void setTheme(ThemeData theme){
    _themeData = theme;

    notifyListeners();
  }
}