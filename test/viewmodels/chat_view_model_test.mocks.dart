// Mocks generated by Mockito 5.4.0 from annotations
// in flutter_chat_app/test/viewmodels/chat_view_model_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:flutter_chat_app/data/datasource/datasource_contract.dart'
    as _i2;
import 'package:flutter_chat_app/models/chat_model.dart' as _i4;
import 'package:flutter_chat_app/models/local_message.dart' as _i5;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [IDataSource].
///
/// See the documentation for Mockito's code generation for more information.
class MockDatasource extends _i1.Mock implements _i2.IDataSource {
  @override
  _i3.Future<void> addChat(_i4.Chat? chat) => (super.noSuchMethod(
        Invocation.method(
          #addChat,
          [chat],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<void> addMessage(_i5.LocalMessage? message) => (super.noSuchMethod(
        Invocation.method(
          #addMessage,
          [message],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<_i4.Chat?> findChat(String? chatId) => (super.noSuchMethod(
        Invocation.method(
          #findChat,
          [chatId],
        ),
        returnValue: _i3.Future<_i4.Chat?>.value(),
        returnValueForMissingStub: _i3.Future<_i4.Chat?>.value(),
      ) as _i3.Future<_i4.Chat?>);
  @override
  _i3.Future<List<_i4.Chat>> findAllChats() => (super.noSuchMethod(
        Invocation.method(
          #findAllChats,
          [],
        ),
        returnValue: _i3.Future<List<_i4.Chat>>.value(<_i4.Chat>[]),
        returnValueForMissingStub:
            _i3.Future<List<_i4.Chat>>.value(<_i4.Chat>[]),
      ) as _i3.Future<List<_i4.Chat>>);
  @override
  _i3.Future<void> updateMessage(_i5.LocalMessage? message) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateMessage,
          [message],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
  @override
  _i3.Future<List<_i5.LocalMessage?>> findMessages(String? chatId) =>
      (super.noSuchMethod(
        Invocation.method(
          #findMessages,
          [chatId],
        ),
        returnValue:
            _i3.Future<List<_i5.LocalMessage?>>.value(<_i5.LocalMessage?>[]),
        returnValueForMissingStub:
            _i3.Future<List<_i5.LocalMessage?>>.value(<_i5.LocalMessage?>[]),
      ) as _i3.Future<List<_i5.LocalMessage?>>);
  @override
  _i3.Future<void> deleteChat(String? chatId) => (super.noSuchMethod(
        Invocation.method(
          #deleteChat,
          [chatId],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
}
