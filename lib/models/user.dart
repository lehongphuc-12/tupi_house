class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String avatar;
  final String gender;
  final String birthday;
  final String role;
  final bool isActive;
  final int points;
  final int accumulatedPoints;
  final String tier;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.avatar = '',
    this.gender = '',
    this.birthday = '',
    this.role = 'user',
    this.isActive = true,
    this.points = 0,
    this.accumulatedPoints = 0,
    this.tier = 'Đồng',
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatar,
    String? gender,
    String? birthday,
    String? role,
    bool? isActive,
    int? points,
    int? accumulatedPoints,
    String? tier,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      points: points ?? this.points,
      accumulatedPoints: accumulatedPoints ?? this.accumulatedPoints,
      tier: tier ?? this.tier,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final parsedPoints = int.tryParse(json['points']?.toString() ?? '') ?? 0;
    final parsedAccumulated = int.tryParse(json['accumulatedPoints']?.toString() ?? '') ?? parsedPoints;
    return AppUser(
      id: json['id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      gender: json['gender'] ?? '',
      birthday: json['birthday'] ?? '',
      role: json['role']?.toString().toLowerCase() ?? 'user',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      points: parsedPoints,
      accumulatedPoints: parsedAccumulated,
      tier: json['tier']?.toString() ?? 'Đồng',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
      'gender': gender,
      'birthday': birthday,
      'role': role,
      'isActive': isActive,
      'points': points,
      'accumulatedPoints': accumulatedPoints,
      'tier': tier,
    };
  }
}

