import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

abstract class IRemoteEncryptionService {
  Future<void> storePreKeyBundle(String? userId, PreKeyBundle preKeyBundle);
  Future<PreKeyBundle> retrievePreKeyBundle(String? userId);
  Future<int> retrieveDeviceId(String userId);
  Future<void> updateOneTimePreKey(
      String userId, ECPublicKey newPreKey, int preKeyId);
}
