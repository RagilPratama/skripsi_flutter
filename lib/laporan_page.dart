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

  final String apiDimsum = 'https://8f9f6e2f555e.ngrok-free.app/dimsum-variant';
  final String apiCriteria =
      'https://8f9f6e2f555e.ngrok-free.app/criteria-weight';
  final String apiNilaiAkhir =
      'https://8f9f6e2f555e.ngrok-free.app/nilai-awal/result-saw';
  final String apiNormalisasi =
      'https://8f9f6e2f555e.ngrok-free.app/nilai-awal/normalisasi';

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
    await _generatePdfReport(
      url: apiDimsum,
      title: "Laporan Dimsum",
      tableHeaders: ['No', 'Nama Dimsum', 'Modal (Rp)', 'Profit (Rp)'],
      rowBuilder: (data, index) => [
        (index + 1).toString(),
        data['name'].toString(),
        data['modal'].toString(),
        data['profit'].toString(),
      ],
      filePrefix: "laporan_dimsum",
    );
  }

  Future<void> _downloadCriteriaReport() async {
    await _generatePdfReport(
      url: apiCriteria,
      title: "Laporan Kriteria",
      tableHeaders: ['No', 'Nama Kriteria', 'Bobot'],
      rowBuilder: (data, index) => [
        (index + 1).toString(),
        data['criteria_name'].toString(),
        data['weight'].toString(),
      ],
      filePrefix: "laporan_kriteria",
    );
  }

  Future<void> _downloadNilaiAkhirReport() async {
    await _generatePdfReport(
      url: apiNilaiAkhir,
      title: "Laporan Nilai Akhir",
      tableHeaders: ['No', 'Nama', 'Nilai Akhir'],
      rowBuilder: (data, index) => [
        (index + 1).toString(),
        data['nama'].toString(),
        (data['nilai'] as num).toStringAsFixed(3),
      ],
      filePrefix: "laporan_nilai_akhir",
      beforeBuild: (dataList) {
        dataList.sort(
          (a, b) => (b['nilai'] as num).compareTo(a['nilai'] as num),
        );
        return dataList;
      },
    );
  }

  Future<void> _downloadNormalisasiReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiNormalisasi));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data normalisasi');
      }

      final List<dynamic> dataList = json.decode(response.body);
      if (dataList.isEmpty) {
        throw Exception('Data normalisasi kosong');
      }

      if (Platform.isAndroid) {
        await _handleAndroidPermissions();
      }

      final firstItem = dataList.first as Map<String, dynamic>;
      final dynamicKeys = firstItem.keys.where((k) => k != 'nama').toList();

      final headers = <String>['No', 'Nama'];
      for (var i = 0; i < dynamicKeys.length; i++) {
        headers.add('C${i + 1}');
      }

      final dataRows = List<List<String>>.generate(dataList.length, (i) {
        final item = dataList[i] as Map<String, dynamic>;
        final row = <String>[];
        row.add((i + 1).toString());
        row.add(item['nama'].toString());
        for (var key in dynamicKeys) {
          final val = item[key];
          if (val is num) {
            row.add(val.toStringAsFixed(6));
          } else {
            row.add(val.toString());
          }
        }
        return row;
      });

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
                  pw.Text(_username ?? ''),
                  pw.SizedBox(height: 60), // space untuk tanda tangan
                  pw.Text('M Ragil Pratama'),
                ],
              ),
            );
          },
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                "Laporan Normalisasi",
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
              headers: headers,
              data: dataRows,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );

      final downloadsPath = "/storage/emulated/0/Download";
      final fileName = 'laporan_normalisasi_${now.millisecondsSinceEpoch}.pdf';
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

  Future<void> _generatePdfReport({
    required String url,
    required String title,
    required List<String> tableHeaders,
    required List<String> Function(dynamic data, int index) rowBuilder,
    required String filePrefix,
    List<dynamic> Function(List<dynamic>)? beforeBuild,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data');
      }

      List<dynamic> dataList = json.decode(response.body);
      if (dataList.isEmpty) {
        throw Exception('Data kosong');
      }

      if (beforeBuild != null) {
        dataList = beforeBuild(dataList);
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
                  pw.Text(_username ?? ''),
                  pw.SizedBox(height: 60), // space untuk tanda tangan
                  pw.Text('M Ragil Pratama'),
                ],
              ),
            );
          },
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
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
              headers: tableHeaders,
              data: List<List<String>>.generate(
                dataList.length,
                (i) => rowBuilder(dataList[i], i),
              ),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );

      final downloadsPath = "/storage/emulated/0/Download";
      final fileName = '${filePrefix}_${now.millisecondsSinceEpoch}.pdf';
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
        if (match != null) return int.parse(match.group(1)!);
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
                  Text('Mengunduh laporan...'),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _downloadCriteriaReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Download Laporan Kriteria PDF",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _downloadNilaiAkhirReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Download Laporan Nilai Akhir PDF",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _downloadNormalisasiReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Download Laporan Normalisasi PDF",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
