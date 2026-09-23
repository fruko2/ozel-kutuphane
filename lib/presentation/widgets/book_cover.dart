import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/book.dart';

class BookCover extends StatelessWidget {
  const BookCover(this.book, {this.width = 86, this.height = 126, super.key});
  final Book book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (book.localCoverPath.isNotEmpty && File(book.localCoverPath).existsSync()) {
      child = Image.file(File(book.localCoverPath), fit: BoxFit.cover);
    } else if (book.coverUrl.startsWith('http')) {
      child = Image.network(
        book.coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else {
      child = _fallback(context);
    }
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFFD6E7DF), Color(0xFFEADDBF)]),
        boxShadow: const [BoxShadow(color: Color(0x220F3E34), blurRadius: 14, offset: Offset(4, 7))],
      ),
      child: child,
    );
  }

  Widget _fallback(BuildContext context) => Center(
        child: Text(
          book.title.trim().isEmpty ? 'K' : book.title.trim()[0].toUpperCase(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}

