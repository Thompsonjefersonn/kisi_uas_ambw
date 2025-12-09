import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Tambah controller password

  void _login() async {
    // Validasi Sederhana (Hardcoded)
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Contoh: Username bebas, tapi Password wajib "12345"
    if (username == "admin" && password == "12345") {
      
      final prefs = await SharedPreferences.getInstance();
      
      // Simpan "Sesi" bahwa user sudah login
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      // Jika password salah atau input kosong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Gagal! Password harus "12345"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text("Login Simulasi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Input Username
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),
            
            // Input Password (Baru)
            TextField(
              controller: _passwordController,
              obscureText: true, // Biar teks jadi bintang-bintang/titik
              decoration: const InputDecoration(
                labelText: "Password (isi: 12345)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("MASUK"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}