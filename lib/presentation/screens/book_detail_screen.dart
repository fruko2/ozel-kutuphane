import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book.dart';
import '../../domain/models/book_loan.dart';
import '../../domain/models/library_entry.dart';
import '../../domain/models/reading_status.dart';
import '../providers/library_provider.dart';
import '../widgets/book_cover.dart';
import 'book_form_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({required this.bookId, super.key});
  final String bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book(LibraryProvider provider) {
    for (final item in provider.books) {
      if (item.id == widget.bookId) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(builder: (context, provider, _) {
      final book = _book(provider);
      if (book == null) return const Scaffold(body: Center(child: Text('Eser kaydı bulunamadı.')));
      return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Eser Tafsilatı'),
            actions: [
              IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Paylaş', onPressed: () => _share(book, provider)),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? _edit(book) : _delete(book, provider),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Eser hakkında'),
                Tab(text: 'Mütalaa ilerlemesi'),
                Tab(text: 'İktibas ve derkenarlar'),
                Tab(text: 'Emanet'),
              ],
            ),
          ),
          body: Column(
            children: [
              _Header(book: book),
              Expanded(
                child: TabBarView(
                  children: [
                    _About(book: book),
                    _Progress(book: book),
                    _Entries(book: book),
                    _Loan(book: book),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _edit(Book book) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BookFormScreen(book: book)));
  }

  Future<void> _delete(Book book, LibraryProvider provider) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eser silinsin mi?'),
        content: Text('${book.title} ve bağlı iktibas, derkenar ve emanet kayıtları silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await provider.deleteBook(book);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _share(Book book, LibraryProvider provider) async {
    final entries = await provider.entriesFor(book.id);
    if (!mounted) return;
    var includeEntries = false;
    var includeReview = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eseri paylaş', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(book.title, style: Theme.of(context).textTheme.titleMedium),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: includeEntries,
                  onChanged: entries.isEmpty ? null : (value) => setSheetState(() => includeEntries = value ?? false),
                  title: const Text('İktibas ve derkenarları ekle'),
                  subtitle: Text(entries.isEmpty ? 'Kayıt yok' : '${entries.length} kayıt'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: includeReview,
                  onChanged: book.review.isEmpty && book.rating == 0 ? null : (value) => setSheetState(() => includeReview = value ?? false),
                  title: const Text('Mütalaa / Tahlil ve puanı ekle'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Vazgeç'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Paylaş'),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await Share.share(_shareText(book, entries, includeEntries, includeReview), subject: book.title);
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _shareText(Book book, List<LibraryEntry> entries, bool includeEntries, bool includeReview) {
    final lines = <String>['KÜTÜPHANE-İ ŞAHSÎ — ESER BİLGİLERİ', '', book.title];
    if (book.subtitle.isNotEmpty) lines.add(book.subtitle);
    lines.add('Müellif: ${book.author.isEmpty ? 'Belirtilmedi' : book.author}');
    if (book.translator.isNotEmpty) lines.add('Mütercim: ${book.translator}');
    if (book.publisher.isNotEmpty) lines.add('Naşir / Tab’hane: ${book.publisher}');
    if (book.publicationYear > 0) lines.add('Zaman-ı Tab: ${book.publicationYear}');
    if (book.isbn.isNotEmpty) lines.add('ISBN: ${book.isbn}');
    if (book.category.isNotEmpty) lines.add('Çeşit / Tür: ${book.category}');
    lines.add('Mütalaa seviyesi: ${book.status.label}');
    if (book.summary.isNotEmpty) lines.addAll(['', 'HÜLASAT-ÜL ESER', book.summary]);
    if (includeReview) {
      lines.addAll(['', 'MÜTALAA / TAHLİL']);
      if (book.rating > 0) lines.add('Puan: ${book.rating}/5');
      if (book.review.isNotEmpty) lines.add(book.review);
    }
    if (includeEntries) {
      lines.addAll(['', 'İKTİBAS VE DERKENARLAR']);
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        lines.add('${i + 1}. ${entry.kind == EntryKind.quote ? 'İktibas' : 'Derkenar'}${entry.pageNumber > 0 ? ' — Sayfa ${entry.pageNumber}' : ''}');
        lines.add(entry.content);
      }
    }
    return lines.join('\n');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: const BoxDecoration(color: Color(0xFFFFFEFA), border: Border(bottom: BorderSide(color: Color(0xFFD8E3DE)))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookCover(book, width: 78, height: 112),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(book.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (book.subtitle.isNotEmpty) Text(book.subtitle),
            const SizedBox(height: 7),
            Text(book.author.isEmpty ? 'Müellif belirtilmedi' : book.author, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Chip(label: Text(book.status.label), visualDensity: VisualDensity.compact),
          ])),
        ]),
      );
}

class _About extends StatelessWidget {
  const _About({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (book.seriesSequential && book.previousTitle.isNotEmpty)
            Card(color: const Color(0xFFFFF3D9), child: Padding(padding: const EdgeInsets.all(15), child: Text('Seri sırası uyarısı: Bu eserden önce “${book.previousTitle}” okunmalıdır.'))),
          Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hülasat-ül Eser', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(book.summary.isEmpty ? 'Bu eser için Türkçe hülasat bulunmuyor.' : book.summary, style: const TextStyle(height: 1.6)),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Yayın Bilgileri', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _fact('Müellif', book.author),
            _fact('Mütercim', book.translator),
            _fact('Naşir / Tab’hane', book.publisher),
            _fact('Zaman-ı Tab', book.publicationYear == 0 ? '' : '${book.publicationYear}'),
            _fact('ISBN', book.isbn),
            _fact('Çeşit / Tür', book.category),
            _fact('Sayfa', book.pageCount == 0 ? '' : '${book.pageCount}'),
          ]))),
        ],
      );

  Widget _fact(String name, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 125, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text(value.isEmpty ? 'Belirtilmedi' : value))]),
      );
}

