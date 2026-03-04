import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Kullanıcıyı arka planda (anonim olarak) Firebase'e dahil ediyoruz.
  await FirebaseAuth.instance.signInAnonymously();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: const WatchRemote(),
    );
  }
}

class WatchRemote extends StatefulWidget {
  const WatchRemote({super.key});

  @override
  State<WatchRemote> createState() => _WatchRemoteState();
}

class _WatchRemoteState extends State<WatchRemote> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("control/command");

  void sendCommand(String cmd) async {
    await _dbRef.set(cmd);
    print("Komut: $cmd");
  }

  @override
  Widget build(BuildContext context) {
    // WatchShape yerine standart, ortalanmış bir tasarım kullanıyoruz.
    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // Küçük ekranlarda taşmayı önler
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.laptop_chromebook, size: 20, color: Colors.grey),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton(Icons.arrow_back_ios_new, Colors.orangeAccent, "PREV"),
                  const SizedBox(width: 10),
                  _buildButton(Icons.arrow_forward_ios, Colors.greenAccent, "NEXT"),
                ],
              ),
              const SizedBox(height: 10),
              // Kilit Butonu
              InkWell(
                onTap: () => sendCommand("LOCK"),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 24, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, Color color, String cmd) {
    return SizedBox(
      width: 55,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => sendCommand(cmd),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}