import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/constants/ui_constants.dart';
import 'package:saver/components/ui_components.dart';


/*<-------This file contain theme data of the app and initial custom default widget-------->*/

class AppThemeData {
  static final ThemeData appThemeData = ThemeData(
    useMaterial3: true,
    fontFamily: AppUIConstants.fontFamilySFProText,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
      surfaceBright: AppColors.background,
      surfaceContainer: AppColors.background,
      surfaceContainerHigh: AppColors.background,
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    disabledColor: AppColors.disabled,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: AppUIComponents.borderRadius10,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: AppUIComponents.borderRadius10,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(44),
        shape: RoundedRectangleBorder(
          borderRadius: AppUIComponents.borderRadius10,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(44),
        shape: RoundedRectangleBorder(
          borderRadius: AppUIComponents.borderRadius10,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: CircleBorder(),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: AppUIComponents.borderRadius10,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.primaryText),
      displayMedium: TextStyle(color: AppColors.primaryText),
      displaySmall: TextStyle(color: AppColors.primaryText),
      headlineMedium: TextStyle(color: AppColors.primaryText),
      labelLarge: TextStyle(fontSize: 16, color: AppColors.primaryText),
      bodyLarge: TextStyle(color: AppColors.primaryText),
      bodyMedium: TextStyle(color: AppColors.secondaryText),
      bodySmall: TextStyle(color: AppColors.secondaryText),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      errorMaxLines: 5,
      hintStyle: TextStyle(color: AppColors.tertiary),
      border: OutlineInputBorder(
        borderRadius: AppUIComponents.borderRadius10,
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppUIComponents.borderRadius10,
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontFamily: AppUIConstants.fontFamilySFProText,
        color: AppColors.primaryText,
        fontWeight: FontWeight.w700,
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: AppUIComponents.borderRadius10,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: AppColors.primaryText.withValues(alpha: 0.5)),
      fillColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Color(0xFFFD6B22);
        }
        return Colors.white;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: AppUIComponents.borderRadius4,
      ),
    ),
    // iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom()),
  );
}
