import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'auth_service.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  bool _isLoading = false;
  String? _username;
  final String apiUrl = 'https://bb3e9ca8413f.ngrok-free.app/dimsum-variant';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = AuthService().username;
    setState(() {
      _username = username;
    });
    print('Username loaded: $_username');
  }

  String _getHariIndonesia(DateTime date) {
    const hari = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return hari[date.weekday % 7];
  }

  String _getBulanIndonesia(int bulan) {
    const namaBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return namaBulan[bulan - 1];
  }

  Future<void> _downloadDimsumReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch dimsum data');
      }

      final List<dynamic> dimsumData = json.decode(response.body);
      if (dimsumData.isEmpty) {
        throw Exception('No dimsum data available');
      }

      if (Platform.isAndroid) {
        await _handleAndroidPermissions();
      }

      final pdf = pw.Document();
      final now = DateTime.now();
      final hari = _getHariIndonesia(now);
      final tanggal = '${now.day} ${_getBulanIndonesia(now.month)} ${now.year}';

      pdf.addPage(
        pw.MultiPage(
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 50),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Bogor, $hari $tanggal'),
                  pw.SizedBox(height: 65),
                  pw.Text(_username ?? ''),
                ],
              ),
            );
          },
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Dimsum',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Dibuat : ${now.toString()}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: [
                'No',
                'Nama Dimsum',
                'Modal (Rp)',
                'Profit (Rp)',
                'Total (Rp)',
              ],
              data: List<List<String>>.generate(
                dimsumData.length,
                (index) => [
                  (index + 1).toString(),
                  dimsumData[index]['name'].toString(),
                  dimsumData[index]['modal'].toString(),
                  dimsumData[index]['profit'].toString(),
                  (dimsumData[index]['modal'] + dimsumData[index]['profit'])
                      .toString(),
                ],
              ),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );

      final downloadsPath = "/storage/emulated/0/Download";
      final fileName = 'laporan_dimsum_${now.millisecondsSinceEpoch}.pdf';
      final filePath = '$downloadsPath/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan berhasil diunduh: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Mengunduh data dimsum...'),
                ],
              )
            : ElevatedButton(
                onPressed: _downloadDimsumReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Download Laporan Dimsum PDF",
                  style: TextStyle(fontSize: 16),
                ),
              ),
      ),
    );
  }
}
