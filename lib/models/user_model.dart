class UserModel {
  final int id;
  final String name;
  final String email;
  final int? restaurantId;
  final String? restaurantName;
  final String? restaurantLocation;
  final String? waiterCode;
  final String? waiterQrUrl;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.restaurantId,
    this.restaurantName,
    this.restaurantLocation,
    this.waiterCode,
    this.waiterQrUrl,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      restaurantId: json['restaurant_id'] as int?,
      restaurantName: json['restaurant_name'] as String?,
      restaurantLocation: json['restaurant_location'] as String?,
      waiterCode: json['waiter_code'] as String?,
      waiterQrUrl: json['waiter_qr_url'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
