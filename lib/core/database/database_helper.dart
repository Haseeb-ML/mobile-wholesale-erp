import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_wholesale_erp/core/database/schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _db;
  bool _isDemoMode = true; // Default to demo until user creates real business
  bool _ffiInitialized = false;

  bool get isDemoMode => _isDemoMode;

  void setDemoMode(bool isDemo) {
    if (_isDemoMode != isDemo) {
      _isDemoMode = isDemo;
      _db?.close();
      _db = null;
    }
  }

  Future<void> _initFfiIfNeeded() async {
    if (!_ffiInitialized && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
  }

  Future<String> getDatabasePath(bool demo) async {
    await _initFfiIfNeeded();
    final dbName = demo ? 'erp_demo.db' : 'erp_real.db';
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appSupportDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(appSupportDir.path, 'databases'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return p.join(dir.path, dbName);
    } else {
      final databasesPath = await getDatabasesPath();
      return p.join(databasesPath, dbName);
    }
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase(_isDemoMode);
    return _db!;
  }

  Future<Database> _initDatabase(bool demo) async {
    final path = await getDatabasePath(demo);
    debugPrint('Opening SQLite DB: $path (demo=$demo)');

    return await openDatabase(
      path,
      version: AppSchema.currentVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute('PRAGMA journal_mode = WAL;');
      },
      onCreate: (db, version) async {
        debugPrint('Creating SQLite schema version $version...');
        for (final sql in AppSchema.createTables) {
          await db.execute(sql);
        }
        for (final sql in AppSchema.createIndexes) {
          await db.execute(sql);
        }
        // Initialize default accounts (Cash in Shop, Bank Account)
        await db.insert('financial_accounts', {
          'id': 'cash',
          'name': 'Cash in Shop (Counter Cash)',
          'type': 'cash',
          'balance_paisa': 0,
        });
        await db.insert('financial_accounts', {
          'id': 'bank',
          'name': 'Meezan Bank - Business Account',
          'type': 'bank',
          'balance_paisa': 0,
          'account_number': '0101-0102030405',
          'bank_name': 'Meezan Bank Limited',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migration logic for future schema increments
      },
    );
  }

  /// Closes database connection cleanly with WAL checkpoint
  Future<void> checkpointAndClose() async {
    if (_db != null && _db!.isOpen) {
      try {
        await _db!.execute('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (e) {
        debugPrint('WAL checkpoint warning: $e');
      }
      await _db!.close();
      _db = null;
    }
  }

  /// Reset demo database completely
  Future<void> resetDemoDatabase() async {
    await checkpointAndClose();
    final path = await getDatabasePath(true);
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    final walFile = File('$path-wal');
    if (walFile.existsSync()) walFile.deleteSync();
    final shmFile = File('$path-shm');
    if (shmFile.existsSync()) shmFile.deleteSync();
    _isDemoMode = true;
    _db = await _initDatabase(true);
  }
}
