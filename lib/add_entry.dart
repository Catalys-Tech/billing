// lib/screens/add_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:pularibilling/settings_provider.dart';

import 'bill_entry.dart';
import 'entries_provider.dart';

class AddEntryScreen extends StatefulWidget {
  final BillEntry? entry;  // For editing
  const AddEntryScreen({super.key, this.entry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late TextEditingController _weightCtrl;
  late TextEditingController _dieselCtrl;
  late TextEditingController _adBlueCtrl;
  late TextEditingController _advanceCtrl;
  double _materialAmount = 0.0;
  double _netAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _date = widget.entry?.date ?? DateTime.now();
    _weightCtrl = TextEditingController(text: widget.entry?.weight.toString() ?? '');
    _dieselCtrl = TextEditingController(text: widget.entry?.diesel.toString() ?? '');
    _adBlueCtrl = TextEditingController(text: widget.entry?.adBlue.toString() ?? '');
    _advanceCtrl = TextEditingController(text: widget.entry?.advance.toString() ?? '');
    _calculateAmounts();
  }

  void _calculateAmounts() {
    double weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    double advance = double.tryParse(_advanceCtrl.text) ?? 0.0;
    double rate = Provider.of<SettingsProvider>(context, listen: false).ratePerTon;
    setState(() {
      _materialAmount = weight * rate;
      _netAmount = _materialAmount - advance;
    });
  }

  Future<void> _pickDate() async {
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2000),
      maxTime: DateTime(2100),
      onConfirm: (date) {
        setState(() {
          _date = date;
        });
      },
      currentTime: _date,
    );
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      BillEntry newEntry = BillEntry(
        id: widget.entry?.id,
        date: _date,
        weight: double.parse(_weightCtrl.text),
        diesel: double.parse(_dieselCtrl.text),
        adBlue: double.parse(_adBlueCtrl.text),
        advance: double.parse(_advanceCtrl.text),
        materialAmount: _materialAmount,
        netAmount: _netAmount,
      );
      if (widget.entry == null) {
        Provider.of<EntriesProvider>(context, listen: false).addEntry(newEntry);
      } else {
        Provider.of<EntriesProvider>(context, listen: false).updateEntry(widget.entry!.id!, newEntry);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Add Entry' : 'Edit Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_date)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (ton)'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (_) => _calculateAmounts(),
              ),
              TextFormField(
                controller: _dieselCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Diesel'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _adBlueCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'AdBlue'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _advanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Advance'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (_) => _calculateAmounts(),
              ),
              const SizedBox(height: 16),
              Text('Material Amount: ${_materialAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Net Amount: ${_netAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEntry,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}