class _Progress extends StatefulWidget {
  const _Progress({required this.book});
  final Book book;

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  late final TextEditingController _page = TextEditingController(text: '${widget.book.currentPage}');
  late ReadingStatus _status = widget.book.status;

  @override
  void dispose() { _page.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mütalaa İlerlemesi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: widget.book.progress, minHeight: 11, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 8),
          Text('${widget.book.currentPage} / ${widget.book.pageCount} sayfa · %${(widget.book.progress * 100).round()}'),
          const SizedBox(height: 18),
          TextField(controller: _page, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bulunduğum sayfa')),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReadingStatus>(value: _status, decoration: const InputDecoration(labelText: 'Mütalaa seviyesi'), items: ReadingStatus.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(), onChanged: (value) => setState(() => _status = value ?? _status)),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('İlerlemeyi kaydet')),
        ]))),
      ]);

  Future<void> _save() async {
    final page = (int.tryParse(_page.text) ?? 0).clamp(0, widget.book.pageCount > 0 ? widget.book.pageCount : 999999).toInt();
    await context.read<LibraryProvider>().saveBook(widget.book.copyWith(currentPage: page, status: _status));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mütalaa ilerlemesi kaydedildi.')));
  }
}

class _Entries extends StatefulWidget {
  const _Entries({required this.book});
  final Book book;
  @override
  State<_Entries> createState() => _EntriesState();
}

