import 'package:flutter/material.dart';
import 'package:sipeka/widgets/custom_drawer.dart';

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
      ),
      drawer: const CustomDrawer(),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO & HEADER
            Center(
              child: Column(
                children:  [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        AssetImage("assets/images/dinsos_logo.png"),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "SIPEKA",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Versi 1.0.0",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

             SizedBox(height: 24),

            // DESKRIPSI
             Text(
              "Deskripsi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             SizedBox(height: 8),
             Text(
              "SIPEKA (Sistem Informasi Pelaporan Kinerja dan Anggaran) "
              "merupakan aplikasi yang dirancang untuk membantu proses "
              "monitoring, pencatatan, serta pelaporan kegiatan secara "
              "efektif dan terintegrasi.",
              textAlign: TextAlign.justify,
            ),

             SizedBox(height: 20),

            // PENGEMBANG
             Text(
              "Pengembang",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             SizedBox(height: 8),

            Card(
              elevation: 2,
              child: Column(
                children:  [
                  ListTile(
                    // Image.asset("assets/images/ahmadhusin.jpeg", width: 40, height: 40)
                    leading: CircleAvatar(
                      radius: 28, // ukuran lebih besar
                      backgroundImage: AssetImage("assets/images/ahmadhusin.jpeg"),
                    ),
                    title: Text("Ahmad Husin"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fullstack Developer"),
                        SizedBox(height: 4),
                        Text("Email: ahmadhusin.2340304028@gmail.com"),
                        Text("WA: 0852-5687-5779"),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage("assets/images/ahmadhusin.jpeg"),
                    ),
                    title: Text("Rangga Saputra"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fullstack Developer"),
                        SizedBox(height: 4),
                        Text("Email: rangga@email.com"),
                        Text("WA: 0812-3456-7891"),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage("assets/images/ahmadhusin.jpeg"),
                    ),
                    title: Text("Adi Saputra"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fullstack Developer"),
                        SizedBox(height: 4),
                        Text("Email: adi@email.com"),
                        Text("WA: 0812-3456-7892"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

             SizedBox(height: 20),

            // KONTAK
             Text(
              "Kontak",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             SizedBox(height: 8),
             Row(
              children: [
                Icon(Icons.email, size: 18),
                SizedBox(width: 8),
                Text("it@domain.go.id"),
              ],
            ),

             SizedBox(height: 30),

             Center(
              child: Text(
                "© 2026 SIPEKA Team",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}