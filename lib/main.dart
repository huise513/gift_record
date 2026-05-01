import 'package:flutter/material.dart';
import 'screens/gift_books_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GiftRecordApp());
}

class GiftRecordApp extends StatelessWidget {
  const GiftRecordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '礼金记录',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
        fontFamily: 'Microsoft YaHei',
      ),
      home: const GiftBooksScreen(),
    );
  }
}
