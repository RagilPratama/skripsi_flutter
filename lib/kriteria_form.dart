import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KriteriaForm extends StatefulWidget {
  const KriteriaForm({super.key});

  @override
  State<KriteriaForm> createState() => _KriteriaFormState();
}

class _KriteriaFormState extends State<KriteriaForm> {
  final _formKey = GlobalKey<FormState>();
  final _criteriaNameController = TextEditingController();
  final _weightController = TextEditingController();

  List<Map<String, dynamic>> _kriteriaList = [];
  bool _isLoading = true;

  final String apiUrl = 'https://d610b2f70ae5.ngrok-free.app/criteria-weight';

  @override
  void initState() {
    super.initState();
    _loadKriteriaData();
  }

  Future<void> _loadKriteriaData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _kriteriaList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load kriteria data: $e');
    }
  }

  Future<void> _addKriteria() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'criteria_name': _criteriaNameController.text,
            'weight': double.parse(_weightController.text),
          }),
        );

        if (response.statusCode == 201) {
          _clearForm();
          _loadKriteriaData();
          _showSuccess('Kriteria added successfully');
        } else {
          _showError('Jumlah bobot kriteria tidak boleh lebih dari 1.0');
        }
      } catch (e) {
        _showError('Error adding kriteria: $e');
      }
    }
  }

  Future<void> _updateKriteria(int index) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/${_kriteriaList[index]['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'criteria_name': _criteriaNameController.text,
          'weight': double.parse(_weightController.text),
        }),
      );

      if (response.statusCode == 200) {
        _loadKriteriaData();
        _clearForm();
        _showSuccess('Kriteria updated successfully');
      } else {
        _showError('Failed to update kriteria');
      }
    } catch (e) {
      _showError('Error updating kriteria: $e');
    }
  }

  Future<void> _deleteKriteria(int index) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/${_kriteriaList[index]['id']}'),
      );

      if (response.statusCode == 204) {
        _loadKriteriaData();
        _showSuccess('Kriteria deleted successfully');
      } else {
        _showError('Kriteria tidak dapat dihapus karena masih digunakan');
      }
    } catch (e) {
      _showError('Error deleting kriteria: $e');
    }
  }

  void _editKriteria(int index) {
    _criteriaNameController.text = _kriteriaList[index]['criteria_name'];
    _weightController.text = _kriteriaList[index]['weight'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Kriteria'),
        content: _buildForm(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _updateKriteria(index);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _criteriaNameController.clear();
    _weightController.clear();
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
            controller: _criteriaNameController,
            decoration: const InputDecoration(
              labelText: 'Nama Kriteria',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan nama kriteria';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Bobot (0.0 - 1.0)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan bobot';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight < 0 || weight > 1) {
                return 'Masukkan bobot antara 0.0 dan 1.0';
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
                    onPressed: _addKriteria,
                    child: const Text('Tambah Kriteria'),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _kriteriaList.length,
                    itemBuilder: (context, index) {
                      final id = _kriteriaList[index]['id'];
                      return Card(
                        child: ListTile(
                          title: Text(_kriteriaList[index]['criteria_name']),
                          subtitle: Text(
                            'Bobot: ${_kriteriaList[index]['weight']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editKriteria(index),
                              ),
                              if (![1, 2, 3].contains(id))
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteKriteria(index),
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
