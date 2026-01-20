import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/allah_name.dart';

class AllahNamesService {
  static final AllahNamesService _instance = AllahNamesService._internal();
  factory AllahNamesService() => _instance;
  AllahNamesService._internal();

  List<AllahName>? _names;

  Future<List<AllahName>> getNames() async {
    if (_names != null) return _names!;
    
    final String data = await rootBundle.loadString('assets/99names.json');
    final List<dynamic> jsonList = json.decode(data);
    _names = jsonList.map((json) => AllahName.fromJson(json)).toList();
    return _names!;
  }
}
