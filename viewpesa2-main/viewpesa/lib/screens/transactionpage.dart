// lib/screens/transactionpage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dbhelper.dart';
import '../models/transaction_models.dart';
import '../services/sms_reader.dart';
import '../utilities/transactioncard.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String selectedTag = 'All';
  DateTime? selectedDate;
  List<TransactionModel> transactions = [];
  List<TransactionModel> filteredTransactions = [];
  final DBHelper _dbHelper = DBHelper();
  final SmsReader _smsReader = SmsReader();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _initSmsReader();
    _searchController.addListener(() => _searchTransactions(_searchController.text));
  }

  Future<void> _loadTransactions() async {
    try {
      await _smsReader.readMpesaTransactions();
      final dbTransactions = await _dbHelper.getTransactions();
      if (mounted) {
        setState(() {
          transactions = dbTransactions;
          filteredTransactions = dbTransactions;
        });
      }
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  void _initSmsReader() async {
    try {
      bool permissionsGranted = await _smsReader.requestSmsPermissions();
      if (permissionsGranted) {
        _smsReader.initSmsListener((TransactionModel transaction) {
          if (mounted) {
            setState(() {
              transactions.insert(0, transaction);
              _applyFilters();
            });
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS permissions required to read transactions')),
          );
        }
      }
    } catch (e) {
      print('Error initializing SMS reader: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTransactions = transactions.where((t) {
        try {
          final matchesTag = selectedTag == 'All' || t.tags.contains(selectedTag);
          final transactionDate = DateFormat('dd/MM/yy').parse(t.time.split(' ')[0]);
          final matchesDate = selectedDate == null ||
              transactionDate.isAtSameMomentAs(selectedDate!) ||
              transactionDate.isAfter(selectedDate!);
          return matchesTag && matchesDate;
        } catch (e) {
          print('Error filtering transaction: $e');
          return false;
        }
      }).toList();
    });
  }

  void _searchTransactions(String query) {
    setState(() {
      filteredTransactions = transactions.where((t) {
        try {
          final matchesQuery = t.sender.toLowerCase().contains(query.toLowerCase()) ||
              t.receiver.toLowerCase().contains(query.toLowerCase()) ||
              t.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
          final matchesTag = selectedTag == 'All' || t.tags.contains(selectedTag);
          final transactionDate = DateFormat('dd/MM/yy').parse(t.time.split(' ')[0]);
          final matchesDate = selectedDate == null ||
              transactionDate.isAtSameMomentAs(selectedDate!) ||
              transactionDate.isAfter(selectedDate!);
          return matchesQuery && matchesTag && matchesDate;
        } catch (e) {
          print('Error searching transaction: $e');
          return false;
        }
      }).toList();
    });
  }

  List<String> getTags() {
    final tags = transactions.expand((t) => t.tags).where((tag) => tag.isNotEmpty).toSet().toList();
    return ['All', ...tags];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by tag, sender, or receiver',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pick Date'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedTag = 'All';
                        selectedDate = null;
                        _searchController.clear();
                        _applyFilters();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset Filters'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tag:'),
                    DropdownButton<String>(
                      value: selectedTag,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTag = newValue!;
                          _applyFilters();
                        });
                      },
                      items: getTags().map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? const Center(child: Text('No transactions match your filters'))
                    : ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final t = filteredTransactions[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/edit', arguments: {
                          'transactionId': t.id,
                          'type': t.type,
                          'party':t.party,
                          'sender': t.sender,
                          'receiver': t.receiver,
                          'amount': t.amount,
                          'cost': t.cost,
                          'balance': t.balance,
                          'time': t.time,
                          'tag': t.tags.join(','), // Pass tags as comma-separated string
                        });
                      },
                      child: TransactionCard(
                        type: t.type,
                        transactionId: t.id,
                        sender: t.sender,
                        receiver: t.receiver,
                        amount: t.amount,
                        cost: t.cost,
                        balance: t.balance,
                        time: t.time,
                        tags: t.tags, // Updated to List<String>
                        party: t.party,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}