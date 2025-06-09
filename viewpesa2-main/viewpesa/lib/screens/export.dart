// lib/screens/export.dart
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import '../database/dbhelper.dart';
import '../services/sms_reader.dart';
import 'dart:io';
import '../providers/theme_provider.dart';

const String syncTask = 'com.viewpesa.syncTask';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == syncTask) {
      final smsReader = SmsReader();
      try {
        bool permissionsGranted = await smsReader.requestSmsPermissions();
        if (permissionsGranted) {
          await smsReader.readMpesaTransactions();
        }
      } catch (e) {
        print('Background sync error: $e');
      }
    }
    return Future.value(true);
  });
}

class ViewpesaExport extends StatefulWidget {
  const ViewpesaExport({super.key});

  @override
  State<ViewpesaExport> createState() => _ViewpesaExportState();
}

class _ViewpesaExportState extends State<ViewpesaExport> {
  bool isSmsReaderActive = false;
  bool isAutoSyncEnabled = false;
  int messagesRead = 0;

  @override
  void initState() {
    super.initState();
    _loadMessageCount();
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  Future<void> _loadMessageCount() async {
    final dbHelper = DBHelper();
    final transactions = await dbHelper.getTransactions();
    if (mounted) {
      setState(() {
        messagesRead = transactions.length;
      });
    }
  }

  Future<void> _importSmsTransactions() async {
    final smsReader = SmsReader();
    try {
      bool permissionsGranted = await smsReader.requestSmsPermissions();
      if (permissionsGranted) {
        await smsReader.readMpesaTransactions();
        await smsReader.initSmsListener();
        await _loadMessageCount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported $messagesRead transactions')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS permissions required')),
          );
        }
      }
    } catch (e) {
      print('SMS Import Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading SMS: $e')),
        );
      }
    }
  }

  Future<void> _exportToCsv() async {
    final dbHelper = DBHelper();
    final transactions = await dbHelper.getTransactions();

    List<List<dynamic>> rows = [
      ['ID', 'Type', 'Sender', 'Receiver', 'Amount', 'Cost', 'Balance', 'Time', 'Tags'],
      ...transactions.map((t) => [
        t.id,
        t.type,
        t.sender,
        t.receiver,
        t.amount,
        t.cost,
        t.balance,
        t.time,
        t.tags.join(','),
      ]),
    ];

    String csv = const ListToCsvConverter().convert(rows);
    try {
      String? outputPath = await FilePicker.platform.getDirectoryPath();
      if (outputPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No directory selected')),
          );
        }
        return;
      }
      final path = '$outputPath/transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    }
  }

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  void _toggleAutoSync(bool val) {
    if (mounted) {
      setState(() {
        isAutoSyncEnabled = val;
      });
    }
    if (val) {
      Workmanager().registerPeriodicTask(
        'syncTask',
        syncTask,
        frequency: const Duration(minutes: 15),
      );
      _importSmsTransactions();
    } else {
      Workmanager().cancelAll();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto Sync ${val ? 'enabled' : 'disabled'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Export',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.greenAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _requestStoragePermission();
                          await _exportToCsv();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent[700],
                        ),
                        icon: const Icon(Icons.file_copy),
                        label: const Text('Export CSV'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Auto Sync'),
                    value: isAutoSyncEnabled,
                    onChanged: _toggleAutoSync,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: Provider.of<ThemeProvider>(context).isDarkMode,
                    onChanged: (val) {
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('SMS Reader Active'),
                      value: isSmsReaderActive,
                      onChanged: (val) async {
                        if (mounted) setState(() => isSmsReaderActive = val);
                        if (val) {
                          await _importSmsTransactions();
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text('Status:'),
                    const SizedBox(height: 4),
                    Text('Messages Read: $messagesRead'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _requestStoragePermission();
                        await _exportToCsv();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[700],
                      ),
                      child: const Text('Export Data'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}