class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String avatar;
  final String gender;
  final String birthday;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.avatar = '',
    this.gender = '',
    this.birthday = '',
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatar,
    String? gender,
    String? birthday,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      gender: json['gender'] ?? '',
      birthday: json['birthday'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': id, // Save both to be safe
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
      'gender': gender,
      'birthday': birthday,
    };
  }
}
