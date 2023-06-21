// ignore_for_file: public_member_api_docs, sort_constructors_first

class User {
  String? get id => _id;
  String username;
  String? photoUrl;
  String? _id;
  bool active;
  DateTime? lastseen;
  String? phoneNumber;

  User(
      {required this.username,
      required this.photoUrl,
      required this.active,
      required this.lastseen,
      this.phoneNumber});

  toJson() => {
        'username': username,
        'photoUrl': photoUrl,
        'active': active,
        'lastseen': lastseen,
        'phone_number': phoneNumber,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
        username: json['username'],
        photoUrl: json['photoUrl'],
        active: json['active'],
        lastseen: json['lastseen'],
        phoneNumber: json['phone_number']);
    user._id = json['id'];
    return user;
  }
}
