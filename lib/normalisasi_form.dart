import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NormalisasiForm extends StatefulWidget {
  const NormalisasiForm({super.key});

  @override
  State<NormalisasiForm> createState() => _NormalisasiFormState();
}

class _NormalisasiFormState extends State<NormalisasiForm> {
  final _formKey = GlobalKey<FormState>();
  final _nilaiController = TextEditingController();

  int? _selectedProdukId;
  int? _selectedKriteriaId;

  List<Map<String, dynamic>> _produkList = [];
  List<Map<String, dynamic>> _kriteriaList = [];
  List<Map<String, dynamic>> _normalisasiList = [];

  List<Map<String, dynamic>> _normalisasiOriginalList = [];

  bool _isLoading = true;
  bool _isLoadingProduk = true;
  bool _isLoadingKriteria = true;
  bool _isLoadingOriginal = true;

  // Filter nama produk untuk tabel normalisasi original
  String? _filterProdukName;

  // Pagination variables for original normalisasi table
  int _currentPageOriginal = 0;
  final int _rowsPerPageOriginal = 5;

  // Data & pagination untuk dynamic normalisasi (nilai-awal/normalisasi)
  List<Map<String, dynamic>> _normalisasiDynamicData = [];
  bool _isLoadingDynamic = true;
  int _currentPageDynamic = 0;
  final int _rowsPerPageDynamic = 5;
  List<String> _dynamicColumns = [];

  final String normalisasiApiUrl =
      'https://d610b2f70ae5.ngrok-free.app/nilai-awal';
  final String produkApiUrl =
      'https://d610b2f70ae5.ngrok-free.app/dimsum-variant';
  final String kriteriaApiUrl =
      'https://d610b2f70ae5.ngrok-free.app/criteria-weight';
  final String normalisasiOriginalApiUrl =
      'https://d610b2f70ae5.ngrok-free.app/nilai-awal/original';

