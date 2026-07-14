class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String avatar;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.avatar = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
    };
  }
}
