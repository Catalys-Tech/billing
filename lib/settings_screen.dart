// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pularibilling/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(text: Provider.of<SettingsProvider>(context, listen: false).ratePerTon.toString());
  }

  void _saveRate() {
    double newRate = double.tryParse(_rateCtrl.text) ?? 1310.0;
    Provider.of<SettingsProvider>(context, listen: false).setRate(newRate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rate per Ton'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveRate,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}