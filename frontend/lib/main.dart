import 'package:flutter/material.dart';
import 'screens/exam_selection_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReadingRoomApp());
}

class ReadingRoomApp extends StatelessWidget {
  const ReadingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOEIC ACADEMY · TOEIC Exams',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 46, 128, 187),
          primary: const Color.fromARGB(255, 46, 128, 187),
          secondary: const Color.fromARGB(255, 118, 184, 234),
          surface: AppColors.surface,
          surfaceTint: Colors.transparent,
        ),
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Arial', 'sans-serif'],
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const ExamSelectionScreen(),
    );
  }
}
