import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cek data di Shared Preferences sebelum aplikasi jalan
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(initialIsLoggedIn: isLoggedIn, initialIsDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool initialIsLoggedIn;
  final bool initialIsDarkMode;

  const MyApp({
    super.key,
    required this.initialIsLoggedIn,
    required this.initialIsDarkMode,
  });

  // Fungsi sakti biar halaman lain bisa akses fungsi ganti tema
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialIsDarkMode;
  }

  // Fungsi ganti tema
  void toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Getter buat ngecek status tema dari file lain
  bool get isDarkMode => _isDarkMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ujian Flutter Modular',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // TINT & MODE CONFIG
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // Ganti warna tint sesuka hati
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      // Logika Navigasi Awal
      home: widget.initialIsLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}