import 'package:alphinance/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const double _checkboxColumnWidth = 36;
  static const double _uncheckedRowOpacity = 0.35;

  String? input;
  String? rawFilter;
  String? sortByColumn;
  String? groupByColumn;
  List<String> headers = <String>[];
  List<Map<String, dynamic>> itemList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> filteredList = <Map<String, dynamic>>[];
  List<bool> _includedFlags = <bool>[];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              _filterTextField(),
              const SizedBox(height: 10),
              _listViewHeader(),
              const SizedBox(height: 5),
              _listView(),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  _inputTextField(),
                  const SizedBox(width: 10),
                  _primaryButton(),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _filterTextField() => SizedBox(
        height: 56,
        child: TextField(
          decoration: const InputDecoration(hintText: 'Filter (e.g. text, !exclude)'),
          expands: true,
          maxLines: null,
          onChanged: (String value) {
            rawFilter = value;
            _parseCsvToJson();
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
      if (add && exclude == false && groupByColumn == null) filteredList.add(e);
      if (add && exclude == false && groupByColumn != null) {
        if (_isIncluded(e) == false) {
          filteredList.add(e);
          continue;
        }
        Map<String, dynamic>? match = filteredList.firstWhereOrNull(
          (Map<String, dynamic> i) => i[groupByColumn] == e[groupByColumn] && _isIncluded(i),
        );
        if (match != null) {
          if (match['count'] is num) {
            match['count'] = (match['count'] as num) + 1;
          } else {
            match['count'] = 2;
          }
          for (String key in e.keys) {
            if (key != 'count') {
              if (num.tryParse(e[key]) != null && num.tryParse(match[key]) != null) {
                match[key] = (num.parse(e[key]) + num.parse(match[key])).toStringAsFixed(2);
              }
            }
          }
        } else {
          filteredList.add(e);
        }
      }
    }
    if (sortByColumn != null) {
      filteredList.sort(
        (Map<String, dynamic> a, Map<String, dynamic> b) {
          if (num.tryParse(a[sortByColumn]) != null && num.tryParse(b[sortByColumn]) != null) {
            return num.parse(b[sortByColumn]).compareTo(num.parse(a[sortByColumn]));
          }
          if (sortByColumn == groupByColumn) {
            if (b['count'] == null && a['count'] == null) return a[sortByColumn].compareTo(b[sortByColumn]);
            return (b['count'] ?? 0).compareTo(a['count'] ?? 0);
          }
          return a[sortByColumn].compareTo(b[sortByColumn]);
        },
      );
    }
    setState(() {});
  }

  Widget _listViewHeader() => SizedBox(
        height: 30,
        child: Row(
          children: <Widget>[
            _headerCheckboxCell(),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: headers.length,
                itemBuilder: (BuildContext context, int i) => Container(
                  width: _dataColumnWidth(context),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    border: Border.all(
                      color: Colors.black,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            sortByColumn = sortByColumn == headers[i] ? null : headers[i];
                            _parseCsvToJson();
                          },
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Icon(
                              Icons.arrow_downward_sharp,
                              size: 18,
                              color: sortByColumn == headers[i] ? AppColors.green : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${headers[i]}${_columnSumResult(i)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_canSumColumn(i) == false) ...<Widget>[
                        const SizedBox(width: 5),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              groupByColumn = groupByColumn == headers[i] ? null : headers[i];
                              _parseCsvToJson();
                            },
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: Icon(
                                Icons.filter_alt_sharp,
                                size: 18,
                                color: groupByColumn == headers[i] ? AppColors.green : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _headerCheckboxCell() => Container(
        width: _checkboxColumnWidth,
        decoration: BoxDecoration(
          color: AppColors.orange,
          border: Border.all(
            color: Colors.black,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      );

  double _dataColumnWidth(BuildContext context) {
    if (headers.isEmpty) return 10;
    return (MediaQuery.of(context).size.width - 40 - _checkboxColumnWidth) / headers.length;
  }

  bool _isIncluded(Map<String, dynamic> row) {
    int index = itemList.indexOf(row);
    if (index < 0 || index >= _includedFlags.length) return true;
    return _includedFlags[index];
  }

  void _setIncluded(Map<String, dynamic> row, bool value) {
    int index = itemList.indexOf(row);
    if (index < 0 || index >= _includedFlags.length) return;
    _includedFlags[index] = value;
    setState(() {});
  }

  bool _canSumColumn(int i) {
    if (filteredList.isEmpty) return false;
    if (num.tryParse(filteredList[0][headers[i]]) == null) return false;
    return true;
  }

  String _columnSumResult(int i) {
    if (_canSumColumn(i) == false) return '';
    num sum = 0;
    for (Map<String, dynamic> e in filteredList) {
      if (_isIncluded(e) == false) continue;
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
            itemBuilder: (BuildContext context, int i) {
              Map<String, dynamic> row = filteredList[i];
              bool included = _isIncluded(row);
              return SizedBox(
                height: 30,
                child: Row(
                  children: <Widget>[
                    _rowCheckboxCell(row, included),
                    Expanded(
                      child: Opacity(
                        opacity: included ? 1 : _uncheckedRowOpacity,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: headers.length,
                          itemBuilder: (BuildContext context, int j) => Container(
                            width: _dataColumnWidth(context),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.orange,
                                strokeAlign: BorderSide.strokeAlignCenter,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              headers[j] == groupByColumn && row['count'] != null
                                  ? '(${row['count']}) ${row[headers[j]]}'
                                  : row[headers[j]],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

  Widget _rowCheckboxCell(Map<String, dynamic> row, bool included) => Container(
        width: _checkboxColumnWidth,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.orange,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Checkbox(
            value: included,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: AppColors.orange),
            fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) return AppColors.orange;
              return Colors.transparent;
            }),
            checkColor: Colors.black,
            onChanged: (bool? value) => _setIncluded(row, value ?? false),
          ),
        ),
      );

  Widget _inputTextField() => Expanded(
        child: SizedBox(
          height: 56,
          child: TextField(
            decoration: const InputDecoration(hintText: 'Input (.csv format)'),
            expands: true,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            onChanged: (String value) => input = value,
          ),
        ),
      );

  Widget _primaryButton() => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            sortByColumn = null;
            groupByColumn = null;
            _includedFlags = <bool>[];
            _parseCsvToJson();
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
    List<bool> previousIncluded = List<bool>.from(_includedFlags);
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
        .map((List<String> row) => <String, dynamic>{
              for (int i = 0; i < headers.length; i++) headers[i]: row[i],
            })
        .toList();
    _includedFlags = <bool>[
      for (int i = 0; i < itemList.length; i++) i < previousIncluded.length ? previousIncluded[i] : true,
    ];

    _filterList();
  }
}
