import 'package:chat/src/models/message.dart';

import '../../models/user.dart';

abstract class IMessageService {
  Future<Message> send(Message message);
  Stream<Message> messages({required User activeUser});
  dispose();
}
