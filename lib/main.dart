// Billify Lite - Hive-backed Flutter Billing App
// Single-file demo: lib/main.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(InvoiceItemAdapter());
  Hive.registerAdapter(InvoiceAdapter());

  // Open boxes
  await Hive.openBox<Invoice>('invoices');
  await Hive.openBox('settings');

  runApp(const BillifyLiteApp());
}

// --- HIVE DATA MODELS AND ADAPTERS ---

@HiveType(typeId: 0)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  String desc;
  @HiveField(1)
  int qty;
  @HiveField(2)
  double rate;

  InvoiceItem({required this.desc, required this.qty, required this.rate});
}

@HiveType(typeId: 1)
class Invoice extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String number;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  String customer;
  @HiveField(4)
  List<InvoiceItem> items;
  @HiveField(5)
  double tax;
  @HiveField(6)
  double discount;
  @HiveField(7)
  double total;
  @HiveField(8)
  String paymentStatus;

  Invoice({
    required this.id,
    required this.number,
    required this.date,
    required this.customer,
    required this.items,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentStatus,
  });
}

class InvoiceItemAdapter extends TypeAdapter<InvoiceItem> {
  @override
  final int typeId = 0;

  @override
  InvoiceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return InvoiceItem(
      desc: fields[0] as String,
      qty: fields[1] as int,
      rate: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.desc)
      ..writeByte(1)
      ..write(obj.qty)
      ..writeByte(2)
      ..write(obj.rate);
  }
}

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 1;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Invoice(
      id: fields[0] as String,
      number: fields[1] as String,
      date: fields[2] as DateTime,
      customer: fields[3] as String,
      items: (fields[4] as List).cast<InvoiceItem>(),
      tax: fields[5] as double,
      discount: fields[6] as double,
      total: fields[7] as double,
      paymentStatus: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.customer)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.tax)
      ..writeByte(6)
      ..write(obj.discount)
      ..writeByte(7)
      ..write(obj.total)
      ..writeByte(8)
      ..write(obj.paymentStatus);
  }
}

// --- REUSABLE PDF FUNCTION ---

// --- REUSABLE PDF FUNCTION ---

Future<Uint8List> generateInvoicePdf(Invoice inv) async {
  final pdf = pw.Document();
  final dateFmt = DateFormat('dd MMM yyyy');

  final subtotal = inv.items.fold(0.0, (p, e) => p + e.qty * e.rate);
  final taxAmount = subtotal * (inv.tax / 100);

  pdf.addPage(pw.MultiPage(
    // FIX: Use the standard A4 constant for reliable page sizing
    pageFormat: PdfPageFormat.a4,
    build: (context) => [
      // NEW: Decorative Header
      pw.Container(
        height: 50,
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 20),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF00BFA5), // Teal color
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(height: 20),

      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Billify Lite Services', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('123 Billing St, Invoice City, FL 33101'),
          pw.Text('Email: support@billifylite.com'),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Invoice #: ${inv.number}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Date: ${dateFmt.format(inv.date)}'),
          pw.Text('Status: ${inv.paymentStatus}', style: inv.paymentStatus == 'Paid' ? pw.TextStyle(color: PdfColors.green700) : pw.TextStyle(color: PdfColors.orange700)),
        ])
      ]),
      pw.SizedBox(height: 15),

      // Bill To Section
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
        child: pw.Text('Bill To: ${inv.customer}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),

      pw.SizedBox(height: 15),

      // Items Table
      pw.Table.fromTextArray(
        headers: ['Description', 'Qty', 'Rate (₹)', 'Amount (₹)'],
        data: inv.items.map((it) => [it.desc, it.qty.toString(), it.rate.toStringAsFixed(2), (it.qty * it.rate).toStringAsFixed(2)]).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700), // Added const back here for safety
        cellAlignment: pw.Alignment.centerRight,
        columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(1.5)},
        cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
      ),

      pw.SizedBox(height: 15),

      // Totals Summary
      pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 250,
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                    pw.Text('Tax (${inv.tax}%): ₹${taxAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                    pw.Text('Discount: -₹${inv.discount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right),
                    pw.Divider(height: 1, thickness: 1),
                    pw.SizedBox(height: 4),
                    pw.Text('TOTAL DUE: ₹${inv.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ]
              ),
            )
          ]
      ),

      // Footer
      pw.SizedBox(height: 30),
      pw.Center(
        child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
      )
    ],
  ));

  return pdf.save();
}

// --- FLUTTER WIDGETS ---

class BillifyLiteApp extends StatefulWidget {
  const BillifyLiteApp({Key? key}) : super(key: key);

  @override
  State<BillifyLiteApp> createState() => _BillifyLiteAppState();
}

class _BillifyLiteAppState extends State<BillifyLiteApp> {
  ColorScheme get scheme => ColorScheme.fromSeed(seedColor: _primaryColor);
  Color _primaryColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    final settings = Hive.box('settings');
    final int? colorValue = settings.get('primaryColor') as int?;
    if (colorValue != null) _primaryColor = Color(colorValue);
  }

  void _updatePrimary(Color color) {
    setState(() => _primaryColor = color);
    Hive.box('settings').put('primaryColor', color.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billify Lite',
      theme: ThemeData(useMaterial3: true, colorScheme: scheme),
      home: HomeScreen(onColorChange: _updatePrimary, primaryColor: _primaryColor),
      navigatorKey: MyApp.navigatorKey,
    );
  }
}

