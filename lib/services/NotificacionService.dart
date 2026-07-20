import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/oferta_service.dart';

class NotificacionService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ofertas_channel',
    'Ofertas GorilaMotos',
    description: 'Notificaciones de ofertas y promociones',
    importance: Importance.high,
  );

  static Future<void> inicializar(BuildContext context) async {

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      //print('Usuario denegó permisos de notificación');
      return;
    }

    String? fcmToken = await _messaging.getToken();
    //print('FCM Token: $fcmToken');

    if (fcmToken != null) {
      await OfertaService.registrarToken(fcmToken);
    }

    _messaging.onTokenRefresh.listen((nuevoToken) async {
      //print(' Token FCM renovado: $nuevoToken');
      await OfertaService.registrarToken(nuevoToken);
    });

    // ── Notificación con app ABIERTA ──
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //print('Foreground: ${message.notification?.title}');

      if (message.notification != null) {
        // Extraer imagen del mensaje
        final imagenUrl = message.notification?.android?.imageUrl
            ?? message.data['imagen_url'];

        // ── Leer fechas del data payload ──
        final fechaInicio = message.data['fechaInicio'];
        final fechaFin = message.data['fechaFin'];

        //print('Fechas: $fechaInicio → $fechaFin');


        _mostrarNotificacionLocal(
          titulo: message.notification!.title ?? 'Nueva oferta',
          cuerpo: '${message.notification!.body ?? ''}'
              '\n📅 Del $fechaInicio al $fechaFin',
          imagenUrl: imagenUrl,
        );
      }
    });
  }

  // ── Descarga imagen y mostrar ──
  static Future<void> _mostrarNotificacionLocal({
    required String titulo,
    required String cuerpo,
    String? imagenUrl,
  }) async {
    AndroidNotificationDetails androidDetails;

    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      try {
        // Descargar imagen temporalmente
        final response = await http.get(Uri.parse(imagenUrl));
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/notif_imagen.jpg');
        await file.writeAsBytes(response.bodyBytes);

        // Mostrar con imagen grande
        final FilePathAndroidBitmap bitmap = FilePathAndroidBitmap(file.path);

        androidDetails = AndroidNotificationDetails(
          'ofertas_channel',
          'Ofertas GorilaMotos',
          channelDescription: 'Notificaciones de ofertas y promociones',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/launcher_icon',
          styleInformation: BigPictureStyleInformation(
            bitmap,
            largeIcon: bitmap,
            contentTitle: titulo,
            summaryText: cuerpo,
            hideExpandedLargeIcon: false,
          ),
        );
      } catch (e) {
        //print('Error cargando imagen notificación: $e');
        // Si falla la imagen, muestra sin ella
        androidDetails = _detallesSinImagen(cuerpo);
      }
    } else {
      androidDetails = _detallesSinImagen(cuerpo);
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      cuerpo,
      NotificationDetails(android: androidDetails),
    );
  }

  static AndroidNotificationDetails _detallesSinImagen(String cuerpo) {
    return AndroidNotificationDetails(
      'ofertas_channel',
      'Ofertas GorilaMotos',
      channelDescription: 'Notificaciones de ofertas y promociones',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(cuerpo),
    );
  }
}