  final String normalisasiDynamicApiUrl =
      'https://d610b2f70ae5.ngrok-free.app/nilai-awal/normalisasi';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProdukData(),
      _loadKriteriaData(),
      _loadNormalisasiData(),
      _loadNormalisasiOriginalData(),
      _loadNormalisasiDynamicData(),
    ]);
  }

  Future<void> _loadProdukData() async {
    try {
      final response = await http.get(Uri.parse(produkApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _produkList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoadingProduk = false;
        });
      } else {
        setState(() => _isLoadingProduk = false);
        _showError('Gagal load data produk');
      }
    } catch (e) {
      setState(() => _isLoadingProduk = false);
      _showError('Error load produk: $e');
    }
  }

  Future<void> _loadKriteriaData() async {
    try {
      final response = await http.get(Uri.parse(kriteriaApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _kriteriaList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoadingKriteria = false;
        });
      } else {
        setState(() => _isLoadingKriteria = false);
        _showError('Gagal load data kriteria');
      }
    } catch (e) {
      setState(() => _isLoadingKriteria = false);
      _showError('Error load kriteria: $e');
    }
  }

  Future<void> _loadNormalisasiData() async {
    try {
      final response = await http.get(Uri.parse(normalisasiApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _normalisasiList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Gagal load data normalisasi');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error load normalisasi: $e');
    }
  }

  Future<void> _loadNormalisasiOriginalData() async {
    try {
      final response = await http.get(Uri.parse(normalisasiOriginalApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _normalisasiOriginalList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoadingOriginal = false;
        });
      } else {
        setState(() => _isLoadingOriginal = false);
        _showError('Gagal load data normalisasi original');
      }
    } catch (e) {
      setState(() => _isLoadingOriginal = false);
      _showError('Error load data normalisasi original: $e');
    }
  }

  Future<void> _loadNormalisasiDynamicData() async {
    setState(() => _isLoadingDynamic = true);
    try {
      final response = await http.get(Uri.parse(normalisasiDynamicApiUrl));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          _normalisasiDynamicData = List<Map<String, dynamic>>.from(decoded);
          // Ambil keys selain 'nama'
          final firstItem = _normalisasiDynamicData.first;
          _dynamicColumns = firstItem.keys.where((k) => k != 'nama').toList();
        } else {
          _normalisasiDynamicData = [];
          _dynamicColumns = [];
        }
      } else {
        _normalisasiDynamicData = [];
        _dynamicColumns = [];
        _showError(
          'Gagal load data normalisasi dynamic (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      _normalisasiDynamicData = [];
      _dynamicColumns = [];
      _showError('Error load normalisasi dynamic: $e');
    }
    setState(() => _isLoadingDynamic = false);
  }

  Future<void> _saveNormalisasi() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProdukId == null || _selectedKriteriaId == null) {
        _showError('Pilih produk dan kriteria terlebih dahulu');
        return;
      }

      try {
        final response = await http.post(
          Uri.parse(normalisasiApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'nilai': double.parse(_nilaiController.text),
            'id_produk': _selectedProdukId,
            'id_kriteria': _selectedKriteriaId,
          }),
        );

        if (response.statusCode == 201) {
          _clearForm();
          _loadNormalisasiData();
          _showSuccess('Normalisasi berhasil disimpan');
        } else {
          _showError('Gagal menyimpan normalisasi');
        }
      } catch (e) {
        _showError('Error: $e');
      }
    }
  }

  void _clearForm() {
    _nilaiController.clear();
    _selectedProdukId = null;
    _selectedKriteriaId = null;
    setState(() {});
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _selectedProdukId,
            decoration: const InputDecoration(
              labelText: 'Pilih Produk',
              border: OutlineInputBorder(),
            ),
            items: _produkList.map((produk) {
              return DropdownMenuItem<int>(
                value: produk['id'],
                child: Text(produk['name'] ?? 'Produk ${produk['id']}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProdukId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Pilih produk terlebih dahulu';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _selectedKriteriaId,
            decoration: const InputDecoration(
              labelText: 'Pilih Kriteria',
              border: OutlineInputBorder(),
            ),
            items: _kriteriaList
                .where((kriteria) => kriteria['id'] != 2 && kriteria['id'] != 3)
                .map((kriteria) {
                  return DropdownMenuItem<int>(
                    value: kriteria['id'],
                    child: Text(
                      kriteria['criteria_name'] ?? 'Kriteria ${kriteria['id']}',
                    ),
                  );
                })
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedKriteriaId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Pilih kriteria terlebih dahulu';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nilaiController,
            decoration: const InputDecoration(
              labelText: 'Nilai',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan nilai';
              }
              final nilai = double.tryParse(value);
              if (nilai == null) {
                return 'Masukkan nilai yang valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterProdukDropdown() {
    return DropdownButtonFormField<String?>(
      value: _filterProdukName,
      decoration: const InputDecoration(
        labelText: 'Filter Produk',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Semua Produk'),
        ),
        ..._produkList.map((produk) {
          final namaProduk = produk['name'] ?? 'Produk';
          return DropdownMenuItem<String?>(
            value: namaProduk,
            child: Text(namaProduk),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _filterProdukName = value;
          _currentPageOriginal = 0; // reset page pada tabel original
        });
      },
    );
  }

  Widget _buildNormalisasiOriginalTable() {
    if (_isLoadingOriginal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_normalisasiOriginalList.isEmpty) {
      return const Center(child: Text('Tidak ada data normalisasi original'));
    }

    final filteredList = (_filterProdukName == null)
        ? _normalisasiOriginalList
        : _normalisasiOriginalList.where((item) {
            final namaProduk = item['nama_produk'] ?? '';
            return namaProduk == _filterProdukName;
          }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text('Data tidak ditemukan untuk produk ini'));
    }

    final startIndex = _currentPageOriginal * _rowsPerPageOriginal;
    final endIndex = (startIndex + _rowsPerPageOriginal) > filteredList.length
        ? filteredList.length
        : startIndex + _rowsPerPageOriginal;

    final pageItems = filteredList.sublist(startIndex, endIndex);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DataTable(
              headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.grey.shade200,
              ),
              dividerThickness: 1,
              columns: const [
                DataColumn(label: Text('Nama Produk'), numeric: false),
                DataColumn(label: Text('Nama Kriteria'), numeric: false),
                DataColumn(label: Text('Nilai'), numeric: true),
              ],
              rows: pageItems.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['nama_produk'] ?? '-')),
                    DataCell(Text(item['nama_kriteria'] ?? '-')),
                    DataCell(
                      Text(
                        item['nilai'] != null
                            ? (double.tryParse(
                                        item['nilai'].toString(),
                                      )?.remainder(1) ==
                                      0
                                  ? double.tryParse(
                                      item['nilai'].toString(),
                                    )!.toInt().toString()
                                  : item['nilai'].toString())
                            : '-',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _currentPageOriginal > 0
                  ? () {
                      setState(() {
                        _currentPageOriginal--;
                      });
                    }
                  : null,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 20),
            Text(
              'Page ${_currentPageOriginal + 1} of ${((_normalisasiOriginalList.length - 1) / _rowsPerPageOriginal + 1).toInt()}',
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: endIndex < filteredList.length
                  ? () {
                      setState(() {
                        _currentPageOriginal++;
                      });
                    }
                  : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNormalisasiDynamicTable() {
    if (_isLoadingDynamic) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_normalisasiDynamicData.isEmpty) {
      return const Center(child: Text('Tidak ada data normalisasi'));
    }

    final startIndex = _currentPageDynamic * _rowsPerPageDynamic;
    final endIndex =
        (startIndex + _rowsPerPageDynamic) > _normalisasiDynamicData.length
        ? _normalisasiDynamicData.length
        : startIndex + _rowsPerPageDynamic;

    final pageItems = _normalisasiDynamicData.sublist(startIndex, endIndex);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DataTable(
              headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.grey.shade200,
              ),
              dividerThickness: 1,
              columns: [
                const DataColumn(label: Text('Nama Produk')),
                ...List.generate(
                  _dynamicColumns.length,
                  (index) => DataColumn(label: Text('C${index + 1}')),
                ),
              ],
              rows: pageItems.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['nama'] ?? '-')),
                    ..._dynamicColumns.map((col) {
                      final val = item[col];
                      if (val == null) return const DataCell(Text('-'));

                      if (val is num) {
                        if (val % 1 == 0) {
                          return DataCell(Text(val.toInt().toString()));
                        } else {
                          return DataCell(Text(val.toStringAsFixed(4)));
                        }
                      }
                      return DataCell(Text(val.toString()));
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _currentPageDynamic > 0
                  ? () {
                      setState(() {
                        _currentPageDynamic--;
                      });
                    }
                  : null,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 20),
            Text(
              'Page ${_currentPageDynamic + 1} of ${((_normalisasiDynamicData.length - 1) / _rowsPerPageDynamic + 1).toInt()}',
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: endIndex < _normalisasiDynamicData.length
                  ? () {
                      setState(() {
                        _currentPageDynamic++;
                      });
                    }
                  : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingAny =
        _isLoading ||
        _isLoadingProduk ||
        _isLoadingKriteria ||
        _isLoadingOriginal ||
        _isLoadingDynamic;

    return Scaffold(
      body: isLoadingAny
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildForm(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveNormalisasi,
                    child: const Text('Simpan Normalisasi'),
                  ),
                  const SizedBox(height: 30),
                  _buildFilterProdukDropdown(),
                  const SizedBox(height: 10),
                  const Text(
                    'Data Normalisasi Nilai',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildNormalisasiOriginalTable(),
                  const SizedBox(height: 40),
                  const Text(
                    'Data Hasil Normalisasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildNormalisasiDynamicTable(),
                ],
              ),
            ),
    );
  }
}