class HomeScreen extends StatelessWidget {
  final void Function(Color) onColorChange;
  final Color primaryColor;
  const HomeScreen({required this.onColorChange, required this.primaryColor, Key? key}) : super(key: key);

  // NEW: Custom Card for Invoice List
  Widget _invoiceCard(BuildContext context, Invoice inv) {
    final bool isPaid = inv.paymentStatus == 'Paid';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv))),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Background gradient
            gradient: LinearGradient(
              colors: [
                isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(inv.number, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Chip(
                    label: Text(inv.paymentStatus, style: TextStyle(color: isPaid ? Colors.white : Colors.black87)),
                    backgroundColor: isPaid ? Colors.green : Colors.amber.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Customer: ${inv.customer}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${DateFormat('dd MMM yyyy').format(inv.date)}', style: Theme.of(context).textTheme.bodySmall),
                  Text('₹${inv.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: isPaid ? Colors.green.shade800 : Colors.red.shade800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billify Lite')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Invoice'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoiceForm())),
            ),
            const SizedBox(height: 12),
            Expanded(child: ValueListenableBuilder<Box<Invoice>>(
              valueListenable: Hive.box<Invoice>('invoices').listenable(),
              builder: (context, box, _) {
                final invoices = box.values.toList().cast<Invoice>().reversed.toList();
                if (invoices.isEmpty) return const Center(child: Text('No invoices yet. Click "Create Invoice" to start!'));
                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, i) {
                    final inv = invoices[i];
                    return _invoiceCard(context, inv); // Use the attractive card widget
                  },
                );
              },
            )),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('Billify Lite', style: Theme.of(context).textTheme.headlineSmall)),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Theme Color'),
              subtitle: Text('Current: #${primaryColor.value.toRadixString(16).toUpperCase()}'),
              onTap: () => _openColorPicker(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Clear All Invoices'),
              onTap: () async {
                final box = Hive.box<Invoice>('invoices');
                await box.clear();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All invoices cleared')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pick a primary color'),
        content: Wrap(
          spacing: 8,
          children: [
            _colorChip(Colors.teal, dialogContext),
            _colorChip(Colors.blue, dialogContext),
            _colorChip(Colors.deepPurple, dialogContext),
            _colorChip(Colors.orange, dialogContext),
            _colorChip(Colors.green, dialogContext),
            _colorChip(Colors.red, dialogContext),
          ],
        ),
      ),
    );
  }

  Widget _colorChip(Color color, BuildContext dialogContext) => GestureDetector(
    onTap: () {
      onColorChange(color);
      Navigator.of(dialogContext).pop();
    },
    child: Chip(label: Text('#${color.value.toRadixString(16).toUpperCase()}'), backgroundColor: color),
  );
}

