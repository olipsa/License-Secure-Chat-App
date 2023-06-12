import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../models/user.dart';

abstract class IUserService {
  Future<User> connect(User user);
  Future<List<User>> online();
  Future<void> update(User user);
  Future<void> disconnect(User user);
  Future<User> fetch(String? id);
  Future<void> storeKeys(String? userId, PreKeyBundle preKeyBundle);
}
