import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import './colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter App',
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  Map<String, int> _dateCounts = {};

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/count.json');
  }

  Future<File> writeContent(Map<String, int> dateCounts) async {
    final file = await _localFile;
    String jsonString = jsonEncode(dateCounts);
    return file.writeAsString(jsonString);
  }

  Future<Map<String, int>> readContent() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      Map<String, dynamic> rawMap = jsonDecode(contents);
      return rawMap.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  void _updateCount(String date, int newCount) {
    setState(() {
      _dateCounts[date] = newCount;
    });
    writeContent(_dateCounts);
  }

  String getFormattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void initState() {
    super.initState();
    readContent().then((data) {
      setState(() {
        _dateCounts = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    String today = getFormattedDate(DateTime.now());
    int count = _dateCounts[today] ?? 0;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = CounterPage(
          title: widget.title,
          selectedDate: today,
          count: count,
          onCountChanged: (newCount) => _updateCount(today, newCount),
        );
        break;
      case 1:
        page = CalendarPage(title: 'Calendar', dateCounts: _dateCounts);
        break;
      case 2:
        page = StatisticsPage(title: 'Statistics', dateCounts: _dateCounts);
        break;
      default:
        throw UnimplementedError('no widget selected');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month),
                  label: Text('Calendar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_graph),
                  label: Text('Statistics'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(color: AppColors.secondary, child: page),
          ),
        ],
      ),
    );
  }
}

class CounterPage extends StatefulWidget {
  final String title;
  final String selectedDate;
  final int count;
  final ValueChanged<int> onCountChanged;

  const CounterPage({
    super.key,
    required this.title,
    required this.selectedDate,
    required this.count,
    required this.onCountChanged,
  });

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  late int _counter;

  @override
  void initState() {
    super.initState();
    _counter = widget.count;
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    widget.onCountChanged(_counter);
  }

  void _decrementCounter() {
    setState(() {
      if (_counter > 0) _counter--;
    });
    widget.onCountChanged(_counter);
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: Text(
          widget.title,
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat.yMMMMd('en_US').format(now),
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You have pushed the button: $_counter  times',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: _incrementCounter,
                  tooltip: 'Increase',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 50),
                FloatingActionButton(
                  onPressed: _decrementCounter,
                  tooltip: 'Decrease',
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final String title;
  final Map<String, int> dateCounts;

  const CalendarPage({
    super.key,
    required this.title,
    required this.dateCounts,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    int? selectedCount = widget.dateCounts[formattedDate];

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: Text(
          widget.title,
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat.yMMMMd('en_US').format(_selectedDate),
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedCount != null
                    ? 'Count on ${DateFormat.yMMMMd('en_US').format(_selectedDate)}: $selectedCount'
                    : 'No data for ${DateFormat.yMMMMd('en_US').format(_selectedDate)}',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticsPage extends StatefulWidget {
  final String title;
  final Map<String, int> dateCounts;

  const StatisticsPage({
    super.key,
    required this.title,
    required this.dateCounts,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String _selectedYear = DateFormat('yyyy').format(DateTime.now());

  int totalMonth = 0;
  double averageMonth = 0.0;
  MapEntry<String, int>? highestMonth;
  MapEntry<String, int>? lowestMonth;

  int totalYear = 0;
  double averageYear = 0.0;
  MapEntry<String, int>? highestYear;
  MapEntry<String, int>? lowestYear;

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final pickedMonth = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedMonth != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(pickedMonth);
        _analyzeSelectedMonth();
      });
    }
  }

  Future<void> _selectYear(BuildContext context) async {
    final pickedYear = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedYear != null) {
      setState(() {
        _selectedYear = DateFormat('yyyy').format(pickedYear);
        _analyzeSelectedYear();
      });
    }
  }

  void _analyzeSelectedMonth() {
    final entriesOfMonth = widget.dateCounts.entries
        .where((entry) => entry.key.startsWith(_selectedMonth))
        .toList();

    totalMonth = entriesOfMonth.fold(0, (sum, entry) => sum + entry.value);
    averageMonth = entriesOfMonth.isNotEmpty
        ? totalMonth / entriesOfMonth.length
        : 0.0;
    highestMonth = entriesOfMonth.isEmpty
        ? null
        : entriesOfMonth.reduce((a, b) => a.value > b.value ? a : b);
    lowestMonth = entriesOfMonth.isEmpty
        ? null
        : entriesOfMonth.reduce((a, b) => a.value < b.value ? a : b);
  }

  void _analyzeSelectedYear() {
    final entriesOfYear = widget.dateCounts.entries
        .where((entry) => entry.key.startsWith(_selectedYear))
        .toList();

    totalYear = entriesOfYear.fold(0, (sum, entry) => sum + entry.value);
    averageYear = entriesOfYear.isNotEmpty
        ? totalYear / entriesOfYear.length
        : 0.0;
    highestYear = entriesOfYear.isEmpty
        ? null
        : entriesOfYear.reduce((a, b) => a.value > b.value ? a : b);
    lowestYear = entriesOfYear.isEmpty
        ? null
        : entriesOfYear.reduce((a, b) => a.value < b.value ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedCount = widget.dateCounts[formattedDate];

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: Text(
          widget.title,
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Date selection and count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Select Date'),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat.yMMMMd('en_US').format(_selectedDate),

                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: $selectedCount',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Month selection and statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _selectMonth(context),
                    child: const Text('Select Month'),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedMonth,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total: $totalMonth',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Average: $averageMonth',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Highest: ${highestMonth!.key} : ${highestMonth!.value}',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lowest: ${lowestMonth!.key} : ${lowestMonth!.value}',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 20),

              //Yearly Review
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _selectYear(context),
                    child: Text('Select Year'),
                  ),
                  SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedYear,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total: $totalYear',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Average: $averageYear',

                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),

              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Highest: ${highestYear!.key} : ${highestYear!.value}',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lowest: ${lowestYear!.key} : ${lowestYear!.value}',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
