import 'package:flutter/material.dart';
import 'package:tripmaniaapp/main.dart';

void main() {
  runApp(const ItemsFormScreen());
}

class ItemsFormScreen extends StatelessWidget {
  const ItemsFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Items Form',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Items Form'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: const Center(
          child: Text('Form to Add/Edit Items'),
        ),
      ),
    );
  }
}