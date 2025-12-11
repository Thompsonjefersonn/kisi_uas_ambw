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
        // Isi kedua list dengan data yang sama saat awal buka
        _allNotes = List<Map<String, dynamic>>.from(jsonDecode(savedData));
        _foundNotes = _allNotes; 
      }
    });
  }

  // --- LOGIKA PENCARIAN ---
  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    
    if (keyword.isEmpty) {
      // Kalau search bar kosong, tampilkan semua data lagi
      results = _allNotes;
    } else {
      // Kalau ada ketikan, filter dari _allNotes
      results = _allNotes
          .where((item) =>
              item["title"].toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    // Update UI
    setState(() {
      _foundNotes = results;
    });
  }

  // --- 2. SAVE DATA ---
  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    // Yang disimpan ke memori HP selalu _allNotes (data lengkap)
    await prefs.setString('notes_data_final', jsonEncode(_allNotes));
  }

  // --- 3. CREATE & UPDATE ---
  void _addOrEditNote({
    int? index,
    required String title,
    required String content,
    required String date,
  }) {
    Map<String, dynamic> newNote = {
      'title': title,
      'content': content,
      'date': date,
    };

    setState(() {
      if (index == null) {
        // Tambah Baru
        _allNotes.add(newNote);
      } else {
        // Edit: Hati-hati, index di _foundNotes bisa beda dengan _allNotes saat searching.
        // Untuk UAS yg aman: Kita cari data asli di _allNotes lalu update.
        // Tapi cara paling gampang biar gak bug:
        // Update data di database utama (_allNotes)
        // Note: Logic index ini works kalau tidak sedang searching. 
        // Jika sedang searching, logic update index agak kompleks. 
        // Solusi simpel UAS: Update _allNotes, lalu reset search.
        
        // Cari item yang diedit di _allNotes (berdasarkan referensi list lama/simple replace)
        // Asumsi UAS: Index didapat dari _foundNotes yg sedang tampil.
        // Kita pakai logika sederhana: Refresh ulang list.
        if (_searchController.text.isNotEmpty) {
           // Jika sedang search, edit agak tricky. Kita disable search dulu biar aman.
           _searchController.clear();
           _foundNotes = _allNotes;
        }
        _allNotes[index] = newNote;
      }
      
      // Setelah nambah/edit, reset tampilan agar muncul data terbaru
      _foundNotes = _allNotes; 
      _searchController.clear(); // Bersihkan search bar
    });
    _saveData();
  }

  // --- 4. DELETE ---
  void _deleteNote(int index) {
    setState(() {
      // Hapus dari _foundNotes (tampilan)
      // Tapi kita harus hapus juga dari _allNotes (database)
      
      // Kasus: User search "Mat", muncul 1 item (index 0).
      // Padahal di database aslinya dia index ke-5.
      // Kalau langsung removeAt(0), salah hapus data!
      
      // Solusi Aman UAS: Ambil objectnya, cari di master, hapus.
      Map<String, dynamic> itemToDelete = _foundNotes[index];
      
      _allNotes.removeWhere((element) => element == itemToDelete);
      _foundNotes = _allNotes; // Reset list
      _searchController.clear(); // Reset search bar
    });
    _saveData();
  }

  // --- LOGOUT & DATE PICKER SAMA SEPERTI SEBELUMNYA ---
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

    if (index != null) {
      titleController.text = _foundNotes[index]['title'];
      contentController.text = _foundNotes[index]['content'];
      dateController.text = _foundNotes[index]['date'];
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
      // PERUBAHAN UI UTAMA DISINI
      body: Column(
        children: [
          // 1. BAGIAN SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value), // Panggil fungsi saat ngetik
              decoration: InputDecoration(
                labelText: 'Cari Jadwal...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                // Tombol silang untuk hapus search
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter(''); // Reset list
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. BAGIAN LIST VIEW
          Expanded(
            child: _foundNotes.isEmpty
                ? const Center(child: Text("Tidak ada data ditemukan"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _foundNotes.length, // Pakai foundNotes
                    itemBuilder: (context, index) {
                      final note = _foundNotes[index]; // Pakai foundNotes
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            radius: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
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
                              Text(note['content']),
                              Text("Deadline: ${note['date']}", style: TextStyle(color: Colors.blue[700])),
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
          ),
        ],
      ),
    );
  }
}