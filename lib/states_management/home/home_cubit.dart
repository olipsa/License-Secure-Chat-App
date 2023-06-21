import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_chat_app/cache/local_cache.dart';
import 'package:flutter_chat_app/states_management/home/home_state.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeCubit extends Cubit<HomeState> {
  final IUserService _userService;
  final ILocalCache _localCache;

  HomeCubit(this._userService, this._localCache) : super(HomeInitial());

  Future<User> connect() async {
    final userJson = _localCache.fetch('USER');
    userJson['lastseen'] = DateTime.now();
    userJson['active'] = true;

    final user = User.fromJson(userJson);
    await _userService.connect(user);
    return user;
  }

  Future<void> activeUsers(User user) async {
    emit(HomeLoading());
    List<User> users = [];
    PermissionStatus status = await Permission.contacts.status;
    if (!status.isGranted) {
      // Request the permissions
      await Permission.contacts.request();
    }
    if (await Permission.contacts.isGranted) {
      List<Contact> contacts =
          await ContactsService.getContacts(withThumbnails: false);
      Map<String, String> phoneDisplayNameMap = {};

      for (Contact contact in contacts) {
        String? displayName = contact.displayName;
        List<Item>? phones = contact.phones;
        if (phones != null && displayName != null) {
          if (phones.isNotEmpty) {
            for (var phone in phones) {
              if (phone.value != null) {
                print('Before: ${phone.value}');
                String prefix = getUserPrefix(user.phoneNumber);
                String formattedPhoneNumber =
                    formatPhoneNumber(phone.value!, prefix);
                print('After: $formattedPhoneNumber');
                phoneDisplayNameMap[formattedPhoneNumber] = displayName;
              }
            }
          }
        }
      }
      users = await _userService.contacts(phoneDisplayNameMap);
      users.removeWhere((element) => element.id == user.id);
      emit(HomeSuccess(users));
    }
  }

  String formatPhoneNumber(String phoneNumber, String prefix) {
    // Remove all non-digit characters from the phone number
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Check if the phone number starts with a '+' sign
    bool startsWithPlus = phoneNumber.startsWith('+');
    bool startsWithPrefix = phoneNumber.startsWith(prefix);

    // Remove any leading '0' characters if present
    phoneNumber = phoneNumber.replaceFirst(RegExp(r'^0+'), '');

    // Add the '+' sign and prefix if necessary
    if (!startsWithPlus) {
      // do not add 2x times the prefix
      if (startsWithPrefix) {
        phoneNumber = '+$phoneNumber';
      } else {
        phoneNumber = '+$prefix$phoneNumber';
      }
    }

    return phoneNumber;
  }

  String getUserPrefix(String? phoneNumber) {
    if (phoneNumber != null) {
// here we have a number in the format +40756236884, where +40 is the prefix
      return phoneNumber.substring(1, phoneNumber.length - 10);
    }
    return ('40');
  }
}
