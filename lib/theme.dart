import 'package:flutter/foundation.dart';

class DynamicDarkMode with ChangeNotifier {
  bool _isDarkMode = false;

  //verif. se o app está em dark mode
  get isDarkMode => this._isDarkMode;

  //aplica o darkMode
  void setDarkMode(){
    this._isDarkMode = true;
    notifyListeners();
  }

  //aplica o lightMode
  void setLightMode(){
    this._isDarkMode = false;
    notifyListeners();
  }


}

