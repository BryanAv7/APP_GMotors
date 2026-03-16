import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/RegistroDetalleDTO.dart';
import '../models/DetalleFacturaDTO.dart';

class PdfFacturaService {
  // ── Colores corporativos ──
  static const _rojo       = PdfColor.fromInt(0xFFCC0000);
  static const _rojoClaro  = PdfColor.fromInt(0xFFFFF0F0);
  static const _grisOscuro = PdfColor.fromInt(0xFF2C2C2C);
  static const _grisMedio  = PdfColor.fromInt(0xFF888888);
  static const _grisLinea  = PdfColor.fromInt(0xFFE0E0E0);

  static Future<void> generarEImprimir({
    required RegistroDetalleDTO registro,
    required List<DetalleFacturaDTO> detalles,
  }) async {
    final pdf = pw.Document();

    // ── Cargar logo desde assets ──
    final logoBytes = await rootBundle.load('assets/images/logoMotors.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // ── Fecha y hora de impresión en tiempo real ──
    final ahora = DateTime.now();
    final fechaImpresion =
        '${ahora.day.toString().padLeft(2, '0')}/'
        '${ahora.month.toString().padLeft(2, '0')}/'
        '${ahora.year}  '
        '${ahora.hour.toString().padLeft(2, '0')}:'
        '${ahora.minute.toString().padLeft(2, '0')}:'
        '${ahora.second.toString().padLeft(2, '0')}';

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
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // ── Logo de la empresa ──
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
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'FACTURA',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _grisMedio,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        '#${registro.idFactura}',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: _grisOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Línea roja divisoria ──
              pw.SizedBox(height: 10),
              pw.Container(height: 2, color: _rojo),
              pw.SizedBox(height: 20),

              // ── INFO CLIENTE, MOTO, PLACA Y SERVICIO ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildBloque(
                      titulo: 'CLIENTE',
                      filas: [registro.nombreCliente ?? 'N/A'],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildBloque(
                      titulo: 'VEHÍCULO',
                      filas: ['${registro.marcaMoto ?? ''} ${registro.modeloMoto ?? ''}'.trim()],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildBloque(
                      titulo: 'PLACA',
                      filas: [registro.placaMoto ?? 'N/A'],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildBloque(
                      titulo: 'SERVICIO',
                      filas: [registro.tipoMantenimiento ?? 'N/A'],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ── TABLA: cabecera ──
              pw.Container(
                color: _rojo,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'DESCRIPCIÓN/PRODUCTOS',
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

              // ── TABLA: filas alternadas ──
              ...detalles.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final esPar = i % 2 == 0;
                return pw.Container(
                  color: esPar ? PdfColors.white : _rojoClaro,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          d.descripcion,
                          style: const pw.TextStyle(fontSize: 9, color: _grisOscuro),
                        ),
                      ),
                      pw.SizedBox(
                        width: 50,
                        child: pw.Text(
                          '${d.cantidad}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9, color: _grisOscuro),
                        ),
                      ),
                      pw.SizedBox(
                        width: 70,
                        child: pw.Text(
                          '\$${d.subtotal.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9, color: _grisOscuro),
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
                      '\$${registro.costoTotal?.toStringAsFixed(2) ?? '0.00'}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _rojo,
                      ),
                    ),
                  ],
                ),
              ),

              // ── OBSERVACIONES (si existen) ──
              if (registro.descripcion != null && registro.descripcion!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Borde rojo izquierdo
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
                            registro.descripcion!,
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

    // ── Genera bytes y abre el menú de compartir del sistema ──
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Factura_${registro.idFactura}_${registro.nombreCliente}.pdf',
    );
  }

  // ── Bloque minimalista: título en rojo + líneas de valor ──
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