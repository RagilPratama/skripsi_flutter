import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DimsumForm extends StatefulWidget {
  const DimsumForm({super.key});

  @override
  State<DimsumForm> createState() => _DimsumFormState();
}

class _DimsumFormState extends State<DimsumForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modalController = TextEditingController();
  final _profitController = TextEditingController();

  List<Map<String, dynamic>> _dimsumList = [];
  bool _isLoading = true;

  final String apiUrl = 'https://d610b2f70ae5.ngrok-free.app/dimsum-variant';

  @override
  void initState() {
    super.initState();
    _loadDimsumData();
  }

  Future<void> _loadDimsumData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _dimsumList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load dimsum data: $e');
    }
  }

  Future<void> _addDimsum() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _nameController.text,
            'modal': int.parse(_modalController.text),
            'profit': int.parse(_profitController.text),
          }),
        );

        if (response.statusCode == 201) {
          _clearForm();
          _loadDimsumData();
          _showSuccess('Dimsum added successfully');
        } else {
          _showError('Failed to add dimsum');
        }
      } catch (e) {
        _showError('Error adding dimsum: $e');
      }
    }
  }

  Future<void> _updateDimsum(int index) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/${_dimsumList[index]['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'modal': int.parse(_modalController.text),
          'profit': int.parse(_profitController.text),
        }),
      );

      if (response.statusCode == 200) {
        _loadDimsumData();
        _clearForm();
        _showSuccess('Dimsum updated successfully');
      } else {
        _showError('Failed to update dimsum');
      }
    } catch (e) {
      _showError('Error updating dimsum: $e');
    }
  }

  Future<void> _deleteDimsum(int index) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/${_dimsumList[index]['id']}'),
      );
      if (response.statusCode == 200) {
        _loadDimsumData();
        _showSuccess('Dimsum deleted successfully');
      } else {
        _showError('Produk terdafatar pada normalisasi tidak dapat dihapus');
      }
    } catch (e) {
      _showError('Error deleting dimsum: $e');
    }
  }

  void _editDimsum(int index) {
    _nameController.text = _dimsumList[index]['name'];
    _modalController.text = _dimsumList[index]['modal'].toString();
    _profitController.text = _dimsumList[index]['profit'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Dimsum'),
        content: _buildForm(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _updateDimsum(index);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _modalController.clear();
    _profitController.clear();
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
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Dimsum',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan nama dimsum';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _modalController,
            decoration: const InputDecoration(
              labelText: 'Modal',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan modal';
              }
              if (int.tryParse(value) == null) {
                return 'Masukkan angka yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _profitController,
            decoration: const InputDecoration(
              labelText: 'Profit',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan profit';
              }
              if (int.tryParse(value) == null) {
                return 'Masukkan angka yang valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildForm(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addDimsum,
                    child: const Text('Tambah Dimsum'),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dimsumList.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(_dimsumList[index]['name']),
                          subtitle: Text(
                            'Modal: Rp ${_dimsumList[index]['modal']} - Profit: Rp ${_dimsumList[index]['profit']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editDimsum(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteDimsum(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
