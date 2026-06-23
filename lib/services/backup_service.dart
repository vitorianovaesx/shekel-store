import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants.dart';

class BackupService {
  static Timer? _timer;
  static const int _keepCount = 3;
  static const Duration _interval = Duration(minutes: 5);

  static Future<void> start() async {
    await _run();
    _timer = Timer.periodic(_interval, (_) => _run());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _run() async {
    try {
      final dbDir = await getDatabasesPath();
      final src = File(p.join(dbDir, AppConstants.dbName));
      if (!src.existsSync()) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(docsDir.path, 'backups'));
      if (!backupDir.existsSync()) backupDir.createSync(recursive: true);

      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final dest = p.join(backupDir.path, 'shekelstore_$stamp.db');
      await src.copy(dest);

      await _pruneOld(backupDir);
    } catch (_) {
      // silently ignore — backup is best-effort
    }
  }

  static Future<void> _pruneOld(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    for (final old in files.skip(_keepCount)) {
      old.deleteSync();
    }
  }
}
