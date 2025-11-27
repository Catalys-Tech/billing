// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pularibilling/settings_provider.dart';
import 'package:pularibilling/settings_screen.dart';
import 'package:pularibilling/summary_card.dart';
import 'add_entry.dart';
import 'bill_entry.dart';
import 'entries_provider.dart';
import 'entry_card.dart';
import 'package:pdf/pdf.dart'; // Provides PdfColors and PdfPageFormat

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _searchDate;
  List<BillEntry> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    // Listen to entries stream for real-time updates from Firestore.
    // Use read here as we don't want initState to rebuild the entire widget tree.
    context.read<EntriesProvider>().entriesStream.listen((snapshot) {
      if (mounted) {
        final entries = snapshot.docs.map((doc) => BillEntry.fromFirestore(doc)).toList();

        // Update the provider's internal list
        context.read<EntriesProvider>().setEntries(entries);

        // Re-apply filter and trigger UI rebuild
        _applyFilter(entries);
      }
    });
  }

  void _applyFilter(List<BillEntry> entries) {
    List<BillEntry> newFilteredEntries;

    if (_searchDate != null) {
      newFilteredEntries = entries.where((e) =>
      e.date.year == _searchDate!.year &&
          e.date.month == _searchDate!.month &&
          e.date.day == _searchDate!.day
      ).toList();
    } else {
      newFilteredEntries = entries;
    }

    // Sort by date (newest first) for better display
    newFilteredEntries.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _filteredEntries = newFilteredEntries;
    });
  }

  Future<void> _pickSearchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _searchDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _searchDate = picked;
      });
      // Use read here to get the current list without causing a build
      _applyFilter(context.read<EntriesProvider>().entries);
    }
  }

  void _clearSearch() {
    setState(() {
      _searchDate = null;
    });
    // Use read here to get the current list without causing a build
    _applyFilter(context.read<EntriesProvider>().entries);
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    // Convert entries to string data for the table
    // Ensure all entries are calculated before converting to string for PDF
    final data = _filteredEntries.map((e) => [
      DateFormat('yyyy-MM-dd').format(e.date),
      e.weight.toStringAsFixed(2),
      e.diesel.toStringAsFixed(2),
      e.adBlue.toStringAsFixed(2),
      e.materialAmount.toStringAsFixed(2),
      e.advance.toStringAsFixed(2),
      e.netAmount.toStringAsFixed(2),
    ]).toList();

    pdf.addPage(
      pw.Page(
        // Use the standard A4 constant for guaranteed sizing
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PULARI BILLS Entries', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            if (_searchDate != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text('Filtered Date: ${DateFormat('yyyy-MM-dd').format(_searchDate!)}', style: const pw.TextStyle(fontSize: 14)),
              ),
            if (data.isNotEmpty)
              pw.Table.fromTextArray(
                headers: ['Date', 'Weight', 'Diesel', 'AdBlue', 'Material', 'Advance', 'Net'],
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                // Access PdfColors via the pw alias
                headerDecoration: pw.BoxDecoration(color:PdfColors.grey300),
                cellHeight: 25,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(1.2), // Slightly wider net amount
                },
              )
            else
              pw.Text('No entries available for export.', style: pw.TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );

    // Using layoutPdf for preview and print option, sharePdf is also good but layoutPdf is more comprehensive
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
    // Alternative if only sharing is needed:
    // await Printing.sharePdf(bytes: await pdf.save(), filename: 'pulari_bills.pdf');
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild when provider data changes (entries, settings loading state)
    final entriesProvider = context.watch<EntriesProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // Ensure the initial filtering is done after data is loaded if entries are empty
    if (_filteredEntries.isEmpty && entriesProvider.entries.isNotEmpty) {
      // This handles the first build if the stream listener hasn't fired yet
      _applyFilter(entriesProvider.entries);
    }

    if (settingsProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PULARI BILLS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickSearchDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Search by Date'),
                ),
                if (_searchDate != null) ...[
                  const SizedBox(width: 8),
                  // Use theme color for the date text for visibility
                  Text(
                    DateFormat('yyyy-MM-dd').format(_searchDate!),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
                ],
              ],
            ),
          ),
          // Summary card uses the filtered list
          SummaryCard(
            totalWeight: _filteredEntries.fold(0.0, (sum, e) => sum + e.weight),
            totalDiesel: _filteredEntries.fold(0.0, (sum, e) => sum + e.diesel),
            totalAdBlue: _filteredEntries.fold(0.0, (sum, e) => sum + e.adBlue),
            totalMaterialAmount: _filteredEntries.fold(0.0, (sum, e) => sum + e.materialAmount),
            totalAdvance: _filteredEntries.fold(0.0, (sum, e) => sum + e.advance),
            totalNetAmount: _filteredEntries.fold(0.0, (sum, e) => sum + e.netAmount),
          ),
          // Display the number of results
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing ${_filteredEntries.length} entries.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                return EntryCard(entry: _filteredEntries[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEntryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}