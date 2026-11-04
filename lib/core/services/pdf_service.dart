import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/models/shop_settings.dart';

class PdfService {
  static final PdfService instance = PdfService._internal();
  PdfService._internal();

  /// Generates a clean A4 Wholesale Invoice PDF
  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required ShopSettings settings,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/branding/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.shopName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('0F172A'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      settings.address,
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('475569')),
                    ),
                    pw.Text(
                      'Phone / WhatsApp: ${settings.phone}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('475569')),
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.Image(logoImage),
                  ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColor.fromHex('CBD5E1')),
            pw.SizedBox(height: 8),

            // Invoice Details & Bill To
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO (DEALER):',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('64748B')),
                    ),
                    pw.Text(
                      invoice.customerName,
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0F172A')),
                    ),
                    if (invoice.customerPhone != null)
                      pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0D9488')),
                    ),
                    pw.Text('Invoice #: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Date: ${invoice.date}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Status: ${invoice.paymentStatus.name.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.8),
                1: const pw.FlexColumnWidth(3.5),
                2: const pw.FlexColumnWidth(2.0),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.8),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
                  children: [
                    _th('#'),
                    _th('Item Description'),
                    _th('Pack / Total Pcs'),
                    _th('Rate (PKR)'),
                    _th('Disc'),
                    _th('Total (PKR)'),
                  ],
                ),
                // Item Rows
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _td('$idx', align: pw.TextAlign.center),
                      _td('${item.productName}\n[SKU: ${item.sku}] ${item.colorSpec != null ? "(${item.colorSpec})" : ""}'),
                      _td('${item.packQty} ${item.packUnitShort} (${item.totalPieces} pcs)', align: pw.TextAlign.center),
                      _td(item.unitPrice.format(includeSymbol: false), align: pw.TextAlign.right),
                      _td(item.lineDiscountPaisa > 0 ? item.lineDiscount.format(includeSymbol: false) : '-', align: pw.TextAlign.right),
                      _td(item.netTotal.format(includeSymbol: false), align: pw.TextAlign.right),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 16),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal:', invoice.subtotal.format()),
                      if (invoice.discountPaisa > 0)
                        _summaryRow('Discount:', '- ${invoice.discount.format()}'),
                      if (invoice.taxPaisa > 0)
                        _summaryRow('Tax:', invoice.tax.format()),
                      pw.Divider(thickness: 1, color: PdfColor.fromHex('CBD5E1')),
                      _summaryRow('Grand Total:', invoice.grandTotal.format(), isBold: true),
                      _summaryRow('Paid Amount:', invoice.paid.format()),
                      pw.Divider(thickness: 1, color: PdfColor.fromHex('CBD5E1')),
                      _summaryRow('Remaining Balance:', invoice.due.format(), isBold: true, color: PdfColor.fromHex('EF4444')),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Footer Note
            pw.Divider(thickness: 0.5, color: PdfColor.fromHex('CBD5E1')),
            pw.SizedBox(height: 4),
            pw.Text(
              settings.invoiceFooter,
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex('64748B')),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Powered by Mobile Wholesale ERP • On-Device Offline Engine',
                style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('94A3B8')),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates Party Ledger PDF Statement
  Future<Uint8List> generatePartyLedgerPdf({
    required Party party,
    required List<PartyLedgerEntry> entries,
    required ShopSettings settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.shopName,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0F172A')),
                    ),
                    pw.Text('Phone: ${settings.phone}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ACCOUNT LEDGER STATEMENT',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0D9488')),
                    ),
                    pw.Text('Date: ${DateTime.now().toIso8601String().split('T').first}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColor.fromHex('CBD5E1')),
            pw.SizedBox(height: 8),

            // Party Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Party: ${party.name}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Type: ${party.type == PartyType.customer ? "Customer (Dealer)" : "Supplier"}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Phone: ${party.phone} • City: ${party.city ?? "N/A"}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      party.isCustomer ? 'Current Outstanding Due:' : 'Current Payable to Supplier:',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      party.currentBalance.format(),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: party.hasOutstandingDue ? PdfColor.fromHex('EF4444') : PdfColor.fromHex('10B981'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Table of entries
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(1.4),
                5: const pw.FlexColumnWidth(1.6),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
                  children: [
                    _th('Date'),
                    _th('Type'),
                    _th('Ref # / Notes'),
                    _th('Debit (PKR)'),
                    _th('Credit (PKR)'),
                    _th('Balance (PKR)'),
                  ],
                ),
                ...entries.map((entry) {
                  return pw.TableRow(
                    children: [
                      _td(entry.date, align: pw.TextAlign.center),
                      _td(entry.type.toUpperCase(), align: pw.TextAlign.center),
                      _td(entry.refNumber ?? entry.notes ?? '-'),
                      _td(entry.debitPaisa > 0 ? entry.debit.format(includeSymbol: false) : '-', align: pw.TextAlign.right),
                      _td(entry.creditPaisa > 0 ? entry.credit.format(includeSymbol: false) : '-', align: pw.TextAlign.right),
                      _td(entry.runningBalance.format(includeSymbol: false), align: pw.TextAlign.right),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('334155')),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Print or show Android print dialog
  Future<void> printInvoice(Invoice invoice, ShopSettings settings) async {
    final pdfBytes = await generateInvoicePdf(invoice: invoice, settings: settings);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  /// Share PDF via Android Share Sheet
  Future<void> shareInvoicePdf(Invoice invoice, ShopSettings settings) async {
    final pdfBytes = await generateInvoicePdf(invoice: invoice, settings: settings);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  /// Share Ledger PDF
  Future<void> sharePartyLedgerPdf(Party party, List<PartyLedgerEntry> entries, ShopSettings settings) async {
    final pdfBytes = await generatePartyLedgerPdf(party: party, entries: entries, settings: settings);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Ledger_${party.name.replaceAll(" ", "_")}.pdf',
    );
  }
}

