// lib/utilities/transactioncard.dart
import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final String type;
  final String transactionId;
  final String sender;
  final String receiver;
  final double amount;
  final double cost;
  final double balance;
  final String party;
  final String time;
  final List<String> tags; // Changed from String to List<String>

  const TransactionCard({
    super.key,
    required this.type,
    required this.transactionId,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.cost,
    required this.balance,
    required this.time,
    required this.tags,
    required this.party,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        title: Text(
          '$sender → $receiver',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type\n$time\nCost: KES ${cost.toStringAsFixed(2)}\nBalance: KES ${balance.toStringAsFixed(2)}'),
            if (tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12)))).toList(),
              ),
          ],
        ),
        trailing: Text(
          'KES ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: type == 'M-PESA Received' || type == 'Reversed' ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}