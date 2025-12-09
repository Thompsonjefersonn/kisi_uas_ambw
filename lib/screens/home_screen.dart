import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notes = [];
  String _username = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 1. LOAD DATA ---
  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User";
      String? savedData = prefs.getString('notes_data_final');
      if (savedData != null) {
        _notes = List<Map<String, dynamic>>.from(jsonDecode(savedData));
      }
    });
  }

  // --- 2. SAVE DATA ---
  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes_data_final', jsonEncode(_notes));
  }

  // --- 3. CREATE & UPDATE ---
  void _addOrEditNote({
    int? index,
    required String title,
    required String content,
    required String date,
  }) {
    setState(() {
      Map<String, dynamic> newNote = {
        'title': title,
        'content': content,
        'date': date, // Tanggal sekarang dari input user
      };

      if (index == null) {
        _notes.add(newNote);
      } else {
        _notes[index] = newNote;
      }
    });
    _saveData();
  }

  // --- 4. DELETE ---
  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveData();
  }

  // --- LOGOUT ---
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // --- FITUR BARU: DATE PICKER ---
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    // Tampilkan Kalender
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Tanggal awal yang disorot
      firstDate: DateTime(2000),   // Batas bawah tahun
      lastDate: DateTime(2100),    // Batas atas tahun
    );

    // Jika user memilih tanggal (tidak cancel)
    if (picked != null) {
      // Format sederhana: YYYY-MM-DD (ambil bagian depannya saja)
      // Kalau mau format cantik (misal: 12 Desember 2024) harus pakai library 'intl', 
      // tapi cara split ini aman tanpa install library tambahan.
      String formattedDate = picked.toString().split(" ")[0]; 
      controller.text = formattedDate; // Isi teks ke kolom
    }
  }

  // --- FORM DIALOG (Updated) ---
  void _showForm({int? index}) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final dateController = TextEditingController(); // Controller baru untuk tanggal

    if (index != null) {
      titleController.text = _notes[index]['title'];
      contentController.text = _notes[index]['content'];
      dateController.text = _notes[index]['date'];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Catatan Baru" : "Edit Catatan"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Input Judul
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Judul",
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 10),
              
              // 2. Input Isi
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: "Isi Catatan",
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              // 3. Input Tanggal (Read Only & Tap to Pick)
              TextField(
                controller: dateController,
                readOnly: true, // PENTING: Agar keyboard tidak muncul
                decoration: const InputDecoration(
                  labelText: "Pilih Tanggal",
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: "Klik untuk pilih tanggal",
                ),
                onTap: () {
                  _selectDate(context, dateController); // Panggil kalender saat diklik
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              // Validasi: Semua harus diisi
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty &&
                  dateController.text.isNotEmpty) {
                
                _addOrEditNote(
                  index: index,
                  title: titleController.text,
                  content: contentController.text,
                  date: dateController.text,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Semua kolom harus diisi!")),
                );
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myApp = MyApp.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Jadwal Ujian", style: TextStyle(fontSize: 18)),
            Text("User: $_username", style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(myApp != null && myApp.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => myApp?.toggleTheme(),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _notes.isEmpty
          ? const Center(child: Text("Belum ada jadwal. Tambah yuk!"))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    // Tampilkan Tanggal di Bagian Kiri (Leading) agar menonjol
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      radius: 30,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          // Ambil tanggalnya saja (misal "20") buat ikon
                          note['date'].toString().split('-').last, 
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    title: Text(
                      note['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(note['content']),
                        const SizedBox(height: 5),
                        // Tampilkan Tanggal Lengkap
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(
                              "Deadline: ${note['date']}",
                              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') _showForm(index: index);
                        if (value == 'delete') _deleteNote(index);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        const PopupMenuItem(value: 'delete', child: Text("Hapus")),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}