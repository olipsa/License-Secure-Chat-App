import 'package:chat/chat.dart';

abstract class IUserService {
  Future<User> connect(User user);
  Future<List<User>> contacts(Map<String, String> phoneDisplayNameMap);
  Future<void> update(User user);
  Future<void> disconnect(User user);
  Future<User> fetch(String? id);
}
