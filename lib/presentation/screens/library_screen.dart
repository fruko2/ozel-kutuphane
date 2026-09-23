import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/book.dart';
import '../../domain/models/reading_status.dart';
import '../providers/library_provider.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<LibraryProvider>(builder: (context, provider, _) {
        final books = provider.visibleBooks;
        return Scaffold(
          appBar: AppBar(title: const Text('Kütüphane-i Şahsî')),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Eser, müellif, ISBN veya tür ara'),
                onChanged: provider.setSearch,
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  _filter(provider, null, 'Tümü'),
                  ...ReadingStatus.values.map((status) => _filter(provider, status, status.label)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: provider.grouping,
                decoration: const InputDecoration(labelText: 'Sıralama / Gruplama', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'added', child: Text('Kütüphaneye ekleme tarihi')),
                  DropdownMenuItem(value: 'author', child: Text('Müellif ve çıkış yılı')),
                  DropdownMenuItem(value: 'category', child: Text('Çeşit / Tür')),
                  DropdownMenuItem(value: 'year', child: Text('Çıkış yılı')),
                ],
                onChanged: (value) => provider.setGrouping(value ?? 'added'),
              ),
            ),
            const SizedBox(height: 7),
            Expanded(child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                    ? const Center(child: Text('Bu ölçütlerde eser bulunamadı.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 105),
                        itemCount: books.length,
                        itemBuilder: (_, index) => _BookTile(book: books[index]),
                      )),
          ]),
        );
      });

  Widget _filter(LibraryProvider provider, ReadingStatus? status, String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: provider.statusFilter == status,
          onSelected: (_) => provider.setStatusFilter(status),
        ),
      );
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              BookCover(book),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(book.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (book.subtitle.isNotEmpty) Text(book.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(book.author.isEmpty ? 'Müellif belirtilmedi' : book.author),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [Chip(label: Text(book.status.label), visualDensity: VisualDensity.compact), if (book.publicationYear > 0) Chip(label: Text('${book.publicationYear}'), visualDensity: VisualDensity.compact)]),
              ])),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      );
}
