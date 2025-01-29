import 'package:finance/colors.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Finance',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.orange,
            brightness: Brightness.dark,
            background: Colors.black,
            surface: Colors.black,
            onSurface: AppColors.orange,
          ),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? input;
  String? rawFilter;
  List<String> headers = <String>[];
  List<Map<String, dynamic>> itemList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> filteredList = <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              _filterTextField(),
              const SizedBox(height: 20),
              _listViewHeader(),
              const SizedBox(height: 5),
              _listView(),
              const SizedBox(height: 20),
              _inputTextField(),
              const SizedBox(height: 20),
              _primaryButton(),
            ],
          ),
        ),
      );

  Widget _filterTextField() => SizedBox(
        height: 58,
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Filter (e.g. text, !exclude)',
          ),
          onSubmitted: (String value) {
            rawFilter = value;
            _filterList();
          },
        ),
      );

  void _filterList() {
    filteredList.clear();
    List<String> filters = rawFilter?.split(',').map((String e) => e.trim().toLowerCase()).toList() ?? <String>[''];
    for (Map<String, dynamic> e in itemList) {
      bool add = false;
      bool exclude = false;
      for (String key in e.keys) {
        for (String f in filters) {
          if (e[key].toString().toLowerCase().contains(f)) add = true;
          if (f.startsWith('!') && e[key].toString().toLowerCase().contains(f.substring(1))) exclude = true;
        }
      }
      if (filters.every((String f) => f.startsWith('!'))) add = true;
      if (add && exclude == false) filteredList.add(e);
    }
    setState(() {});
  }

  Widget _listViewHeader() => SizedBox(
        height: 30,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: headers.length,
          itemBuilder: (BuildContext context, int i) => Container(
            width: headers.isEmpty ? 10 : (MediaQuery.of(context).size.width - 40) / (headers.length),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.orange,
              border: Border.all(
                color: Colors.black,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Text(
                    '${headers[i]}${_columnSumResult(i)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _columnSumResult(int i) {
    if (filteredList.isEmpty) return '';
    if (num.tryParse(filteredList[0][headers[i]]) == null) return '';
    num sum = 0;
    for (Map<String, dynamic> e in filteredList) {
      num? val = num.tryParse(e[headers[i]]);
      sum += val ?? 0;
    }
    return ' (${sum.toStringAsFixed(2)})';
  }

  Expanded _listView() => Expanded(
        child: SingleChildScrollView(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: filteredList.length,
            itemBuilder: (BuildContext context, int i) => SizedBox(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: headers.length,
                itemBuilder: (BuildContext context, int j) => Container(
                  width: headers.isEmpty ? 10 : (MediaQuery.of(context).size.width - 40) / (headers.length),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.orange,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    filteredList[i][headers[j]],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  SizedBox _inputTextField() => SizedBox(
        height: 58,
        child: TextField(
          decoration: const InputDecoration(hintText: 'Input (.csv format)'),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          onChanged: (String value) => input = value,
        ),
      );

  Widget _primaryButton() => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _parseCsvToJson,
          child: Container(
            height: 50,
            color: AppColors.orange,
            alignment: Alignment.center,
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

  void _parseCsvToJson() {
    itemList.clear();
    List<List<String>>? rows = input
        ?.split(RegExp(r'\r?\n'))
        .where((String row) => row.isNotEmpty)
        .map((String row) => row.split(','))
        .toList();

    if (rows == null || rows.isEmpty) return;

    headers = rows.first;
    itemList = rows
        .skip(1)
        .map((List<String> row) => <String, String>{
              for (int i = 0; i < headers.length; i++) headers[i]: row[i],
            })
        .toList();

    _filterList();
  }
}
