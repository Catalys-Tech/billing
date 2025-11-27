// lib/widgets/summary_card.dart
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double totalWeight;
  final double totalDiesel;
  final double totalAdBlue;
  final double totalMaterialAmount;
  final double totalAdvance;
  final double totalNetAmount;

  const SummaryCard({
    super.key,
    required this.totalWeight,
    required this.totalDiesel,
    required this.totalAdBlue,
    required this.totalMaterialAmount,
    required this.totalAdvance,
    required this.totalNetAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Total Weight: ${totalWeight.toStringAsFixed(2)}'),
            Text('Total Diesel: ${totalDiesel.toStringAsFixed(2)}'),
            Text('Total AdBlue: ${totalAdBlue.toStringAsFixed(2)}'),
            Text('Total Material Amount: ${totalMaterialAmount.toStringAsFixed(2)}'),
            Text('Total Advance: ${totalAdvance.toStringAsFixed(2)}'),
            Text('Total Net Amount: ${totalNetAmount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}