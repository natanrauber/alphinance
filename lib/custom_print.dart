// ignore_for_file: avoid_print

import 'dart:convert';

enum PrintType {
  plainText,
  json,
}

enum PrintColor {
  red,
  green,
  yellow,
}

void customPrint(Object? object, {PrintType type = PrintType.plainText, PrintColor color = PrintColor.yellow}) {
  if (type == PrintType.json) object = const JsonEncoder.withIndent(' ').convert(object);
  final String timestamp = DateTime.now().toIso8601String().substring(11, 19);

  if (color == PrintColor.red) return print('$timestamp \x1B[31m$object\x1B[0m');
  if (color == PrintColor.green) return print('$timestamp \x1B[32m$object\x1B[0m');
  if (color == PrintColor.yellow) return print('$timestamp \x1B[33m$object\x1B[0m');
  return print('$timestamp $object');
}