class _EntriesState extends State<_Entries> {
  int _version = 0;
  @override
  Widget build(BuildContext context) {
    final provider = context.read<LibraryProvider>();
    return FutureBuilder<List<LibraryEntry>>(
      key: ValueKey(_version),
      future: provider.entriesFor(widget.book.id),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <LibraryEntry>[];
        return ListView(padding: const EdgeInsets.all(16), children: [
          FilledButton.tonalIcon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('İktibas yahut derkenar ekle')),
          const SizedBox(height: 10),
          if (snapshot.connectionState == ConnectionState.waiting) const Center(child: CircularProgressIndicator()),
          if (snapshot.connectionState != ConnectionState.waiting && entries.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('Henüz iktibas veya derkenar kaydı yok.'))),
          ...entries.map((entry) => Card(child: ListTile(
                title: Text(entry.kind == EntryKind.quote ? 'İktibas' : 'Derkenar'),
                subtitle: Text('${entry.pageNumber > 0 ? 'Sayfa ${entry.pageNumber}\n' : ''}${entry.content}'),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await provider.deleteEntry(entry.id); setState(() => _version++); }),
              ))),
        ]);
      },
    );
  }

  Future<void> _add() async {
    final text = TextEditingController(), page = TextEditingController();
    var kind = EntryKind.quote;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<EntryKind>(value: kind, decoration: const InputDecoration(labelText: 'Tür'), items: const [DropdownMenuItem(value: EntryKind.quote, child: Text('İktibas')), DropdownMenuItem(value: EntryKind.note, child: Text('Derkenar'))], onChanged: (value) => setSheetState(() => kind = value ?? kind)),
          const SizedBox(height: 12),
          TextField(controller: page, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sayfa')),
          const SizedBox(height: 12),
          TextField(controller: text, minLines: 4, maxLines: 8, autofocus: true, decoration: const InputDecoration(labelText: 'Metin')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Vazgeç'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () async {
              if (text.text.trim().isEmpty) return;
              await context.read<LibraryProvider>().saveEntry(LibraryEntry(id: context.read<LibraryProvider>().newId(), bookId: widget.book.id, kind: kind, pageNumber: int.tryParse(page.text) ?? 0, content: text.text.trim(), createdAt: DateTime.now()));
              if (sheetContext.mounted) Navigator.pop(sheetContext);
              if (mounted) setState(() => _version++);
            }, child: const Text('Kaydet'))),
          ]),
        ]),
      )),
    );
    text.dispose(); page.dispose();
  }
}

class _Loan extends StatefulWidget {
  const _Loan({required this.book});
  final Book book;
  @override
  State<_Loan> createState() => _LoanState();
}

class _LoanState extends State<_Loan> {
  int _version = 0;
  @override
  Widget build(BuildContext context) => FutureBuilder<BookLoan?>(
        key: ValueKey(_version),
        future: context.read<LibraryProvider>().activeLoanFor(widget.book.id),
        builder: (context, snapshot) {
          final loan = snapshot.data;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(18), child: loan == null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bu eser emanette değil.'), const SizedBox(height: 14), FilledButton.tonal(onPressed: _lend, child: const Text('Emanet ver'))])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(loan.borrowerName, style: Theme.of(context).textTheme.titleLarge),
                    if (loan.borrowerContact.isNotEmpty) Text(loan.borrowerContact),
                    const SizedBox(height: 8),
                    Text('Veriliş: ${DateFormat.yMMMMd('tr_TR').format(loan.loanDate)}'),
                    if (loan.expectedReturnDate != null) Text('Beklenen iade: ${DateFormat.yMMMMd('tr_TR').format(loan.expectedReturnDate!)}'),
                    const SizedBox(height: 14),
                    FilledButton(onPressed: () async { await context.read<LibraryProvider>().saveLoan(BookLoan(id: loan.id, bookId: loan.bookId, borrowerName: loan.borrowerName, borrowerContact: loan.borrowerContact, loanDate: loan.loanDate, expectedReturnDate: loan.expectedReturnDate, returnedDate: DateTime.now())); setState(() => _version++); }, child: const Text('İade al')),
                  ]))),
          ]);
        },
      );

  Future<void> _lend() async {
    final name = TextEditingController(), contact = TextEditingController();
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Emanet alan / Müstear *')),
        const SizedBox(height: 12),
        TextField(controller: contact, decoration: const InputDecoration(labelText: 'İletişim')),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Vazgeç'))), const SizedBox(width: 10), Expanded(child: FilledButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          await context.read<LibraryProvider>().saveLoan(BookLoan(id: context.read<LibraryProvider>().newId(), bookId: widget.book.id, borrowerName: name.text.trim(), borrowerContact: contact.text.trim(), loanDate: DateTime.now()));
          if (sheetContext.mounted) Navigator.pop(sheetContext);
          if (mounted) setState(() => _version++);
        }, child: const Text('Kaydet')))]),
      ]),
    ));
    name.dispose(); contact.dispose();
  }
}
