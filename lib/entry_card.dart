// lib/widgets/entry_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'add_entry.dart';
import 'bill_entry.dart';
import 'entries_provider.dart';

class EntryCard extends StatelessWidget {
  final BillEntry entry;

  const EntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(DateFormat('yyyy-MM-dd').format(entry.date)),
        subtitle: Text(
          'Weight: ${entry.weight} | Diesel: ${entry.diesel} | AdBlue: ${entry.adBlue}\n'
              'Material: ${entry.materialAmount.toStringAsFixed(2)} | Advance: ${entry.advance} | Net: ${entry.netAmount.toStringAsFixed(2)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEntryScreen(entry: entry))),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Entry?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Provider.of<EntriesProvider>(context, listen: false).deleteEntry(entry.id!);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}