import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/dua_model.dart';

class DuaRepository {
  Future<List<Dua>> loadAllDuas() async {
    final String response = await rootBundle.loadString('assets/munajat.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => Dua.fromJson(json)).toList();
  }
  Future<List<Dua>> getDuasByManzil(int manzilNumber) async {
    final allDuas = await loadAllDuas();
    return allDuas.where((dua) => dua.manzilNumber == manzilNumber).toList();
  }
}