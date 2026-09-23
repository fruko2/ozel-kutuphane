import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/book.dart';
import '../../domain/models/reading_status.dart';
import '../providers/library_provider.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';
import 'book_form_screen.dart';
import 'library_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: const [_Dashboard(), LibraryScreen(), _LoansPage(), _AccountPage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sahife'),
          NavigationDestination(icon: Icon(Icons.local_library_outlined), selectedIcon: Icon(Icons.local_library), label: 'Kütüphane'),
          NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: 'Emanet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hesap'),
        ],
      ),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookFormScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Eser ekle'),
            )
          : null,
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) => Consumer<LibraryProvider>(builder: (context, provider, _) {
        if (provider.loading) return const Center(child: CircularProgressIndicator());
        final now = DateTime.now();
        final date = DateFormat('EEEE, d MMMM y', 'tr_TR').format(now);
        final completed = provider.books.where((book) => book.status == ReadingStatus.completed && book.updatedAt.year == now.year).length;
        final pages = provider.books.fold<int>(0, (total, book) => total + (book.status == ReadingStatus.completed ? book.pageCount : book.currentPage));
        final reading = provider.books.where((book) => book.status == ReadingStatus.reading).take(4).toList();
        return RefreshIndicator(
          onRefresh: provider.reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 105),
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_greeting(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)), Text(provider.authSync.user?.displayName ?? 'Hocam', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))])),
                Text(_titleCase(date), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(minHeight: 185),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF367C71), Color(0xFF173E35)]),
                  boxShadow: const [BoxShadow(color: Color(0x33245D52), blurRadius: 24, offset: Offset(0, 14))],
                ),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('✦  GÜNÜN SATIRI', style: TextStyle(color: Color(0xFFF6D9A1), fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                  SizedBox(height: 14),
                  Text('“İyi bir kitap, insana yürümeyi değil; hangi yöne yürüyeceğini öğretir.”', style: TextStyle(color: Colors.white, fontSize: 21, height: 1.35, fontWeight: FontWeight.w600)),
                  SizedBox(height: 9),
                  Text('Kütüphane-i Şahsî', style: TextStyle(color: Color(0xFFE5EFEA))),
                ]),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _Stat(label: 'Kütüphanedeki eser', value: '${provider.books.length}'),
                  _Stat(label: 'Bu yıl okunan', value: '$completed'),
                  _Stat(label: 'Okunan sayfa', value: '$pages'),
                  _Stat(label: 'Faal emanet', value: '${provider.loans.where((loan) => !loan.isReturned).length}'),
                ],
              ),
              const SizedBox(height: 22),
              Text('Mütalaaya Devam', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 9),
              if (reading.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('Faal mütalaa yok. Bir eseri “Okuyorum” durumuna getirebilirsiniz.'))),
              ...reading.map((book) => _ReadingBook(book: book)),
            ],
          ),
        );
      });

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  static String _titleCase(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 6), Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))])));
}

class _ReadingBook extends StatelessWidget {
  const _ReadingBook({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))), child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [BookCover(book, width: 48, height: 68), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(book.author), const SizedBox(height: 8), LinearProgressIndicator(value: book.progress), const SizedBox(height: 5), Text('${book.currentPage} / ${book.pageCount} sayfa', style: Theme.of(context).textTheme.bodySmall)])), const Icon(Icons.chevron_right)]))));
}

class _LoansPage extends StatelessWidget {
  const _LoansPage();
  @override
  Widget build(BuildContext context) => Consumer<LibraryProvider>(builder: (context, provider, _) {
        final active = provider.loans.where((loan) => !loan.isReturned).toList();
        return Scaffold(appBar: AppBar(title: const Text('Emanet-i Kütüb')), body: active.isEmpty
            ? const Center(child: Text('Faal emanet kaydı yok.'))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: active.length, itemBuilder: (_, index) {
                final loan = active[index];
                final book = provider.books.where((item) => item.id == loan.bookId).firstOrNull;
                return Card(child: ListTile(title: Text(book?.title ?? 'Eser'), subtitle: Text(loan.borrowerName), trailing: const Icon(Icons.chevron_right), onTap: book == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)))));
              }));
      });
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();
  @override
  Widget build(BuildContext context) => Consumer<LibraryProvider>(builder: (context, provider, _) {
        final user = provider.authSync.user;
        return Scaffold(
          appBar: AppBar(title: const Text('Hesap ve Eşitleme')),
          body: ListView(padding: const EdgeInsets.all(18), children: [
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.displayName ?? 'Yerel Kütüphane', style: Theme.of(context).textTheme.titleLarge),
              if (user?.email != null) Text(user!.email!),
              const SizedBox(height: 8),
              Text(provider.authSync.status),
              const SizedBox(height: 16),
              if (user == null) FilledButton.icon(onPressed: () => _run(context, provider.signIn), icon: const Icon(Icons.login), label: const Text('Google ile giriş yap')),
              if (user != null) ...[
                FilledButton.icon(onPressed: () => _run(context, provider.syncNow), icon: const Icon(Icons.sync), label: const Text('Şimdi eşitle')),
                TextButton(onPressed: provider.signOut, child: const Text('Oturumu kapat')),
              ],
            ]))),
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Kayıtlar öncelikle cihazdaki SQLite veritabanında muhafaza edilir. İnternet ve Google hesabı bulunduğunda web kütüphanesiyle eşitlenir.', style: TextStyle(height: 1.5)))),
          ]),
        );
      });

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try { await action(); }
    catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İşlem gerçekleştirilemedi: $error'))); }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

