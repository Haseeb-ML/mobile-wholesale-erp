import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
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
    if (_ffiInitialized) return;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      _ffiInitialized = true;
    } else if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
  }

  Future<String> getDatabasePath(bool demo) async {
    await _initFfiIfNeeded();
    final dbName = demo ? 'erp_demo.db' : 'erp_real.db';
    if (kIsWeb) {
      return dbName;
    }
    if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
      final appSupportDir = await getApplicationSupportDirectory();
      final dir = io.Directory(p.join(appSupportDir.path, 'databases'));
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
        if (!kIsWeb) {
          try {
            await db.execute('PRAGMA foreign_keys = ON;');
          } catch (e) {
            debugPrint('PRAGMA foreign_keys warning: $e');
          }
        }
      },
      onCreate: (db, version) async {
        for (final sql in AppSchema.createTables) {
          await db.execute(sql);
        }
        for (final sql in AppSchema.createIndexes) {
          await db.execute(sql);
        }
        // Seed initial financial accounts
        await db.insert('financial_accounts', {
          'id': 'cash',
          'name': 'Cash in Shop',
          'type': 'cash',
          'balance_paisa': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await db.insert('financial_accounts', {
          'id': 'bank',
          'name': 'Bank Account (Meezan/HBL)',
          'type': 'bank',
          'balance_paisa': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      },
      onOpen: (db) async {
        await db.execute('''
          INSERT OR IGNORE INTO financial_accounts (id, name, type, balance_paisa)
          VALUES ('cash', 'Cash in Shop', 'cash', 0)
        ''');
        await db.execute('''
          INSERT OR IGNORE INTO financial_accounts (id, name, type, balance_paisa)
          VALUES ('bank', 'Bank Account (Meezan/HBL)', 'bank', 0)
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrations
      },
    );
  }

  /// Checkpoint WAL journal before backups
  Future<void> checkpointAndClose() async {
    if (_db != null && _db!.isOpen) {
      if (!kIsWeb) {
        try {
          await _db!.execute('PRAGMA wal_checkpoint(TRUNCATE);');
        } catch (e) {
          debugPrint('WAL checkpoint warning: $e');
        }
      }
      await _db!.close();
      _db = null;
    }
  }

  /// Reset demo database completely
  Future<void> resetDemoDatabase() async {
    await checkpointAndClose();
    if (kIsWeb) {
      await databaseFactory.deleteDatabase('erp_demo.db');
      _isDemoMode = true;
      _db = await _initDatabase(true);
      return;
    }
    final path = await getDatabasePath(true);
    final file = io.File(path);
    if (file.existsSync()) file.deleteSync();
    final walFile = io.File('$path-wal');
    if (walFile.existsSync()) walFile.deleteSync();
    final shmFile = io.File('$path-shm');
    if (shmFile.existsSync()) shmFile.deleteSync();
    _isDemoMode = true;
    _db = await _initDatabase(true);
  }
}
