import 'package:flutter/material.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({Key? key}) : super(key: key);

  void _onButtonPressed(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tombol "$label" ditekan')));
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // padding antar tombol
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _onButtonPressed(context, label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              context,
              'Export Data Dimsum',
              Icons.picture_as_pdf,
              Color.fromRGBO(243, 197, 60, 1),
            ),
            _buildButton(
              context,
              'Export Data Kriteria',
              Icons.picture_as_pdf,
              Color.fromRGBO(243, 197, 60, 1),
            ),
            _buildButton(
              context,
              'Export Data SAW',
              Icons.picture_as_pdf,
              Color.fromRGBO(243, 197, 60, 1),
            ),
          ],
        ),
      ),
    );
  }
}
