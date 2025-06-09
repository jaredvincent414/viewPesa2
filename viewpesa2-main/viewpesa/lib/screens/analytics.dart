// lib/screens/analytics.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/dbhelper.dart';
import '../models/transaction_models.dart';

class ViewpesaAnalysis extends StatefulWidget {
  const ViewpesaAnalysis({super.key});

  @override
  State<ViewpesaAnalysis> createState() => _ViewpesaAnalysisState();
}

class _ViewpesaAnalysisState extends State<ViewpesaAnalysis> {
  final TextEditingController _searchController = TextEditingController();
  int _expandedIndex = -1;
  List<TransactionModel> _transactions = [];
  final DBHelper _dbHelper = DBHelper();
  double _currentBalance = 0.0;
  double _totalSpent = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(() {
      _searchTransactions(_searchController.text);
    });
  }

  Future<void> _loadTransactions() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final transactions = await _dbHelper.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _totalSpent = transactions.fold(
            0.0,
                (sum, t) => sum + (['Sent', 'Paid', 'Withdrawn', 'Give', 'Airtime'].contains(t.type) ? t.amount : 0.0),
          );
          _currentBalance = transactions.fold(
            0.0,
                (sum, t) {
              switch (t.type) {
                case 'M-PESA Received':
                case 'Reversed':
                  return sum + t.amount;
                case 'Sent':
                case 'Paid':
                case 'Withdrawn':
                case 'Give':
                case 'Airtime':
                  return sum - t.amount;
                default:
                  return sum;
              }
            },
          );
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading transactions: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load transactions')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchTransactions(String query) async {
    if (query.isEmpty) {
      await _loadTransactions();
    } else {
      final transactions = await _dbHelper.searchTransactions(query);
      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }
    }
  }

  void _handleCardTap(int index) {
    if (mounted) {
      setState(() {
        _expandedIndex = (_expandedIndex == index) ? -1 : index;
      });
    }
  }

  Map<String, double> _aggregateByTag() {
    final Map<String, double> tagTotals = {};
    for (var t in _transactions) {
      if (t.tags.isNotEmpty) {
        final amountPerTag = t.amount / t.tags.length; // Distribute amount evenly across tags
        for (var tag in t.tags) {
          tagTotals[tag] = (tagTotals[tag] ?? 0) + amountPerTag;
        }
      }
    }
    return tagTotals;
  }

  List<FlSpot> _aggregateByDate() {
    final Map<String, double> dateTotals = {};
    for (var t in _transactions) {
      final date = t.time.split(' ')[0];
      dateTotals[date] = (dateTotals[date] ?? 0) + t.amount;
    }
    final sortedDates = dateTotals.keys.toList()..sort();
    return sortedDates
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), dateTotals[e.value]!))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagTotals = _aggregateByTag();
    final dateSpots = _aggregateByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Search Transactions",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "e.g., groceries, John Doe...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildBalanceCard(
                  "Current Balance",
                  "KES ${_currentBalance.toStringAsFixed(2)}"),
              const SizedBox(width: 10),
              _buildBalanceCard(
                  "Total Spent", "KES ${_totalSpent.toStringAsFixed(2)}"),
            ],
          ),
          const SizedBox(height: 20),
          _buildAnimatedChartCard(
            0,
            "Spending by Tag (Bar)",
            tagTotals.isEmpty
                ? const Center(child: Text('No data for Bar Chart'))
                : BarChart(
              BarChartData(
                barGroups: tagTotals.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: Colors.green[700],
                    ),
                  ],
                ))
                    .toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          tagTotals.keys.elementAt(value.toInt()),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
          _buildAnimatedChartCard(
            1,
            "Spending by Tag (Pie)",
            tagTotals.isEmpty
                ? const Center(child: Text('No data for Pie Chart'))
                : PieChart(
              PieChartData(
                sections: tagTotals.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => PieChartSectionData(
                  value: e.value.value,
                  title:
                  '${e.value.key}\n${e.value.value.toStringAsFixed(0)}',
                  color: Colors.primaries[
                  e.key % Colors.primaries.length],
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ))
                    .toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          _buildAnimatedChartCard(
            2,
            "Spending Over Time (Line)",
            dateSpots.isEmpty
                ? const Center(child: Text('No data for Line Chart'))
                : LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: dateSpots,
                    isCurved: true,
                    color: Colors.green[700],
                    dotData: FlDotData(show: true),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= dateSpots.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _transactions[index]
                                .time
                                .split(' ')[0],
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, String content) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedChartCard(int index, String label, Widget chart) {
    final bool isExpanded = _expandedIndex == index;
    return GestureDetector(
      onTap: () => _handleCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: isExpanded ? 300 : 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isExpanded ? 18 : 14,
                  fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }
}