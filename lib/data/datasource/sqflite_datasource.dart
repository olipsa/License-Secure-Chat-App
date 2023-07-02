// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:chat/chat.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:flutter_chat_app/data/datasource/datasource_contract.dart';
import 'package:flutter_chat_app/models/chat_model.dart';
import 'package:flutter_chat_app/models/local_message.dart';

class SqfliteDatasource implements IDataSource {
  final Database _db;
  SqfliteDatasource(this._db);

  @override
  Future<void> addChat(Chat chat) async {
    //use transaction to avoid deadlocks
    await _db.transaction((txn) async {
      await txn.insert('chats', chat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> addMessage(LocalMessage message) async {
    await _db.transaction((txn) async {
      await txn.insert('messages', message.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> deleteChat(String chatId) async {
    final batch = _db.batch();
    batch.delete('messages',
        where: 'chat_id = ?',
        whereArgs: [chatId]); //deletes from messages table the chat id
    batch.delete('chats', where: 'id = ?', whereArgs: [chatId]);
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Chat>> findAllChats() {
    return _db.transaction((txn) async {
      final chatsWithLatestMessage = await txn.rawQuery(''' 
      SELECT messages.* FROM 
        (SELECT 
          chat_id, MAX(created_at) AS created_at
          FROM messages
          GROUP BY chat_id   
        ) AS latest_messages
      INNER JOIN messages
      ON messages.chat_id = latest_messages.chat_id
      AND messages.created_at = latest_messages.created_at
      ORDER BY messages.created_at DESC
    ''');

      if (chatsWithLatestMessage.isEmpty) return [];

      final chatsWithUnreadMessage = await txn.rawQuery(''' 
    SELECT chat_id, count(*) as unread
    FROM messages
    WHERE receipt = ?
    GROUP BY chat_id
    ''', ['delivered']);

      return chatsWithLatestMessage.map<Chat>((row) {
        final int? unread = int.tryParse(chatsWithUnreadMessage
            .firstWhere((element) => row['chat_id'] == element['chat_id'],
                orElse: () => {'unread': 0})['unread']
            .toString());

        final chat = Chat.fromMap({"id": row['chat_id']});
        chat.unread = unread!;
        chat.mostRecent = LocalMessage.fromMap(row);
        return chat;
      }).toList();
    });
  }

  @override
  Future<Chat?> findChat(String? chatId) async {
    return _db.transaction((txn) async {
      final listOfChatMaps =
          await txn.query('chats', where: 'id = ?', whereArgs: [chatId]);

      if (listOfChatMaps.isEmpty) return null;

      final unread = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM messages WHERE chat_id = ? AND receipt = ?',
          [chatId, 'delivered']));

      final mostRecentMessage = await txn.query('messages',
          where: 'chat_id = ?',
          whereArgs: [chatId],
          orderBy: 'created_at DESC',
          limit: 1);
      final chat = Chat.fromMap(listOfChatMaps.first);
      chat.unread = unread!;
      if (mostRecentMessage.isNotEmpty) {
        chat.mostRecent = LocalMessage.fromMap(mostRecentMessage.first);
      }
      return chat;
    });
  }

  @override
  Future<List<LocalMessage>> findMessages(String chatId) async {
    final listOfMaps =
        await _db.query('messages', where: 'chat_id = ?', whereArgs: [chatId]);
    return listOfMaps
        .map<LocalMessage>((map) => LocalMessage.fromMap(map))
        .toList();
  }

  @override
  Future<void> updateMessage(LocalMessage message) async {
    await _db.update('messages', message.toMap(),
        where: 'id = ?',
        whereArgs: [message.message.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateMessageReceipt(String? messageId, ReceiptStatus status) {
    return _db.transaction((txn) async {
      await txn.update('messages', {'receipt': status.value()},
          where: 'id = ?',
          whereArgs: [messageId],
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}
