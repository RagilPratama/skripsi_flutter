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

  bool _isLoading = true;
  bool _isLoadingProduk = true;
  bool _isLoadingKriteria = true;

  final String normalisasiApiUrl =
      'https://bb3e9ca8413f.ngrok-free.app/nilai-awal';
  final String produkApiUrl =
      'https://bb3e9ca8413f.ngrok-free.app/dimsum-variant';
  final String kriteriaApiUrl =
      'https://bb3e9ca8413f.ngrok-free.app/criteria-weight';

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
      }
    } catch (e) {
      setState(() => _isLoadingProduk = false);
      _showError('Failed to load produk: $e');
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
      }
    } catch (e) {
      setState(() => _isLoadingKriteria = false);
      _showError('Failed to load kriteria: $e');
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
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load normalisasi: $e');
    }
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
            items: _kriteriaList.map((kriteria) {
              return DropdownMenuItem<int>(
                value: kriteria['id'],
                child: Text(
                  kriteria['criteria_name'] ?? 'Kriteria ${kriteria['id']}',
                ),
              );
            }).toList(),
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

  Widget _buildNormalisasiList() {
    if (_normalisasiList.isEmpty) {
      return const Center(child: Text('Tidak ada data normalisasi'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Normalisasi Nilai Awal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading || _isLoadingProduk || _isLoadingKriteria
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
                  _buildNormalisasiList(),
                ],
              ),
            ),
    );
  }
}
