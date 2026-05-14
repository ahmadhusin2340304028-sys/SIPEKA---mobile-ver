import 'package:flutter/material.dart';
import 'package:sipeka/widgets/custom_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  Widget buildIconItem(IconData icon, String label, String url, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO & HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                  top: Radius.circular(24)
                ),
              ),
              child: const Column(
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 42,
                    backgroundImage:
                        AssetImage("assets/images/dinsos_logo.png"),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "SIPEKA",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Versi 1.0.0",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),

            // DESKRIPSI
             const Text(
              "Deskripsi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             const SizedBox(height: 8),
             const Text(
              "SIPEKA (Sistem Informasi Pelaporan Kinerja dan Anggaran) "
              "merupakan aplikasi yang dirancang untuk membantu proses "
              "monitoring, pencatatan, serta pelaporan kegiatan secara "
              "efektif dan terintegrasi.",
              textAlign: TextAlign.justify,
            ),

             const SizedBox(height: 20),

            // PENGEMBANG
             const Text(
              "Pengembang",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             const SizedBox(height: 8),

            const Card(
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
                        Text("Software Developer"),
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
                        Text("Software Developer"),
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
                        Text("Software Developer"),
                        SizedBox(height: 4),
                        Text("Email: adi@email.com"),
                        Text("WA: 0812-3456-7892"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

             const SizedBox(height: 20),

            // KONTAK
             const Text(
              "Kontak",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             const SizedBox(height: 12),
             

            // Facebook
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildIconItem(Icons.email, "Email", "mailto:it@domain.go.id", Colors.red),
                buildIconItem(Icons.facebook, "Facebook", "https://www.facebook.com/DinsosPM", Colors.blue),
                buildIconItem(Icons.camera_alt, "Instagram", "https://www.instagram.com/dinsospm", Colors.purple),
                buildIconItem(Icons.language, "Website", "https://dinsos.tarakankota.go.id/", Colors.green),
              ],
            ),

             const SizedBox(height: 30),

             const Center(
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