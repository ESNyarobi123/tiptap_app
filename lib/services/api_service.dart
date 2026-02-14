import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/dashboard_model.dart';
import '../models/user_model.dart';

num _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

int _parseInt(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? defaultValue;
  return defaultValue;
}

class ApiService {
  final String? token;
  final String baseUrl;

  ApiService({this.token, this.baseUrl = AppConfig.baseUrl});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    final body = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      message: body['message'] as String? ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  // Auth
  Future<LoginResponse> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(res);
    return LoginResponse.fromJson(data);
  }

  Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);
  }

  // Dashboard
  Future<DashboardData> getDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/waiter/dashboard'),
      headers: _headers,
    );
    final data = await _handleResponse(res);
    return DashboardData.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<DashboardStats> getDashboardStats() async {
    final res = await http.get(
      Uri.parse('$baseUrl/waiter/dashboard/stats'),
      headers: _headers,
    );
    final data = await _handleResponse(res);
    return DashboardStats.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Orders
  Future<OrdersResponse> getOrders({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/waiter/orders?page=$page'),
      headers: _headers,
    );
    final data = await _handleResponse(res);
    return OrdersResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> claimOrder(int orderId) async {
    await http.post(
      Uri.parse('$baseUrl/waiter/orders/$orderId/claim'),
      headers: _headers,
    );
  }

  // Requests
  Future<List<PendingRequest>> getPendingRequests() async {
    final res = await http.get(
      Uri.parse('$baseUrl/waiter/requests'),
      headers: _headers,
    );
    final data = await _handleResponse(res);
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => PendingRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> completeRequest(int requestId) async {
    await http.post(
      Uri.parse('$baseUrl/waiter/requests/$requestId/complete'),
      headers: _headers,
    );
  }

  // Tips
  Future<TipsResponse> getTips({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/waiter/tips?page=$page'),
      headers: _headers,
    );
    final data = await _handleResponse(res);
    return TipsResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Ratings
  Future<RatingsResponse> getRatings({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/waiter/ratings?page=$page'),
      headers: _headers,
    );
    final data = await _handleResponse(res);
    return RatingsResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Menu
  Future<MenuResponse> getMenu() async {
    final res = await http.get(
      Uri.parse('$baseUrl/waiter/menu'),
      headers: _headers,
    );
    final data = await _handleResponse(res);
    return MenuResponse.fromJson(data['data'] as Map<String, dynamic>);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});
  @override
  String toString() => message;
}

class LoginResponse {
  final String token;
  final UserModel user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class DashboardData {
  final DashboardStats stats;
  final List<UnassignedOrder> unassignedOrders;
  final List<PendingRequest> pendingRequests;
  final List<RecentFeedback> recentFeedback;
  final List<MyOrderToday> myOrdersToday;

  DashboardData({
    required this.stats,
    required this.unassignedOrders,
    required this.pendingRequests,
    required this.recentFeedback,
    required this.myOrdersToday,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      unassignedOrders:
          (json['unassigned_orders'] as List<dynamic>?)
              ?.map((e) => UnassignedOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingRequests:
          (json['pending_requests'] as List<dynamic>?)
              ?.map((e) => PendingRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentFeedback:
          (json['recent_feedback'] as List<dynamic>?)
              ?.map((e) => RecentFeedback.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      myOrdersToday:
          (json['my_orders_today'] as List<dynamic>?)
              ?.map((e) => MyOrderToday.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderListItem {
  final int id;
  final String tableNumber;
  final String status;
  final num totalAmount;
  final String createdAt;
  final List<OrderItem> items;

  OrderListItem({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return OrderListItem(
      id: json['id'] as int,
      tableNumber: (json['table_number'] ?? '?').toString(),
      status: json['status'] as String? ?? 'pending',
      totalAmount: _parseNum(json['total_amount']),
      createdAt: json['created_at'] as String? ?? '',
      items: itemsList
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrdersResponse {
  final List<OrderListItem> data;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;
  final int total;
  final int perPage;

  OrdersResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
    required this.total,
    required this.perPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    // The API might return the pagination object directly or wrapped in "data"
    final pagination = json.containsKey('data') && json['data'] is Map
        ? json['data']
        : json;
    final dataList = pagination['data'] as List<dynamic>? ?? [];

    return OrdersResponse(
      data: dataList
          .map((e) => OrderListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (pagination['current_page'] ?? 1) as int,
      lastPage: (pagination['last_page'] ?? 1) as int,
      nextPageUrl: pagination['next_page_url'] as String?,
      total: (pagination['total'] ?? 0) as int,
      perPage: (pagination['per_page'] ?? 15) as int,
    );
  }
}

class TipItem {
  final int id;
  final int? orderId;
  final num amount;
  final String createdAt;

  TipItem({
    required this.id,
    this.orderId,
    required this.amount,
    required this.createdAt,
  });

  factory TipItem.fromJson(Map<String, dynamic> json) {
    return TipItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int?,
      amount: _parseNum(json['amount']),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class TipsResponse {
  final num totalTips;
  final List<TipItem> tips;
  final int currentPage;
  final int lastPage;
  final int total;

  TipsResponse({
    required this.totalTips,
    required this.tips,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory TipsResponse.fromJson(Map<String, dynamic> json) {
    final paginator = json['tips'] as Map<String, dynamic>? ?? {};
    final tipsList = paginator['data'] as List<dynamic>? ?? [];
    return TipsResponse(
      totalTips: _parseNum(json['total_tips']),
      tips: tipsList
          .map((e) => TipItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (paginator['current_page'] ?? 1) as int,
      lastPage: (paginator['last_page'] ?? 1) as int,
      total: (paginator['total'] ?? 0) as int,
    );
  }
}

class RatingItem {
  final int id;
  final int rating;
  final String? comment;
  final String? tableNumber;
  final String createdAt;

  RatingItem({
    required this.id,
    required this.rating,
    this.comment,
    this.tableNumber,
    required this.createdAt,
  });

  factory RatingItem.fromJson(Map<String, dynamic> json) {
    return RatingItem(
      id: json['id'] as int,
      rating: (json['rating'] ?? 0) as int,
      comment: json['comment'] as String?,
      tableNumber: json['table_number']?.toString(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class RatingsResponse {
  final List<RatingItem> data;
  final int currentPage;
  final int lastPage;
  final int total;

  RatingsResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory RatingsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return RatingsResponse(
      data: dataList
          .map((e) => RatingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (json['current_page'] ?? 1) as int,
      lastPage: (json['last_page'] ?? 1) as int,
      total: (json['total'] ?? 0) as int,
    );
  }
}

class MenuCategory {
  final int id;
  final String name;
  final List<MenuItemData> items;

  MenuCategory({required this.id, required this.name, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return MenuCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      items: itemsList
          .map((e) => MenuItemData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MenuItemData {
  final int id;
  final String name;
  final String? description;
  final num price;
  final int? categoryId;
  final String? categoryName;
  final String? image;
  final bool isAvailable;
  final int preparationTime;

  MenuItemData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.image,
    required this.isAvailable,
    this.preparationTime = 15,
  });

  factory MenuItemData.fromJson(Map<String, dynamic> json) {
    return MenuItemData(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: _parseNum(json['price']),
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      image: json['image'] as String?,
      isAvailable: _parseBool(json['is_available']),
      preparationTime: _parseInt(json['preparation_time'], 15),
    );
  }
}

class MenuResponse {
  final List<MenuCategory> categories;
  final List<MenuItemData> items;

  MenuResponse({required this.categories, required this.items});

  factory MenuResponse.fromJson(Map<String, dynamic> json) {
    // getMenu() already unwraps data['data'], so we just read categories/items directly
    final catList = json['categories'] as List<dynamic>? ?? [];
    final itemList = json['items'] as List<dynamic>? ?? [];

    return MenuResponse(
      categories: catList
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: itemList
          .map((e) => MenuItemData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
