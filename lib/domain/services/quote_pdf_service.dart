import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/calculator_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../models/calculator_models.dart';

class QuotePdfService {
  Future<Uint8List> generate(QuoteData data, CurrencySpec currency) async {
    final doc = pw.Document();
    final accent = PdfColor.fromInt(CalculatorConstants.accentColor);

    pw.MemoryImage? logoImage;
    if (data.companyLogoBytes != null && data.companyLogoBytes!.isNotEmpty) {
      logoImage = pw.MemoryImage(Uint8List.fromList(data.companyLogoBytes!));
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 80,
                          height: 40,
                          margin: const pw.EdgeInsets.only(right: 12),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            data.companyName.isEmpty
                                ? 'SUA EMPRESA'
                                : data.companyName,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          if (data.companySlogan.isNotEmpty)
                            pw.Text(
                              data.companySlogan,
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ORÇAMENTO #${data.quoteNumber}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Data: ${data.date}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DESTINATÁRIO',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey500,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          data.clientName.isEmpty
                              ? 'Nome do Cliente'
                              : data.clientName,
                        ),
                        pw.Text(
                          data.contact.isEmpty ? 'Contato' : data.contact,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EMITIDO POR',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey500,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          data.companyName.isEmpty
                              ? 'Sua Empresa'
                              : data.companyName,
                        ),
                        if (data.companyEmail.isNotEmpty)
                          pw.Text(
                            data.companyEmail,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (data.companyPhone.isNotEmpty)
                          pw.Text(
                            data.companyPhone,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                    children: [
                      _headerCell('ITEM'),
                      _headerCell('QTD', align: pw.TextAlign.center),
                      _headerCell('PREÇO UNIT.', align: pw.TextAlign.right),
                      _headerCell('TOTAL', align: pw.TextAlign.right),
                    ],
                  ),
                  ...data.items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.name,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (item.description.isNotEmpty)
                                pw.Text(
                                  item.description,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey500,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Text(
                            item.quantity.toString().padLeft(2, '0'),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Text(
                            CurrencyFormatter.format(item.unitPrice, currency),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Text(
                            CurrencyFormatter.format(item.total, currency),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _totalRow(
                        'Subtotal:',
                        CurrencyFormatter.format(data.subtotal, currency),
                      ),
                      _totalRow(
                        'Frete:',
                        CurrencyFormatter.format(data.shippingCost, currency),
                      ),
                      _totalRow(
                        'Desconto (${data.discountPercent.toStringAsFixed(0)}%):',
                        '- ${CurrencyFormatter.format(data.discountAmount, currency)}',
                        color: PdfColors.green700,
                      ),
                      pw.Divider(color: PdfColors.grey300),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL:',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            CurrencyFormatter.format(data.total, currency),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (data.stockMovements.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'ESTOQUE UTILIZADO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...data.stockMovements.map(
                  (m) => pw.Text(
                    '• ${m.itemName}: -${m.quantityUsed} ${m.unit} (saldo ${m.quantityAfter} ${m.unit})',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.green900,
                    ),
                  ),
                ),
              ],
              if (data.observations.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'OBSERVAÇÕES',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.observations,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey500,
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: color ?? PdfColors.grey600,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
