// lib/providers/settings_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  double _ratePerTon = 1310.0;
  bool _isLoading = true;

  double get ratePerTon => _ratePerTon;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadRate();
  }

  Future<void> _loadRate() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('global')
          .get();
      if (doc.exists) {
        _ratePerTon = doc['ratePerTon'] ?? 1310.0;
      } else {
        // Set default if not exists
        await setRate(1310.0);
      }
    } catch (e) {
      // Handle error, fallback to default
      _ratePerTon = 1310.0;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setRate(double newRate) async {
    _ratePerTon = newRate;
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('global')
        .set({'ratePerTon': newRate});
    notifyListeners();
  }
}