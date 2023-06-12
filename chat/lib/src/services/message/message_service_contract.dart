import 'package:chat/src/models/message.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../models/user.dart';

abstract class IMessageService {
  Future<Message> send(Message message);
  Stream<Message> messages({required User activeUser});
  Future<PreKeyBundle> retrievePreKeyBundle(String? userId);
  dispose();
}
