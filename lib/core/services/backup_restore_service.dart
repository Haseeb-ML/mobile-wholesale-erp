import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';

class BackupResult {
  final bool success;
  final String? filePath;
  final String? message;

  BackupResult({required this.success, this.filePath, this.message});
}

class RestoreResult {
  final bool success;
  final String message;

  RestoreResult({required this.success, required this.message});
}

class BackupRestoreService {
  static final BackupRestoreService instance = BackupRestoreService._internal();
  BackupRestoreService._internal();

  /// Creates a complete offline backup archive (.zip)
  Future<BackupResult> createBackup({bool forDemo = false}) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      // 1. Flush WAL before archiving
      await dbHelper.checkpointAndClose();

      final dbPath = await dbHelper.getDatabasePath(forDemo);
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        return BackupResult(success: false, message: 'Database file not found');
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDocDir.path, 'photos'));

      // 2. Prepare Zip Archive
      final archive = Archive();

      // Add database file
      final dbBytes = await dbFile.readAsBytes();
      final dbHash = sha256.convert(dbBytes).toString();
      archive.addFile(ArchiveFile('erp_database.db', dbBytes.length, dbBytes));

      // Add photos
      final Map<String, String> photoHashes = {};
      if (photosDir.existsSync()) {
        final photoFiles = photosDir.listSync().whereType<File>();
        for (final file in photoFiles) {
          final relName = p.basename(file.path);
          final bytes = await file.readAsBytes();
          photoHashes[relName] = sha256.convert(bytes).toString();
          archive.addFile(ArchiveFile('photos/$relName', bytes.length, bytes));
        }
      }

      // Add manifest
      final manifest = {
        'app_name': 'Mobile Wholesale ERP',
        'backup_version': 1,
        'created_at': DateTime.now().toIso8601String(),
        'is_demo': forDemo,
        'db_checksum': dbHash,
        'photos_checksum': photoHashes,
      };
      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      // 3. Encode Zip
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      // 4. Save to exports directory
      final exportDir = Directory(p.join(appDocDir.path, 'backups'));
      if (!exportDir.existsSync()) exportDir.createSync(recursive: true);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupFilePath = p.join(exportDir.path, 'backup_$timestamp.mwzip');
      final backupFile = File(backupFilePath);
      await backupFile.writeAsBytes(zipData);

      // Record backup date in settings
      final db = await dbHelper.database;
      await db.update(
        'shop_settings',
        {'last_backup_date': DateTime.now().toIso8601String().split('T').first},
        where: 'id = 1',
      );

      return BackupResult(
        success: true,
        filePath: backupFilePath,
        message: 'Backup created successfully: ${p.basename(backupFilePath)}',
      );
    } catch (e) {
      debugPrint('Backup error: $e');
      return BackupResult(success: false, message: 'Backup failed: $e');
    }
  }

  /// Restores database and photos from a validated backup archive
  Future<RestoreResult> restoreBackup(String zipFilePath, {bool forDemo = false}) async {
    try {
      final zipFile = File(zipFilePath);
      if (!zipFile.existsSync()) {
        return RestoreResult(success: false, message: 'Backup file does not exist.');
      }

      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // 1. Verify Manifest
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) {
        return RestoreResult(success: false, message: 'Invalid backup: missing manifest.json');
      }

      final manifestJson = jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>;
      final dbChecksum = manifestJson['db_checksum'] as String?;

      final dbArchiveFile = archive.findFile('erp_database.db');
      if (dbArchiveFile == null) {
        return RestoreResult(success: false, message: 'Invalid backup: missing database file.');
      }

      // 2. Validate Checksum
      final actualDbHash = sha256.convert(dbArchiveFile.content as List<int>).toString();
      if (dbChecksum != null && actualDbHash != dbChecksum) {
        return RestoreResult(success: false, message: 'Backup corrupted: Database checksum mismatch.');
      }

      // 3. Stage restore: Checkpoint current DB and close
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.checkpointAndClose();

      final targetDbPath = await dbHelper.getDatabasePath(forDemo);

      // Precautionary backup of current DB in case of failure
      final currentDbFile = File(targetDbPath);
      final tempPrecautionPath = '$targetDbPath.precaution';
      if (currentDbFile.existsSync()) {
        currentDbFile.copySync(tempPrecautionPath);
      }

      try {
        // Write new database
        await File(targetDbPath).writeAsBytes(dbArchiveFile.content as List<int>);

        // Restore photos
        final appDocDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory(p.join(appDocDir.path, 'photos'));
        if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

        for (final file in archive.files) {
          if (file.name.startsWith('photos/') && !file.isDirectory) {
            final fileName = p.basename(file.name);
            final dest = File(p.join(photosDir.path, fileName));
            await dest.writeAsBytes(file.content as List<int>);
          }
        }

        // Clean up precaution file
        final precFile = File(tempPrecautionPath);
        if (precFile.existsSync()) precFile.deleteSync();

        // Reconnect DB
        await dbHelper.database;

        return RestoreResult(
          success: true,
          message: 'Restore completed successfully! All records and photos restored.',
        );
      } catch (innerError) {
        // Rollback to precautionary backup
        if (File(tempPrecautionPath).existsSync()) {
          File(tempPrecautionPath).copySync(targetDbPath);
          File(tempPrecautionPath).deleteSync();
        }
        return RestoreResult(success: false, message: 'Restore failed during extraction: $innerError');
      }
    } catch (e) {
      return RestoreResult(success: false, message: 'Error opening backup file: $e');
    }
  }
}
