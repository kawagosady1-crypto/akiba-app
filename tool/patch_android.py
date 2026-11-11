"""Adjusts the generated Android project for Akiba's features.

Run after `flutter create`. Adds notification, boot and fingerprint
permissions, the reminder receivers, Java desugaring (needed by the
notifications plugin) and switches MainActivity to FlutterFragmentActivity
(needed for fingerprint unlock).
"""
import pathlib
import re
import sys

app = pathlib.Path('android/app')

# ---------- AndroidManifest.xml ----------
man = app / 'src/main/AndroidManifest.xml'
s = man.read_text()
s = s.replace('android:label="akiba"', 'android:label="Akiba"')

perms = [
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.VIBRATE',
    'android.permission.USE_BIOMETRIC',
]
add = ''.join(
    f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in s)
s = re.sub(r'(<manifest[^>]*>\s*\n)', lambda m: m.group(1) + add, s, count=1)

receivers = '''
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
if 'ScheduledNotificationReceiver' not in s:
    s = s.replace('</application>', receivers + '    </application>', 1)
man.write_text(s)
print('Manifest patched')

# ---------- Desugaring ----------
kts = app / 'build.gradle.kts'
groovy = app / 'build.gradle'
if kts.exists():
    g = kts.read_text()
    if 'isCoreLibraryDesugaringEnabled' not in g:
        if 'compileOptions {' in g:
            g = g.replace('compileOptions {',
                          'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
        else:
            g = g.replace('android {',
                          'android {\n    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n    }', 1)
    if 'desugar_jdk_libs' not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(g)
    print('build.gradle.kts patched')
elif groovy.exists():
    g = groovy.read_text()
    if 'coreLibraryDesugaringEnabled' not in g:
        if 'compileOptions {' in g:
            g = g.replace('compileOptions {',
                          'compileOptions {\n        coreLibraryDesugaringEnabled true', 1)
        else:
            g = g.replace('android {',
                          'android {\n    compileOptions {\n        coreLibraryDesugaringEnabled true\n    }', 1)
    if 'desugar_jdk_libs' not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    groovy.write_text(g)
    print('build.gradle patched')
else:
    sys.exit('No app build.gradle found')

# ---------- Release signing (only when the key was provided) ----------
if (pathlib.Path('android') / 'key.properties').exists():
    if kts.exists():
        g = kts.read_text()
        block = '''    signingConfigs {
        create("release") {
            val props = java.util.Properties()
            props.load(java.io.FileInputStream(rootProject.file("key.properties")))
            keyAlias = props.getProperty("keyAlias")
            keyPassword = props.getProperty("keyPassword")
            storeFile = file(props.getProperty("storeFile"))
            storePassword = props.getProperty("storePassword")
        }
    }

'''
        if 'create("release")' not in g:
            g = g.replace('    buildTypes {', block + '    buildTypes {', 1)
        g = g.replace('signingConfigs.getByName("debug")', 'signingConfigs.getByName("release")')
        kts.write_text(g)
    else:
        g = groovy.read_text()
        block = '''    signingConfigs {
        release {
            def props = new Properties()
            props.load(new FileInputStream(rootProject.file("key.properties")))
            keyAlias props['keyAlias']
            keyPassword props['keyPassword']
            storeFile file(props['storeFile'])
            storePassword props['storePassword']
        }
    }

'''
        if 'signingConfigs {' not in g:
            g = g.replace('    buildTypes {', block + '    buildTypes {', 1)
        g = g.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
        groovy.write_text(g)
    print('Release signing set up')
else:
    print('No signing key given: using a temporary key')

# ---------- Home-screen widget ----------
import shutil
src = pathlib.Path('tool')
res = app / 'src/main/res'
for name, sub, target in [
    ('widget_layout.xml', 'layout', 'akiba_widget.xml'),
    ('widget_info.xml', 'xml', 'akiba_widget_info.xml'),
    ('widget_bg.xml', 'drawable', 'akiba_widget_bg.xml'),
]:
    (res / sub).mkdir(parents=True, exist_ok=True)
    shutil.copy(src / name, res / sub / target)
widget_receiver = '''
        <receiver android:name=".AkibaWidgetProvider" android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data android:name="android.appwidget.provider"
                android:resource="@xml/akiba_widget_info" />
        </receiver>
'''
m = man.read_text()
if 'AkibaWidgetProvider' not in m:
    m = m.replace('</application>', widget_receiver + '    </application>', 1)
    man.write_text(m)
print('Widget resources added')

# ---------- MainActivity ----------
found = False
for p in list(app.rglob('MainActivity.kt')) + list(app.rglob('MainActivity.java')):
    t = p.read_text()
    t = t.replace('io.flutter.embedding.android.FlutterActivity',
                  'io.flutter.embedding.android.FlutterFragmentActivity')
    t = re.sub(r'\bFlutterActivity\b', 'FlutterFragmentActivity', t)
    p.write_text(t)
    found = True
    print('Patched', p)
    if p.suffix == '.kt':
        pkg = re.search(r'^package\s+([\w.]+)', t, re.M).group(1)
        k = (src / 'AkibaWidgetProvider.kt').read_text().replace('PACKAGE_NAME', pkg)
        (p.parent / 'AkibaWidgetProvider.kt').write_text(k)
        print('Widget provider added in', pkg)
if not found:
    sys.exit('MainActivity not found')
