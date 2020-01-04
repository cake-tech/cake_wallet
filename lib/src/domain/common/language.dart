import 'package:flutter/material.dart';

class Language with ChangeNotifier {

  String _currentLanguage;

  Language(this._currentLanguage);

  getCurrentLanguage() => _currentLanguage;

  setCurrentLanguage(String language){
    _currentLanguage = language;
    notifyListeners();
  }

}