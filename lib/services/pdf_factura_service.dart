import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/RegistroDetalleDTO.dart';
import '../models/DetalleFacturaDTO.dart';
import '../services/productos_service.dart';

class PdfFacturaService {
  // ── Colores corporativos ──
  static const _rojo = PdfColor.fromInt(0xFFCC0000);
  static const _rojoClaro = PdfColor.fromInt(0xFFFFF0F0);
  static const _grisOscuro = PdfColor.fromInt(0xFF2C2C2C);
  static const _grisMedio = PdfColor.fromInt(0xFF888888);
  static const _grisLinea = PdfColor.fromInt(0xFFE0E0E0);

  static Future<void> generarEImprimir({
    required RegistroDetalleDTO registro,
    required List<DetalleFacturaDTO> detalles,
    Map<int, String>? mapaNombresProductos,
  }) async {
    // ── Si no llegó el mapa (o llegó vacío), lo cargamos aquí ──
    Map<int, String> mapa = mapaNombresProductos ?? {};
    if (mapa.isEmpty) {
      try {
        final productos = await ProductoService.listarProductos();
        mapa = {
          for (final p in productos)
            if (p.idProducto != null) p.idProducto!: (p.nombre ?? ''),
        };
      } catch (_) {
        mapa = {};
      }
    }

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
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),

        // ── ENCABEZADO (se repite en cada página) ──
        header: (pw.Context context) {
          return pw.Column(
            children: [
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
                      pw.SizedBox(height: 8),
                      _buildEstadoBadge(registro.estado),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(height: 2, color: _rojo),
              pw.SizedBox(height: 16),
            ],
          );
        },

        // ── PIE (se repite en cada página) ──
        footer: (pw.Context context) {
          return pw.Column(
            children: [
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
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: _grisMedio),
                  ),
                ],
              ),
            ],
          );
        },

        // ── CONTENIDO ──
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // ───────────────────── PRIMERA FILA ─────────────────────
          widgets.add(
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
                    titulo: 'CÉDULA/RUC',
                    filas: [registro.cedulaCliente ?? 'N/A'],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: _buildBloque(
                    titulo: 'DIRECCIÓN',
                    filas: [registro.direccionCliente ?? 'N/A'],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: _buildBloque(
                    titulo: 'TELÉFONO',
                    filas: [registro.telefonoCliente ?? 'N/A'],
                  ),
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 16));

          // ───────────────────── SEGUNDA FILA ─────────────────────
          widgets.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildBloque(
                    titulo: 'CORREO',
                    filas: [registro.correoCliente ?? 'N/A'],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: _buildBloque(
                    titulo: 'VEHÍCULO',
                    filas: [
                      '${registro.marcaMoto ?? ''} ${registro.modeloMoto ?? ''}'
                          .trim(),
                    ],
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
                    titulo: 'KILOMETRAJE',
                    filas: [
                      registro.kilometraje != null
                          ? '${registro.kilometraje} km'
                          : 'N/A',
                    ],
                  ),
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 16));

          // ───────────────────── TERCERA FILA ─────────────────────
          widgets.add(
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildBloque(
                    titulo: 'SERVICIO',
                    filas: [registro.tipoMantenimiento ?? 'N/A'],
                  ),
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 24));

          // ── TABLA: cabecera ──
          widgets.add(_buildCabeceraTabla());

          // ── TABLA: filas (cada una es un widget independiente) ──
          for (int i = 0; i < detalles.length; i++) {
            widgets.add(_buildFila(detalles[i], i, mapa));
          }

          // Línea cierre tabla
          widgets.add(pw.Container(height: 1, color: _grisLinea));
          widgets.add(pw.SizedBox(height: 14));

          // ── TOTAL ──
          widgets.add(
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
          );

          // ── OBSERVACIONES (si existen) ──
          if (registro.descripcion != null &&
              registro.descripcion!.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(
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
            );
          }

          return widgets;
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

  // ── Resuelve el nombre del producto: mapa → descripción → Producto #id ──
  static String _resolverNombre(
      DetalleFacturaDTO d,
      Map<int, String> mapa,
      ) {
    String nombre = '';

    if (d.idProducto != null) {
      nombre = mapa[d.idProducto] ?? '';
    }
    if (nombre.trim().isEmpty) {
      nombre = d.descripcion;
    }
    if (nombre.trim().isEmpty) {
      nombre = 'Producto #${d.idProducto ?? '?'}';
    }
    return _limpiarEtiquetas(nombre);
  }

  // Metodo auxiliar para limpiar etiquetas

  static String _limpiarEtiquetas(String texto) {
    return texto
        .replaceAll(RegExp(r'\s*\[\s*MO\s*\]\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  // ── Cabecera de la tabla ──
  static pw.Widget _buildCabeceraTabla() {
    pw.Widget celda(String t, pw.TextAlign align) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        t,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 1,
        ),
      ),
    );

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(5),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _rojo),
          children: [
            celda('DESCRIPCIÓN/PRODUCTOS', pw.TextAlign.left),
            celda('CANT.', pw.TextAlign.center),
            celda('SUBTOTAL', pw.TextAlign.right),
          ],
        ),
      ],
    );
  }

  // ── Fila de la tabla ──
  static pw.Widget _buildFila(
      DetalleFacturaDTO d,
      int i,
      Map<int, String> mapa,
      ) {
    final esPar = i % 2 == 0;

    pw.Widget celda(String t, pw.TextAlign align) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        t,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 9, color: _grisOscuro),
      ),
    );

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(5),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: esPar ? PdfColors.white : _rojoClaro,
          ),
          children: [
            celda(_resolverNombre(d, mapa), pw.TextAlign.left),
            celda('${d.cantidad}', pw.TextAlign.center),
            celda('\$${d.subtotal.toStringAsFixed(2)}', pw.TextAlign.right),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildEstadoBadge(int? estado) {
    PdfColor color;
    String texto;

    switch (estado) {
      case 1:
        color = PdfColors.orange700;
        texto = 'EN PROCESO';
        break;

      case 2:
        color = PdfColors.green700;
        texto = 'FINALIZADO';
        break;

      default:
        return pw.SizedBox();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
          letterSpacing: 1,
        ),
      ),
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