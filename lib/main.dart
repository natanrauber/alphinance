import 'package:alphinance/home_page.dart';
import 'package:alphinance/theme.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Alphinance',
        theme: appTheme(),
        home: const MyHomePage(),
      );
}
