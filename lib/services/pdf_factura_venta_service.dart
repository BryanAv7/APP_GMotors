import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/venta_listado_model.dart';
import '../models/detalle_ui.dart';

class PdfVentaService {
  // ── Colores corporativos ──
  static const _rojo = PdfColor.fromInt(0xFFCC0000);
  static const _rojoClaro = PdfColor.fromInt(0xFFFFF0F0);
  static const _grisOscuro = PdfColor.fromInt(0xFF2C2C2C);
  static const _grisMedio = PdfColor.fromInt(0xFF888888);
  static const _grisLinea = PdfColor.fromInt(0xFFE0E0E0);

  static Future<void> generarEImprimir({
    required VentaListadoModel venta,
    required List<DetalleUI> productos,
  }) async {
    final pdf = pw.Document();

    // ── Logo ──
    final logoBytes = await rootBundle.load('assets/images/logoMotors.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // ── Fechas ──
    final fe = venta.fechaEmision;
    final fechaEmision =
        '${fe.day.toString().padLeft(2, '0')}/'
        '${fe.month.toString().padLeft(2, '0')}/'
        '${fe.year}';

    final ahora = DateTime.now();
    final fechaImpresion =
        '${ahora.day.toString().padLeft(2, '0')}/'
        '${ahora.month.toString().padLeft(2, '0')}/'
        '${ahora.year}  '
        '${ahora.hour.toString().padLeft(2, '0')}:'
        '${ahora.minute.toString().padLeft(2, '0')}:'
        '${ahora.second.toString().padLeft(2, '0')}';

    // ── Total desde los productos editados ──
    final double totalCalculado =
    productos.fold(0, (s, p) => s + p.subtotal);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // ── ENCABEZADO ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(logoImage, width: 40, height: 40),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'GORILA-MOTOS',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: _rojo,
                              letterSpacing: 2,
                            ),
                          ),
                          pw.Text(
                            'Taller de Reparación de Motocicletas',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: _grisMedio,
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
                        'CONSUMIDOR FINAL',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _grisMedio,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        '#${venta.idVenta}',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: _grisOscuro,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Fecha: $fechaEmision',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _grisMedio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Línea roja ──
              pw.SizedBox(height: 10),
              pw.Container(height: 2, color: _rojo),
              pw.SizedBox(height: 20),

              // ── INFO CLIENTE ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 90,
                    child: _buildBloque(
                      titulo: 'CLIENTE',
                      filas: [venta.nombreCliente],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(
                    width: 90,
                    child: _buildBloque(
                      titulo: 'CÉDULA',
                      filas: [venta.cedulaCliente],
                    ),
                  ),
                  if (venta.telefonoCliente != null &&
                      venta.telefonoCliente!.isNotEmpty) ...[
                    pw.SizedBox(width: 8),
                    pw.SizedBox(
                      width: 90,
                      child: _buildBloque(
                        titulo: 'TELÉFONO',
                        filas: [venta.telefonoCliente!],
                      ),
                    ),
                  ],
                  if (venta.correoCliente != null &&
                      venta.correoCliente!.isNotEmpty) ...[
                    pw.SizedBox(width: 8),
                    pw.SizedBox(
                      width: 120,
                      child: _buildBloque(
                        titulo: 'CORREO',
                        filas: [venta.correoCliente!],
                      ),
                    ),
                  ],
                  if (venta.direccionCliente != null &&
                      venta.direccionCliente!.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.SizedBox(
                    width: 90,
                      child: _buildBloque(
                      titulo: 'DIRECCIÓN',
                      filas: [venta.direccionCliente!],
                    ),
                    ),
                  ],
                ],
              ),


              pw.SizedBox(height: 24),

              // ── TABLA cabecera ──
              pw.Container(
                color: _rojo,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'DESCRIPCIÓN / PRODUCTO',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 50,
                      child: pw.Text(
                        'CANT.',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 70,
                      child: pw.Text(
                        'SUBTOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── TABLA filas ──
              ...productos.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final esPar = i % 2 == 0;
                return pw.Container(
                  color: esPar ? PdfColors.white : _rojoClaro,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          d.nombre,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: _grisOscuro,
                          ),
                        ),
                      ),
                      pw.SizedBox(
                        width: 50,
                        child: pw.Text(
                          '${d.cantidad}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: _grisOscuro,
                          ),
                        ),
                      ),
                      pw.SizedBox(
                        width: 70,
                        child: pw.Text(
                          '\$${d.subtotal.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: _grisOscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Línea cierre tabla
              pw.Container(height: 1, color: _grisLinea),
              pw.SizedBox(height: 14),

              // ── TOTAL ──
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'TOTAL  ',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _grisMedio,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.Text(
                      '\$${totalCalculado.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _rojo,
                      ),
                    ),
                  ],
                ),
              ),

              // ── OBSERVACIONES ──
              if (venta.observaciones != null &&
                  venta.observaciones!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 3, height: 36, color: _rojo),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'OBSERVACIONES',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _rojo,
                              letterSpacing: 1,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            venta.observaciones!,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: _grisOscuro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              pw.Spacer(),

              // ── PIE ──
              pw.Container(height: 1, color: _grisLinea),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Impreso el: $fechaImpresion',
                    style: const pw.TextStyle(fontSize: 8, color: _grisMedio),
                  ),
                  pw.Text(
                    'Gracias por confiar en Gorila-Motos',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _rojo,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'ConsumidorFinal_Gmotos${venta.idVenta}.pdf',
    );
  }

  static pw.Widget _buildBloque({
    required String titulo,
    required List<String> filas,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _rojo,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 4),
        ...filas.map(
              (f) => pw.Text(
            f,
            style: const pw.TextStyle(fontSize: 10, color: _grisOscuro),
          ),
        ),
      ],
    );
  }
}