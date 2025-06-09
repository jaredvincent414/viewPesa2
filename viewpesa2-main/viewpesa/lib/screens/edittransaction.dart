// lib/screens/edittransaction.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dbhelper.dart';
import '../models/transaction_models.dart';

class ViewpesaEdit extends StatefulWidget {
  const ViewpesaEdit({super.key});

  @override
  State<ViewpesaEdit> createState() => _ViewpesaEditState();
}

class _ViewpesaEditState extends State<ViewpesaEdit> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper();
  TransactionModel? _transaction;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        _amountController.text = args['amount'].toString();
        _costController.text = args['cost'].toString();
        _balanceController.text = args['balance'].toString();
        _dateController.text = args['time'].split(' ')[0];
        _timeController.text = args['time'].split(' ').sublist(1).join(' ');
        _tags = (args['tag'] as String?)?.split(',').where((tag) => tag.isNotEmpty).toList() ?? [];
        _transaction = TransactionModel(
          id: args['transactionId'],
          type: args['type'],
          sender: args['sender'],
          receiver: args['receiver'],
          amount: args['amount'],
          cost: args['cost'],
          balance: args['balance'],
          time: args['time'],
          tags: _tags,
          party: args['party'],
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _costController.dispose();
    _balanceController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final updatedTransaction = TransactionModel(
        id: _transaction!.id,
        type: _transaction!.type,
        sender: _transaction!.sender,
        receiver: _transaction!.receiver,
        amount: double.parse(_amountController.text),
        cost: double.parse(_costController.text),
        balance: double.parse(_balanceController.text),
        time: '${_dateController.text} ${_timeController.text}',
        tags: _tags,
        party: _transaction!.party,
      );
      try {
        await _dbHelper.updateTransaction(updatedTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction updated')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating transaction: $e')),
          );
        }
      }
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          "Edit Transaction",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[700],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an amount';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: 'Cost',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a cost';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: 'Balance',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a balance';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date (dd/MM/yy)',
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  readOnly: true,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && mounted) {
                      _dateController.text = DateFormat('dd/MM/yy').format(pickedDate);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a date';
                    try {
                      DateFormat('dd/MM/yy').parseStrict(value);
                      return null;
                    } catch (_) {
                      return 'Use format: dd/MM/yy';
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Time (HH:mm AM/PM)',
                    suffixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  readOnly: true,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null && mounted) {
                      _timeController.text = pickedTime.format(context);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a time';
                    final regex = RegExp(r'^\d{1,2}:\d{2}\s?(AM|PM)$', caseSensitive: false);
                    return regex.hasMatch(value) ? null : 'Use format: HH:mm AM/PM';
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    labelText: 'Add Tag',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addTag(_tagController.text.trim()),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onFieldSubmitted: (value) => _addTag(value.trim()),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _tags
                      .map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}