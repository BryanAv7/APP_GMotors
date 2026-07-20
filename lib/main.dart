import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';
import 'screens/HomeScreen.dart';
import 'screens/reset_password_screen.dart';

// Handler para notificaciones
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  //print('Notificación background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _handleDeepLink();
  }

  void _handleDeepLink() {
    appLinks.uriLinkStream.listen(
          (uri) {
        print('Deep link recibido: $uri');
        _processUri(uri);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  void _processUri(Uri uri) {

    if (uri.scheme == 'gmotors' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        setState(() {
          _resetToken = token;
        });


        Future.delayed(const Duration(milliseconds: 500), () {
          navigatorKey.currentState?.pushNamed(
            '/reset',
            arguments: token,
          );
        });
      } else {
        //print(' Token vacío o nulo');
      }
    } else {
      //print(' URI no coincide con reset-password');
    }

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/reset': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String? ?? _resetToken ?? '';
          return ReestablecerContrasenaScreen(token: token);
        },
      },
    );
  }
}