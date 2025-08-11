import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  Future<void> _savePdfToDownloads() async {
    try {
      if (Platform.isAndroid) {
        await _handleAndroidPermissions();
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Text('Hello PDF!', style: pw.TextStyle(fontSize: 40)),
          ),
        ),
      );

      final downloadsPath = "/storage/emulated/0/Download";
      final filePath =
          '$downloadsPath/laporan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil disimpan di Downloads: $filePath'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleAndroidPermissions() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();

      if (androidVersion >= 30) {
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception("Izin Manage External Storage ditolak");
          }
        }
      } else {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            throw Exception("Izin penyimpanan ditolak");
          }
        }
      }
    }
  }

  Future<int> _getAndroidVersion() async {
    try {
      final file = File("/system/build.prop");
      if (await file.exists()) {
        final content = await file.readAsString();
        final match = RegExp(r'ro.build.version.sdk=(\d+)').firstMatch(content);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      }
    } catch (_) {}
    return 30; // default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _savePdfToDownloads,
          child: const Text("Download Laporan Dimsum PDF"),
        ),
      ),
    );
  }
}
