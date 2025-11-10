import 'package:flutter/material.dart';
import 'package:ddalgguk/core/navigation/main_navigation.dart';

void main() {
  runApp(const DdalggukApp());
}

class DdalggukApp extends StatelessWidget {
  const DdalggukApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ddalgguk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}
