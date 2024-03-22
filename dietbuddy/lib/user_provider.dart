import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String? _email;

  String? get email => _email;

  get userName => null;

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }
}
