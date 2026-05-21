class SellerRequestUserSummary {
  final int id;
  final String? name;
  final String? phone;
  final String? email;

  const SellerRequestUserSummary({
    required this.id,
    this.name,
    this.phone,
    this.email,
  });

  factory SellerRequestUserSummary.fromJson(Map<String, dynamic> json) {
    return SellerRequestUserSummary(
      id: json['id'] as int,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
}

class SellerRequestModel {
  final int id;
  final String status; // 'pending' | 'approved' | 'rejected'
  final SellerRequestUserSummary user;
  final String createdAt;

  const SellerRequestModel({
    required this.id,
    required this.status,
    required this.user,
    required this.createdAt,
  });

  factory SellerRequestModel.fromJson(Map<String, dynamic> json) {
    return SellerRequestModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      user: SellerRequestUserSummary.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
