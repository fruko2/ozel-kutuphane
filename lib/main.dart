import 'package:flutter/material.dart';

void main() {
  runApp(const OzelKutuphaneApp());
}

class OzelKutuphaneApp extends StatelessWidget {
  const OzelKutuphaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Özel Kütüphane',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Özel Kütüphane'),
          backgroundColor: Colors.deepPurpleContainer,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded, size: 80, color: Colors.deepPurple),
              SizedBox(height: 16),
              Text(
                'Kütüphane Uygulamasına Hoş Geldiniz!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Otomatik derleme ile oluşturulan ilk sürüm.'),
            ],
          ),
        ),
      ),
    );
  }
}
