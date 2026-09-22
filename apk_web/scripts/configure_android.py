#!/usr/bin/env python3
"""Apply Android settings after Flutter generates the platform project."""
from pathlib import Path

manifest = Path(__file__).resolve().parents[1] / 'android/app/src/main/AndroidManifest.xml'
text = manifest.read_text(encoding='utf-8')
permission = '<uses-permission android:name="android.permission.INTERNET" />'
if permission not in text:
    text = text.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
                        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    ' + permission,
                        1)
text = text.replace('android:label="kutuphane_web"', 'android:label="Kütüphane-i Şahsî"')
if permission not in text or 'android:label="Kütüphane-i Şahsî"' not in text:
    raise SystemExit('Android manifest formatı beklenenden farklı; değişiklik uygulanmadı.')
manifest.write_text(text, encoding='utf-8')
