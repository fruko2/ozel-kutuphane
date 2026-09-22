import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const libraryUrl = 'https://kutuphane-i-sahsi.aygulfurkan.chatgpt.site';

void main() => runApp(const LibraryApp());

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kütüphane-i Şahsî',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF287562),
          surface: const Color(0xFFF8F6F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F6F0),
      ),
      home: const LibraryLauncher(),
    );
  }
}

class LibraryLauncher extends StatefulWidget {
  const LibraryLauncher({super.key});

  @override
  State<LibraryLauncher> createState() => _LibraryLauncherState();
}

class _LibraryLauncherState extends State<LibraryLauncher> {
  bool opening = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => openLibrary());
  }

  Future<void> openLibrary() async {
    if (opening) return;
    setState(() {
      opening = true;
      error = null;
    });
    try {
      final uri = Uri.parse(libraryUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!opened) {
        // The phone may not support Custom Tabs. Keep the same URL available.
        final external = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!external) throw StateError('Tarayıcı açılamadı.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Bağlantı açılamadı. İnternet ve tarayıcıyı kontrol edip yeniden deneyin.');
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_stories_rounded, size: 76, color: Color(0xFF287562)),
                  const SizedBox(height: 24),
                  Text('Kütüphane-i Şahsî', style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text(
                    'Web kütüphaneniz aynı Google hesabıyla açılır. Kitaplarınız ve eşitleme web uygulamasındadır.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: opening ? null : openLibrary,
                    icon: opening
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.open_in_browser_rounded),
                    label: Text(opening ? 'Açılıyor…' : 'Kütüphaneyi aç'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 20),
                    Text(error!, textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
