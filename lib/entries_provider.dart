// lib/providers/entries_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


import 'bill_entry.dart';

class EntriesProvider with ChangeNotifier {
  List<BillEntry> _entries = [];

  List<BillEntry> get entries => _entries;

  // Summaries
  double get totalWeight => _entries.fold(0.0, (sum, e) => sum + e.weight);
  double get totalDiesel => _entries.fold(0.0, (sum, e) => sum + e.diesel);
  double get totalAdBlue => _entries.fold(0.0, (sum, e) => sum + e.adBlue);
  double get totalMaterialAmount => _entries.fold(0.0, (sum, e) => sum + e.materialAmount);
  double get totalAdvance => _entries.fold(0.0, (sum, e) => sum + e.advance);
  double get totalNetAmount => _entries.fold(0.0, (sum, e) => sum + e.netAmount);

  Stream<QuerySnapshot> get entriesStream {
    return FirebaseFirestore.instance
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots();
  }

  void setEntries(List<BillEntry> newEntries) {
    _entries = newEntries;
    notifyListeners();
  }

  Future<void> addEntry(BillEntry entry) async {
    await FirebaseFirestore.instance.collection('entries').add(entry.toFirestore());
  }

  Future<void> updateEntry(String id, BillEntry entry) async {
    await FirebaseFirestore.instance.collection('entries').doc(id).update(entry.toFirestore());
  }

  Future<void> deleteEntry(String id) async {
    await FirebaseFirestore.instance.collection('entries').doc(id).delete();
  }
}