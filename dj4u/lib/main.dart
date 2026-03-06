import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light
    ),
  );
  runApp(const DJ4UApp());
}

class DJ4UApp extends StatelessWidget {
  const DJ4UApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ4U',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050545),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF7900),
          secondary: Color(0xFFADA0A0),
          surface: Color(0xFF13131A),
          onPrimary: Color(0xFF050545),
          onSecondary: Colors.white
        ),
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
