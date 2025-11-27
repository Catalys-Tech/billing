// lib/models/bill_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BillEntry {
  final String? id;
  final DateTime date;
  final double weight;
  final double diesel;
  final double adBlue;
  final double advance;
  final double materialAmount;
  final double netAmount;

  BillEntry({
    this.id,
    required this.date,
    required this.weight,
    required this.diesel,
    required this.adBlue,
    required this.advance,
    required this.materialAmount,
    required this.netAmount,
  });

  // From Firestore
  factory BillEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return BillEntry(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      weight: data['weight'],
      diesel: data['diesel'],
      adBlue: data['adBlue'],
      advance: data['advance'],
      materialAmount: data['materialAmount'],
      netAmount: data['netAmount'],
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'diesel': diesel,
      'adBlue': adBlue,
      'advance': advance,
      'materialAmount': materialAmount,
      'netAmount': netAmount,
    };
  }
}