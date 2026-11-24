import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

import '../models/RegistroDetalleDTO.dart';
import '../models/DetalleFacturaDTO.dart';
import '../services/registros_service.dart';

class PdfHistorialMantenimientosService {
  // =====================================================
  // COLORES CORPORATIVOS
  // =====================================================

  static const _rojo = PdfColor.fromInt(0xFFCC0000);
  static const _rojoClaro = PdfColor.fromInt(0xFFFFF0F0);
  static const _grisOscuro = PdfColor.fromInt(0xFF2C2C2C);
  static const _grisMedio = PdfColor.fromInt(0xFF888888);
  static const _grisLinea = PdfColor.fromInt(0xFFE0E0E0);
  static const _verde = PdfColor.fromInt(0xFF28A745);
  static const _azul = PdfColor.fromInt(0xFF007BFF);
  static const _grisHeader = PdfColor.fromInt(0xFFF2F2F2);
  static const _verdeOpaco30 = PdfColor.fromInt(0x4D28A745);

  // =====================================================
  // GENERAR HISTORIAL
  // =====================================================

  static Future<void> generarEImprimir({
    required List<RegistroDetalleDTO> historial,
    required String nombreCliente,
    Map<int, String>? mapaNombresProductos,
  }) async {
    if (historial.isEmpty) {
      throw Exception('No existen mantenimientos para imprimir');
    }

    final pdf = pw.Document();

    // =====================================================
    // LOGO
    // =====================================================

    final logoBytes = await rootBundle.load(
      'assets/images/logoMotors.png',
    );
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // =====================================================
    // FECHA DE IMPRESIÓN
    // =====================================================

    final ahora = DateTime.now();
    final fechaImpresion =
        '${ahora.day.toString().padLeft(2, '0')}/'
        '${ahora.month.toString().padLeft(2, '0')}/'
        '${ahora.year}  '
        '${ahora.hour.toString().padLeft(2, '0')}:'
        '${ahora.minute.toString().padLeft(2, '0')}';

    // =====================================================
    // TOTAL GENERAL
    // =====================================================

    double totalGeneral = 0;
    for (final registro in historial) {
      totalGeneral += registro.costoTotal ?? 0;
    }

    // =====================================================
    // CARGAR DETALLES DE FACTURAS
    // =====================================================

    final Map<int, List<DetalleFacturaDTO>> detallesFacturas = {};

    try {
      for (final registro in historial) {
        final int? idFactura = registro.idFactura;
        if (idFactura != null) {
          try {
            final List<DetalleFacturaDTO> detalles =
            await RegistrosService.obtenerDetallesFactura(idFactura);
            detallesFacturas[idFactura] = _deduplicarDetalles(detalles);
          } catch (_) {
            detallesFacturas[idFactura] = [];
          }
        }
      }
    } catch (_) {}

    // =====================================================
    // PDF MULTIPÁGINA
    // =====================================================

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(
          horizontal: 36,
          vertical: 32,
        ),

        header: (context) {
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
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: _rojo,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.Text(
                            'Taller de Reparación de Motocicletas',
                            style: const pw.TextStyle(
                              fontSize: 8,
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
                        'HISTORIAL DE MANTENIMIENTOS',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _grisOscuro,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.Text(
                        'Fecha de impresión: $fechaImpresion',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: _grisMedio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 2, color: _rojo),
              pw.SizedBox(height: 12),
            ],
          );
        },

        footer: (context) {
          return pw.Column(
            children: [
              pw.Container(height: 1, color: _grisLinea),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GORILA-MOTOS - Telf: 0980834367',
                    style: const pw.TextStyle(fontSize: 7, color: _grisMedio),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7, color: _grisMedio),
                  ),
                ],
              ),
            ],
          );
        },

        build: (context) {
          final List<pw.Widget> widgets = [];

          // =================================================
          // DATOS DEL CLIENTE
          // =================================================
          widgets.add(_buildCliente(nombreCliente, historial));
          widgets.add(pw.SizedBox(height: 14));

          // =================================================
          // RESUMEN
          // =================================================
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'RESUMEN',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _rojo,
                  letterSpacing: 1,
                ),
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 8));

          widgets.add(_buildResumen(historial.length, totalGeneral));

          widgets.add(pw.SizedBox(height: 6));

          // =================================================
          // TÍTULO "DETALLES DE MANTENIMIENTOS"
          // =================================================
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'DETALLES DE MANTENIMIENTOS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _rojo,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 12));

          // =================================================
          // CADA MANTENIMIENTO
          // =================================================
          for (int i = 0; i < historial.length; i++) {
            final registro = historial[i];
            final int? idFactura = registro.idFactura;
            final List<DetalleFacturaDTO> detalles =
            idFactura != null ? (detallesFacturas[idFactura] ?? []) : [];

            widgets.add(
              _buildMantenimientoCard(
                index: i,
                registro: registro,
                detalles: detalles,
                mapaNombresProductos: mapaNombresProductos,
              ),
            );
            if (i < historial.length - 1) {
              widgets.add(pw.SizedBox(height: 14));
            }
          }

          widgets.add(pw.SizedBox(height: 18));

          // =================================================
          // TOTAL GENERAL
          // =================================================
          widgets.add(_buildTotalGeneral(totalGeneral));

          return widgets;
        },
      ),
    );

    // =====================================================
    // GUARDAR Y COMPARTIR
    // =====================================================

    final bytes = await pdf.save();
    final nombreArchivo = _limpiarNombreArchivo(nombreCliente);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Historial_Mantenimientos_$nombreArchivo.pdf',
    );
  }

  // =====================================================
  // DEDUPLICAR DETALLES
  // =====================================================

  static List<DetalleFacturaDTO> _deduplicarDetalles(
      List<DetalleFacturaDTO> detalles) {
    final Set<String> vistos = {};
    return detalles.where((d) {
      final clave = '${d.descripcion}_${d.precioUnitario}_${d.cantidad}';
      return vistos.add(clave);
    }).toList();
  }

  // =====================================================
  // CLIENTE
  // =====================================================

  static pw.Widget _buildCliente(
      String nombreCliente, List<RegistroDetalleDTO> historial) {
    final primer = historial.first;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _rojoClaro,
        border: pw.Border(left: pw.BorderSide(color: _rojo, width: 3)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildDato('Cliente', nombreCliente.isNotEmpty ? nombreCliente : 'N/A'),
          _buildDato('Cédula/RUC', primer.cedulaCliente ?? 'N/A'),
          _buildDato('Correo', primer.correoCliente ?? 'N/A'),
          _buildDato('Dirección', primer.direccionCliente ?? 'N/A'),
          _buildDato('Teléfono', primer.telefonoCliente ?? 'N/A'),
        ],
      ),
    );
  }

  static pw.Widget _buildDato(String titulo, String valor) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            titulo,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: _rojo,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            valor,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10, color: _grisOscuro),
            maxLines: 2,
          ),
        ],
      ),
    );
  }


  // =====================================================
  // RESUMEN
  // =====================================================

  static pw.Widget _buildResumen(int cantidad, double total) {
    return pw.Row(
      children: [
        _buildResumenBox('TOTAL DE MANTENIMIENTOS', '$cantidad'),
        pw.SizedBox(width: 12),
        _buildResumenBox('TOTAL GLOBAL', '\$${total.toStringAsFixed(2)}'),
      ],
    );
  }

  static pw.Widget _buildResumenBox(String titulo, String valor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _grisLinea),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _rojo,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: _grisOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // TARJETA DE MANTENIMIENTO
  // =====================================================

  static pw.Widget _buildMantenimientoCard({
    required int index,
    required RegistroDetalleDTO registro,
    required List<DetalleFacturaDTO> detalles,
    Map<int, String>? mapaNombresProductos,
  }) {
    final bool tieneFactura = registro.idFactura != null && detalles.isNotEmpty;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grisLinea, width: 0.8),
        borderRadius: pw.BorderRadius.circular(5),
        color: index % 2 == 0 ? PdfColors.white : _grisHeader,
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // =============================================
          // Cabecera
          // =============================================
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    alignment: pw.Alignment.center,
                    decoration: const pw.BoxDecoration(
                      color: _rojo,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Text(
                      '${index + 1}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Tipo de Mantenimiento: ',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _grisOscuro,
                    ),
                  ),
                  pw.Text(
                    registro.tipoMantenimiento ?? 'Sin tipo',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.normal,
                      color: _azul,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 6),

          // =============================================
          // Datos principales
          // =============================================
          pw.Row(
            children: [
              _campoInfo('Fecha', _formatearFecha(registro.fecha)),
              pw.SizedBox(width: 14),
              _campoInfo('Vehículo',
                  '${registro.marcaMoto ?? ''} ${registro.modeloMoto ?? ''}'.trim()),
              pw.SizedBox(width: 14),
              _campoInfo('Placa', registro.placaMoto ?? 'N/A'),
              pw.SizedBox(width: 14),
              if (registro.kilometraje != null)
                _campoInfo('KM', '${registro.kilometraje}'),
            ],
          ),

          // =============================================
          // Detalles de factura
          // =============================================
          if (tieneFactura) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: _verdeOpaco30, width: 0.5),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'DETALLE DE FACTURA',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _verde,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Text(
                        'Factura #${registro.idFactura}',
                        style: pw.TextStyle(fontSize: 7, color: _grisMedio),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  _buildTablaDetalles(detalles, mapaNombresProductos),
                ],
              ),
            ),
          ],

          // =============================================
          // Recuadro de Subtotal
          // =============================================
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 140,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: _rojo, width: 1),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _grisOscuro,
                    ),
                  ),
                  pw.Text(
                    '\$${(registro.costoTotal ?? 0).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _verde,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // Campo de información
  // =============================================
  static pw.Widget _campoInfo(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _grisOscuro,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8,
            color: _grisOscuro,
          ),
        ),
      ],
    );
  }

  // =============================================
  // Tabla de detalles de factura
  // =============================================
  static pw.Widget _buildTablaDetalles(
      List<DetalleFacturaDTO> detalles,
      Map<int, String>? mapaNombresProductos,
      ) {
    if (detalles.isEmpty) {
      return pw.Text(
        'Sin productos registrados',
        style: pw.TextStyle(fontSize: 7, color: _grisMedio, fontStyle: pw.FontStyle.italic),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _grisLinea, width: 0.3),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(4.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.8),
      },
      children: [
        // Cabecera
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _grisHeader),
          children: [
            _celdaCabecera('Producto / Servicio', align: pw.TextAlign.left),
            _celdaCabecera('Cant.', align: pw.TextAlign.center),
            _celdaCabecera('Precio', align: pw.TextAlign.center),
            _celdaCabecera('Subtotal', align: pw.TextAlign.center),
          ],
        ),
        // Filas
        ...detalles.map((d) {
          String nombreProducto = d.descripcion;
          if (d.idProducto != null && mapaNombresProductos != null) {
            nombreProducto = mapaNombresProductos[d.idProducto] ?? d.descripcion;
          }
          if (nombreProducto.isEmpty) {
            nombreProducto = 'Producto #${d.idProducto ?? '?'}';
          }

          return pw.TableRow(
            children: [
              _celdaDato(
                nombreProducto,
                align: pw.TextAlign.left,
              ),
              _celdaDato(
                '${d.cantidad}',
                align: pw.TextAlign.center,
              ),
              _celdaDato(
                '\$${d.precioUnitario.toStringAsFixed(2)}',
                align: pw.TextAlign.center,
              ),
              _celdaDato(
                '\$${d.subtotal.toStringAsFixed(2)}',
                align: pw.TextAlign.center,
                bold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _celdaCabecera(String texto, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        texto,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
          color: _grisOscuro,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static pw.Widget _celdaDato(String texto,
      {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        texto,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7,
          color: _grisOscuro,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // =============================================
  // TOTAL GENERAL
  // =============================================
  static pw.Widget _buildTotalGeneral(double total) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 180,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _rojoClaro,
          border: pw.Border.all(color: _rojo, width: 1),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL HISTORIAL',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _grisMedio,
              ),
            ),
            pw.Text(
              '\$${total.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _rojo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // UTILIDADES
  // =============================================

  static String _formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return fecha;
    }
  }

  static String _limpiarNombreArchivo(String nombre) {
    return nombre
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(' ', '_');
  }
}