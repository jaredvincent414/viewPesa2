// lib/models/transaction_models.dart
class TransactionModel {
  final String id;
  final String type;
  final String sender;
  final String receiver;
  final double amount;
  final double cost;
  final double balance;
  final String time;
  final String party;
  final List<String> tags;

  TransactionModel({
    required this.id,
    required this.type,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.cost,
    required this.balance,
    required this.time,
    required this.tags,
    required this.party,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'party': party,
      'sender': sender,
      'receiver': receiver,
      'amount': amount,
      'cost': cost,
      'balance': balance,
      'time': time,
      'tags': tags.join(','), // Store as comma-separated string
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      sender: map['sender'] ?? map['party'] ?? 'Unknown',
      receiver: map['receiver'] ?? map['party'] ?? 'Unknown',
      amount: map['amount'],
      cost: map['cost'],
      balance: map['balance'],
      time: map['time'],
      tags: (map['tags'] as String?)?.split(',').where((tag) => tag.isNotEmpty).toList() ?? [],
      party: map['party'] ?? 'Unknown',
    );
  }
}