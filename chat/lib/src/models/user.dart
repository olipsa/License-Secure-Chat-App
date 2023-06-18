// ignore_for_file: public_member_api_docs, sort_constructors_first

class User {
  String? get id => _id;
  String username;
  String? photoUrl;
  String? _id;
  bool active;
  DateTime? lastseen;

  User({
    required this.username,
    required this.photoUrl,
    required this.active,
    required this.lastseen,
  });

  toJson() => {
        'username': username,
        'photoUrl': photoUrl,
        'active': active,
        'lastseen': lastseen
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
        username: json['username'],
        photoUrl: json['photoUrl'],
        active: json['active'],
        lastseen: json['lastseen']);
    user._id = json['id'];
    return user;
  }
}
