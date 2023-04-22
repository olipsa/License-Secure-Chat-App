import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:chat/src/services/encryption/encryption_service.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_validator/string_validator.dart';

main() {
  final encrypter = Encrypter(AES(Key.fromLength(32)));
  IEncryption sut = EncryptionService(encrypter);

  setUp(() {});

  test('it encrypts the plaintext', () {
    const text = 'this is a message';
    final encrypted = sut.encrypt(text);
    expect(isBase64(encrypted), true);
  });

  test('it decrypts the encrypted text', () {
    const text = 'this is a message';
    final encrypted = sut.encrypt(text);
    final decrypted = sut.decrypt(encrypted);
    expect(decrypted, text);
  });
}
