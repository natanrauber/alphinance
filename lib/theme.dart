import 'package:alphinance/colors.dart';
import 'package:flutter/material.dart';

ThemeData appTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.dark,
        background: Colors.black,
        surface: Colors.black,
        onSurface: AppColors.orange,
      ),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: _inputBorder,
        errorBorder: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorder,
        disabledBorder: _inputBorder,
        focusedErrorBorder: _inputBorder,
      ),
    );

OutlineInputBorder get _inputBorder => const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      gapPadding: 0,
      borderSide: BorderSide(
        color: AppColors.orange,
      ),
    );
