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
  // Controller untuk text field pencarian
  final TextEditingController _searchController = TextEditingController();

  // LIST 1: Master Data (Menyimpan semua data dari HP)
  List<Map<String, dynamic>> _allNotes = [];
  
  // LIST 2: Display Data (Yang ditampilkan di layar)
  List<Map<String, dynamic>> _foundNotes = [];

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
        // Decode data
        _allNotes = List<Map<String, dynamic>>.from(jsonDecode(savedData));
        _foundNotes = _allNotes; 
      }
    });
  }

  // --- LOGIKA PENCARIAN ---
  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    if (keyword.isEmpty) {
      results = _allNotes;
    } else {
      results = _allNotes
          .where((item) =>
              item["title"].toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundNotes = results;
    });
  }

  // --- 2. SAVE DATA ---
  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes_data_final', jsonEncode(_allNotes));
  }

  // --- 3. CREATE & UPDATE ---
  void _addOrEditNote({
    int? index,
    required String title,
    required String content,
    required String date,
    bool isDone = false, // Default false jika baru
  }) {
    Map<String, dynamic> newNote = {
      'title': title,
      'content': content,
      'date': date,
      'isDone': isDone,
    };

    setState(() {
      if (index == null) {
        // Tambah Baru
        _allNotes.add(newNote);
      } else {
        // Logic Edit Aman: Update _allNotes
        // Jika sedang search, matikan search dulu biar index sinkron
        if (_searchController.text.isNotEmpty) {
           _searchController.clear();
           _foundNotes = _allNotes;
        }
        _allNotes[index] = newNote;
      }
      
      // Reset tampilan
      _foundNotes = _allNotes; 
      _searchController.clear();
    });
    _saveData();
  }

  // --- 4. DELETE DENGAN KONFIRMASI ---
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Jadwal?"),
        content: const Text("Data ini akan dihapus permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _deleteNote(index); // Eksekusi hapus
            }, 
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() {
      Map<String, dynamic> itemToDelete = _foundNotes[index];
      _allNotes.removeWhere((element) => element == itemToDelete);
      _foundNotes = _allNotes; 
      _searchController.clear(); 
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data berhasil dihapus")));
  }

  // --- 5. TOGGLE CHECKBOX (SELESAI/BELUM) ---
  void _toggleDone(int index) {
    setState(() {
      // Ambil status sekarang (pakai ?? false untuk jaga-jaga kalau null)
      bool currentStatus = _foundNotes[index]['isDone'] ?? false;
      
      // Ubah status jadi kebalikannya
      _foundNotes[index]['isDone'] = !currentStatus;
      
      // Karena _foundNotes merujuk ke object memory yang sama dengan _allNotes,
      // data di _allNotes biasanya otomatis update.
      // Tapi untuk memastikan save benar, kita panggil _saveData.
    });
    _saveData();
  }

  // --- LOGOUT & DATE PICKER ---
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

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      String formattedDate = picked.toString().split(" ")[0]; 
      controller.text = formattedDate;
    }
  }

  // --- FORM DIALOG ---
  void _showForm({int? index}) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final dateController = TextEditingController();
    
    // Simpan status isDone saat ini (untuk edit)
    bool currentDoneStatus = false;

    if (index != null) {
      titleController.text = _foundNotes[index]['title'];
      contentController.text = _foundNotes[index]['content'];
      dateController.text = _foundNotes[index]['date'];
      // Ambil status done yang ada
      currentDoneStatus = _foundNotes[index]['isDone'] ?? false;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Catatan Baru" : "Edit Catatan"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Judul"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "Isi"),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Tanggal"),
                onTap: () => _selectDate(context, dateController),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty &&
                  dateController.text.isNotEmpty) {
                _addOrEditNote(
                  index: index,
                  title: titleController.text,
                  content: contentController.text,
                  date: dateController.text,
                  isDone: currentDoneStatus, // Pertahankan status saat edit
                );
                Navigator.pop(context);
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
      
      // --- BODY UTAMA ---
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: 'Cari Jadwal...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. List View
          Expanded(
            child: _foundNotes.isEmpty
                ? const Center(child: Text("Tidak ada data ditemukan"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _foundNotes.length,
                    itemBuilder: (context, index) {
                      final note = _foundNotes[index];
                      // Cek status selesai (aman null)
                      bool isDone = note['isDone'] ?? false;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        // Warna card jadi abu-abu jika selesai
                        color: isDone ? Colors.grey[200] : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          // LOGIKA LEADING: Row (Checkbox + Tanggal)
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isDone,
                                onChanged: (val) => _toggleDone(index),
                              ),
                              CircleAvatar(
                                backgroundColor: isDone ? Colors.grey : Colors.deepPurple,
                                foregroundColor: Colors.white,
                                radius: 25,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    note['date'].toString().split('-').last,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            note['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              // Coret tulisan jika selesai
                              decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                              color: isDone ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note['content'],
                                style: TextStyle(
                                  decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                  color: isDone ? Colors.grey : Colors.black87,
                                ),
                              ),
                              Text(
                                "Deadline: ${note['date']}",
                                style: TextStyle(
                                  color: isDone ? Colors.grey : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'edit') _showForm(index: index);
                              // Panggil fungsi confirm delete biar aman
                              if (value == 'delete') _confirmDelete(index);
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
          ),
        ],
      ),
    );
  }
}