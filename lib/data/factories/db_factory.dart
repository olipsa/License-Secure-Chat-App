// ignore_for_file: avoid_print

import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class LocalDatabaseFactory {
  Future<Database> createDatabase() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'secure_messenger.db');

    //create database tables
    final storage = FlutterSecureStorage();
    String? dbPassword = (await storage.read(key: "db_pass"));
    if (dbPassword == null) {
      dbPassword = _generatePassword();
      await storage.write(key: "db_pass", value: dbPassword);
    }
    var database = await openDatabase(dbPath,
        version: 1, password: dbPassword, onCreate: populateDb);
    return database;
  }

  String _generatePassword() {
    var random = Random.secure();
    var values = List<int>.generate(16, (i) => random.nextInt(256));
    var password = sha256.convert(values).toString();
    return password;
  }

  void populateDb(Database db, int version) async {
    await _createChatTable(db);
    await _createMessagesTable(db);
    await _createIdentityKeyTable(db);
    await _createTrustedKeysTable(db);
    await _createMetadataTable(db);
    await _createPreKeysTable(db);
    await _createSignedPreKeysTable(db);
    await _createSessionsTable(db);
  }

  _createChatTable(Database db) async {
    await db
        .execute(
          """CREATE TABLE chats(
            id TEXT PRIMARY KEY,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
            )""",
        )
        .then((_) => print('creating table chats...'))
        .catchError((e) => print('error creating chats table: $e'));
  }

  _createMessagesTable(Database db) async {
    await db
        .execute("""
          CREATE TABLE messages(
            chat_id TEXT NOT NULL,
            id TEXT PRIMARY KEY,
            sender TEXT NOT NULL,
            receiver TEXT NOT NULL,
            contents TEXT NOT NULL,
            receipt TEXT NOT NULL,
            received_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
            content_type TEXT NOT NULL,
            file_path TEXT
            )
      """)
        .then((_) => print('creating table messages'))
        .catchError((e) => print('error creating messages table: $e'));
  }

  _createIdentityKeyTable(Database db) async {
    await db
        .execute(
          """CREATE TABLE user_identity(
            registration_id INTEGER PRIMARY KEY,
            identity_key_pair BLOB NOT NULL
            )""",
        )
        .then((_) => print('creating table user_identity...'))
        .catchError((e) => print('error creating user_identity table: $e'));
  }

  _createTrustedKeysTable(Database db) async {
    await db
        .execute(
          """CREATE TABLE trusted_keys(
            address TEXT PRIMARY KEY,
            identity_key BLOB NOT NULL
            )""",
        )
        .then((_) => print('creating table trusted_keys...'))
        .catchError((e) => print('error creating trusted_keys table: $e'));
  }

  _createMetadataTable(Database db) async {
    await db
        .execute(
          """CREATE TABLE metadata(
            current_pre_key_id INTEGER PRIMARY KEY
            )""",
        )
        .then((_) => print('creating table metadata...'))
        .catchError((e) => print('error creating metadata table: $e'));
  }

  _createPreKeysTable(Database db) async {
    await db
        .execute(
          """CREATE TABLE pre_keys(
            id INTEGER PRIMARY KEY,
            pre_key BLOB NOT NULL
            )""",
        )
        .then((_) => print('creating table pre_keys...'))
        .catchError((e) => print('error creating pre_keys table: $e'));
  }

  _createSignedPreKeysTable(Database db) async {
    await db
        .execute(
          """CREATE TABLE signed_pre_keys(
            id INTEGER PRIMARY KEY,
            signed_pre_key BLOB NOT NULL
            )""",
        )
        .then((_) => print('creating table signed_pre_keys...'))
        .catchError((e) => print('error creating signed_pre_keys table: $e'));
  }

  _createSessionsTable(Database db) async {
    await db
        .execute(
          """CREATE TABLE sessions(
            address TEXT PRIMARY KEY,
            session BLOB NOT NULL
            )""",
        )
        .then((_) => print('creating table sessions...'))
        .catchError((e) => print('error creating sessions table: $e'));
  }
}
