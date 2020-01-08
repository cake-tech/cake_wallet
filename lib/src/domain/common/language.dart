import 'package:flutter/material.dart';

class Language with ChangeNotifier {
  Language(this._currentLanguage);

  String _currentLanguage;

  String getCurrentLanguage() => _currentLanguage;

  void setCurrentLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }
}