class MyApp { static final navigatorKey = GlobalKey<NavigatorState>(); }

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({Key? key}) : super(key: key);

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerCtrl = TextEditingController();
  final List<InvoiceItem> _items = [InvoiceItem(desc: 'Item 1', qty: 1, rate: 100.0)];
  double tax = 0.0;
  double discount = 0.0;

  double get subtotal => _items.fold(0.0, (p, e) => p + e.qty * e.rate);
  double get total => subtotal + subtotal * (tax / 100) - discount;

  @override
  void dispose() {
    _customerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _customerCtrl, decoration: const InputDecoration(labelText: 'Customer Name'), validator: (s) => s == null || s.isEmpty ? 'Enter customer' : null),
              const SizedBox(height: 12),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(children: [
                      TextFormField(initialValue: item.desc, decoration: const InputDecoration(labelText: 'Description'), onChanged: (v) => item.desc = v),
                      Row(children: [
                        Expanded(child: TextFormField(
                          initialValue: item.qty.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty'),
                          onChanged: (v) => setState(() => item.qty = int.tryParse(v) ?? 1),
                          validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Qty must be > 0' : null,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(
                          initialValue: item.rate.toStringAsFixed(2),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Rate (₹)'),
                          onChanged: (v) => setState(() => item.rate = double.tryParse(v) ?? 0),
                          validator: (v) => (double.tryParse(v ?? '') ?? 0.0) < 0.0 ? 'Rate must be >= 0' : null,
                        )),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _items.removeAt(i))),
                      ])
                    ]),
                  ),
                );
              }).toList(),
              TextButton.icon(onPressed: () => setState(() => _items.add(InvoiceItem(desc: 'New Item', qty: 1, rate: 0.0))), icon: const Icon(Icons.add), label: const Text('Add item')),
              const SizedBox(height: 8),
              TextFormField(initialValue: tax.toString(), decoration: const InputDecoration(labelText: 'Tax %'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => setState(() => tax = double.tryParse(v) ?? 0)),
              TextFormField(initialValue: discount.toString(), decoration: const InputDecoration(labelText: 'Discount (₹)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => setState(() => discount = double.tryParse(v) ?? 0)),
              const SizedBox(height: 12),
              // Use ValueListenableBuilder just to show the dynamic subtotal/total
              ValueListenableBuilder(
                  valueListenable: ValueNotifier(subtotal + total), // Arbitrary notifier to rebuild on state change
                  builder: (context, _, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
                        Text('Tax: ₹${(subtotal * (tax / 100)).toStringAsFixed(2)}'),
                        Text('Discount: ₹${discount.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        Text('Total: ₹${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    );
                  }
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate & Save'),
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if item list is empty or if all rates/quantities are zero
    if (_items.isEmpty || _items.every((e) => e.qty == 0 || e.rate == 0.0)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item with a valid quantity and rate.')));
      return;
    }

    final id = const Uuid().v4();
    final number = 'BL-${DateTime.now().millisecondsSinceEpoch}';
    final inv = Invoice(
      id: id,
      number: number,
      date: DateTime.now(),
      customer: _customerCtrl.text,
      items: List.from(_items),
      tax: tax,
      discount: discount,
      total: total,
      paymentStatus: 'Pending',
    );

    // Save to Hive
    final box = Hive.box<Invoice>('invoices');
    await box.put(inv.id, inv);

    // Generate PDF bytes using the reusable function
    final bytes = await generateInvoicePdf(inv);

    // Open PDF preview / share
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfPreviewScreen(bytes: bytes, invoice: inv)));
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final Invoice invoice;
  const PdfPreviewScreen({required this.bytes, required this.invoice, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice ${invoice.number}')),
      body: PdfPreview(build: (format) => bytes, allowPrinting: true, allowSharing: true),
      floatingActionButton: ValueListenableBuilder<Box<Invoice>>(
        valueListenable: Hive.box<Invoice>('invoices').listenable(keys: [invoice.id]),
        builder: (context, box, child) {
          final currentInv = box.get(invoice.id) ?? invoice;
          final bool isPaid = currentInv.paymentStatus == 'Paid';

          return FloatingActionButton.extended(
            onPressed: () async {
              currentInv.paymentStatus = isPaid ? 'Pending' : 'Paid';
              await box.put(currentInv.id, currentInv);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked ${currentInv.paymentStatus}')));
            },
            icon: Icon(isPaid ? Icons.cached : Icons.payment),
            label: Text(isPaid ? 'Mark Pending' : 'Mark Paid'),
            backgroundColor: isPaid ? Colors.orange : Colors.green,
          );
        },
      ),
    );
  }
}

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({required this.invoice, Key? key}) : super(key: key);

  // NEW: Custom Card for Summary Totals
  Widget _totalSummaryCard(BuildContext context, Invoice inv) {
    final subtotal = inv.items.fold(0.0, (p, e) => p + e.qty * e.rate);
    final taxAmount = subtotal * (inv.tax / 100);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow('Subtotal', subtotal),
            _summaryRow('Tax (${inv.tax}%)', taxAmount),
            _summaryRow('Discount', inv.discount, isDiscount: true),
            const Divider(),
            _summaryRow('TOTAL DUE', inv.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null),
          Text(
            '₹${(isDiscount ? -amount : amount).toStringAsFixed(2)}',
            style: isTotal ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange) : null,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Invoice>>(
      valueListenable: Hive.box<Invoice>('invoices').listenable(keys: [invoice.id]),
      builder: (context, box, child) {
        final currentInv = box.get(invoice.id) ?? invoice;

        return Scaffold(
          appBar: AppBar(title: Text(currentInv.number)),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Customer: ${currentInv.customer}', style: Theme.of(context).textTheme.titleMedium),
              Text('Date: ${DateFormat('dd MMM yyyy').format(currentInv.date)}'),
              Row(
                children: [
                  const Text('Status: '),
                  Chip(
                    label: Text(currentInv.paymentStatus),
                    backgroundColor: currentInv.paymentStatus == 'Paid' ? Colors.green.shade100 : Colors.orange.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Item List
              Text('Items Included:', style: Theme.of(context).textTheme.titleSmall),
              Expanded(child: ListView(
                  children: currentInv.items.map((it) => ListTile(
                      title: Text(it.desc),
                      subtitle: Text('${it.qty} x ₹${it.rate.toStringAsFixed(2)}'),
                      trailing: Text('₹${(it.qty*it.rate).toStringAsFixed(2)}'))
                  ).toList()
              )),

              // NEW: Total Summary Card
              _totalSummaryCard(context, currentInv),

              const SizedBox(height: 12),

              Row(children: [
                ElevatedButton.icon(
                    onPressed: () async {
                      final bytes = await generateInvoicePdf(currentInv);
                      await Printing.layoutPdf(onLayout: (_) async => bytes);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print')
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                    onPressed: () async {
                      final bytes = await generateInvoicePdf(currentInv);
                      await Printing.sharePdf(bytes: bytes, filename: '${currentInv.number}.pdf');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share')
                ),
              ])
            ]),
          ),
        );
      },
    );
  }
}