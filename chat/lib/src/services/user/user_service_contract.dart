import 'package:chat/chat.dart';

abstract class IUserService {
  Future<User> connect(User user);
  Future<List<User>> online();
  Future<void> update(User user);
  Future<void> disconnect(User user);
  Future<User> fetch(String? id);
}
