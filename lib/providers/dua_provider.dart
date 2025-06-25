import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/dua_model.dart'; // Assuming Dua model is in models/dua_model.dart

class DuaProvider extends ChangeNotifier {
  List<Dua> _allDuas = [];
  bool _isLoaded = false;

  List<Dua> get allDuas => _allDuas;

  Future<void> loadAllDuas() async {
    if (_isLoaded) {
      return; // Load only once
    }
    try {
      final String response = await rootBundle.loadString('assets/munajat.json');
      final List<dynamic> data = json.decode(response);
      _allDuas = data.map((json) => Dua.fromJson(json)).toList();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      // Handle error, e.g., log it or show a user-friendly message
      // Consider using a logging framework like `logger` or `flutter_logger` for production apps.
      // For now, we'll just rethrow the error or handle it silently.
      // throw e; // Or rethrow if you want to propagate the error
    }
  }
}
