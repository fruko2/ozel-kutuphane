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

# Keep the generated Android build within a small laptop's memory budget.
properties = manifest.parents[3] / 'gradle.properties'
settings = {
    'org.gradle.jvmargs': '-Xmx1536m -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8',
    'org.gradle.workers.max': '1',
    'org.gradle.parallel': 'false',
    'kotlin.compiler.execution.strategy': 'in-process',
}
lines = properties.read_text(encoding='utf-8').splitlines() if properties.exists() else []
filtered = [line for line in lines if line.split('=', 1)[0].strip() not in settings]
filtered.extend(f'{key}={value}' for key, value in settings.items())
properties.write_text('\n'.join(filtered) + '\n', encoding='utf-8')
