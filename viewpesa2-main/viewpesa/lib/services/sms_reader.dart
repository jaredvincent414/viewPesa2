// lib/services/sms_reader.dart
import 'package:intl/intl.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction_models.dart';
import '../database/dbhelper.dart';

class SmsReader {
  final Telephony telephony = Telephony.instance;
  final DBHelper _dbHelper = DBHelper();

  Future<bool> requestSmsPermissions() async {
    try {
      if (await Permission.sms.status.isGranted) {
        print("SMS permissions already granted");
        return true;
      }
      final status = await Permission.sms.request();
      if (status.isGranted) {
        print("SMS permissions granted");
        return true;
      } else {
        print("SMS permissions denied: $status");
        return false;
      }
    } catch (e) {
      print("Error requesting SMS permissions: $e");
      return false;
    }
  }

  Future<void> initSmsListener([void Function(TransactionModel)? onNewTransaction]) async {
    bool permissionsGranted = await requestSmsPermissions();
    if (!permissionsGranted) {
      print("Cannot initialize SMS listener: permissions not granted");
      throw Exception('SMS permissions not granted');
    }

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        try {
          if (message.address?.toUpperCase().contains('MPESA') ?? false) {
            final transaction = _parseMpesaSms(message.body);
            if (transaction != null) {
              _dbHelper.insertTransaction(transaction);
              onNewTransaction?.call(transaction);
              print("New SMS transaction saved: ${transaction.id}");
            } else {
              print("Failed to parse SMS: ${message.body}");
            }
          } else {
            print("Non-M-PESA SMS ignored: ${message.address} - ${message.body}");
          }
        } catch (e) {
          print("Error processing incoming SMS: $e");
        }
      },
      onBackgroundMessage: _backgroundMessageHandler,
      listenInBackground: true,
    );
    print("SMS listener initialized");
  }

  Future<List<TransactionModel>> readMpesaTransactions() async {
    try {
      bool permissionsGranted = await requestSmsPermissions();
      if (!permissionsGranted) {
        throw Exception('SMS permissions not granted');
      }

      final List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).like('%MPESA%'),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      print('Retrieved ${messages.length} SMS messages');
      List<TransactionModel> transactions = [];
      for (var msg in messages) {
        final transaction = _parseMpesaSms(msg.body);
        if (transaction != null) {
          await _dbHelper.insertTransaction(transaction);
          transactions.add(transaction);
          print("Saved SMS transaction: ${transaction.id}");
        } else {
          print("Failed to parse SMS: ${msg.body}");
        }
      }
      print('Parsed ${transactions.length} transactions');
      return transactions;
    } catch (e, stackTrace) {
      print('Error reading SMS: $e\n$stackTrace');
      throw Exception('Failed to read SMS: $e');
    }
  }

  TransactionModel? _parseMpesaSms(String? body) {
    if (body == null) {
      print("SMS body is null");
      return null;
    }

    // General regex for most M-PESA transactions
    final regex = RegExp(
      r'(\w+\d+\w*)\s*Confirmed[\.\s]*(?:You have received|Sent|Give|Paid|Bought|Withdrawn)\s*(?:KES|KSh)?([\d,\.]+)\s*(?:from|to|for|at)\s*([A-Za-z\s]+?)(?:\s*(?:\+254\d{9}|\d{10}))?\s*(?:on)\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s*at\s*(\d{1,2}:\d{2}\s*(?:AM|PM)?)?(?:.*?New M-PESA balance is (?:KES|KSh)?([\d,\.]+))?(?:.*?Transaction cost, (?:KES|KSh)?([\d,\.]+))?',
      caseSensitive: false,
    );

    final match = regex.firstMatch(body);
    if (match != null) {
      final id = match[1] ?? 'SMS_${body.hashCode}';
      final amountStr = match[2]!.replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0.0;
      final party = match[3]?.trim() ?? 'Unknown';
      final date = match[4]!.replaceAll('-', '/');
      final time = match[5] ?? DateFormat('hh:mm a').format(DateTime.now());
      final balanceStr = match[6]?.replaceAll(',', '') ?? '0.0';
      final balance = double.tryParse(balanceStr) ?? 0.0;
      final costStr = match[7]?.replaceAll(',', '') ?? '0.0';
      final cost = double.tryParse(costStr) ?? 0.0;

      String type;
      List<String> tags;
      String sender = 'Unknown';
      String receiver = 'Unknown';

      if (RegExp(r'received', caseSensitive: false).hasMatch(body)) {
        type = 'M-PESA Received';
        tags = ['Received'];
        sender = party;
        receiver = 'You';
      } else if (RegExp(r'sent', caseSensitive: false).hasMatch(body)) {
        type = 'Sent';
        tags = ['Sent'];
        sender = 'You';
        receiver = party;
      } else if (RegExp(r'paid', caseSensitive: false).hasMatch(body)) {
        type = 'Paid';
        tags = ['Paid'];
        sender = 'You';
        receiver = party;
      } else if (RegExp(r'bought', caseSensitive: false).hasMatch(body)) {
        type = 'Airtime';
        tags = ['Airtime'];
        sender = 'You';
        receiver = 'Safaricom';
      } else if (RegExp(r'withdrawn', caseSensitive: false).hasMatch(body)) {
        type = 'Withdrawn';
        tags = ['Withdrawn'];
        sender = 'You';
        receiver = party;
      } else if (RegExp(r'give', caseSensitive: false).hasMatch(body)) {
        type = 'Give';
        tags = ['Give'];
        sender = 'You';
        receiver = party;
      } else {
        type = 'Unknown';
        tags = ['Unknown'];
      }

      return TransactionModel(
        id: id,
        type: type,
        sender: sender,
        receiver: receiver,
        amount: amount,
        cost: cost,
        balance: balance,
        time: '$date $time',
        tags: tags,
        party: party,
      );
    }

    // M-Shwari and Deposit transactions
    final mshwariRegex = RegExp(
      r'(\w+\d+\w*)\s*Confirmed[\.\s]*Your M-Shwari (?:Deposit|Loan) of\s*(?:KES|KSh)?([\d,\.]+)\s*(?:from|to)\s*M-Shwari\s*(?:on)\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s*at\s*(\d{1,2}:\d{2}\s*(?:AM|PM)?)?(?:.*?New M-PESA balance is (?:KES|KSh)?([\d,\.]+))?(?:.*?Transaction cost, (?:KES|KSh)?([\d,\.]+))?',
      caseSensitive: false,
    );

    final mshwariMatch = mshwariRegex.firstMatch(body);
    if (mshwariMatch != null) {
      final id = mshwariMatch[1] ?? 'SMS_${body.hashCode}';
      final amountStr = mshwariMatch[2]!.replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0.0;
      final date = mshwariMatch[3]!.replaceAll('-', '/');
      final time = mshwariMatch[4] ?? DateFormat('hh:mm a').format(DateTime.now());
      final balanceStr = mshwariMatch[5]?.replaceAll(',', '') ?? '0.0';
      final balance = double.tryParse(balanceStr) ?? 0.0;
      final costStr = mshwariMatch[6]?.replaceAll(',', '') ?? '0.0';
      final cost = double.tryParse(costStr) ?? 0.0;

      final type = RegExp(r'deposit', caseSensitive: false).hasMatch(body)
          ? 'M-Shwari Deposit'
          : 'M-Shwari Loan';
      final tags = [type];
      final sender = RegExp(r'deposit', caseSensitive: false).hasMatch(body) ? 'You' : 'M-Shwari';
      final receiver = RegExp(r'deposit', caseSensitive: false).hasMatch(body) ? 'M-Shwari' : 'You';

      print('Parsed M-Shwari: ID=$id, Type=$type, Sender=$sender, Receiver=$receiver, Amount=$amount, Cost=$cost, Balance=$balance, Time=$date $time');

      return TransactionModel(
        id: id,
        type: type,
        sender: sender,
        receiver: receiver,
        amount: amount,
        cost: cost,
        balance: balance,
        time: '$date $time',
        tags: tags,
        party: 'M-Shwari',
      );
    }

    // Reversal transactions
    final reversalRegex = RegExp(
      r'(\w+\d+\w*)\s*Reversed[\.\s]*(?:KES|KSh)?([\d,\.]+)\s*(?:from|to)\s*([A-Za-z\s]+?)(?:\s*(?:\+254\d{9}|\d{10}))?\s*(?:on)\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s*at\s*(\d{1,2}:\d{2}\s*(?:AM|PM)?)?',
      caseSensitive: false,
    );

    final reversalMatch = reversalRegex.firstMatch(body);
    if (reversalMatch != null) {
      final id = reversalMatch[1]!;
      final amountStr = reversalMatch[2]!.replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0.0;
      final party = reversalMatch[3]?.trim() ?? 'Unknown';
      final date = reversalMatch[4]!.replaceAll('-', '/');
      final time = reversalMatch[5] ?? DateFormat('hh:mm a').format(DateTime.now());
      final sender = RegExp(r'from', caseSensitive: false).hasMatch(body) ? party : 'You';
      final receiver = RegExp(r'to', caseSensitive: false).hasMatch(body) ? party : 'You';

      print('Parsed Reversal: ID=$id, Type=Reversed, Sender=$sender, Receiver=$receiver, Amount=$amount, Time=$date $time');

      return TransactionModel(
        id: id,
        type: 'Reversed',
        sender: sender,
        receiver: receiver,
        amount: amount,
        cost: 0.0,
        balance: 0.0,
        time: '$date $time',
        tags: ['Reversed'],
        party: party,
      );
    }

    print("No match for SMS: $body");
    return null;
  }

  static void _backgroundMessageHandler(SmsMessage message) async {
    print("Background SMS received: ${message.body}");
    if (message.address?.toUpperCase().contains('MPESA') ?? false) {
      final smsReader = SmsReader();
      final transaction = smsReader._parseMpesaSms(message.body);
      if (transaction != null) {
        final dbHelper = DBHelper();
        await dbHelper.database;
        await dbHelper.insertTransaction(transaction);
        print("Background transaction saved: ${transaction.id}");
      } else {
        print("Background SMS parse failed: ${message.body}");
      }
    }
  }
}