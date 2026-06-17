import 'dart:convert';

import '../../core/api/api_service.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.readAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Notificacao',
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: json['read_at'] == null ? null : DateTime.tryParse(json['read_at'].toString()),
    );
  }
}

class NotificationPageResult {
  final List<AppNotification> notifications;
  final int unreadCount;
  final int currentPage;
  final int lastPage;

  const NotificationPageResult({
    required this.notifications,
    required this.unreadCount,
    required this.currentPage,
    required this.lastPage,
  });
}

class NotificationApiService {
  final ApiService _api;

  NotificationApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<NotificationPageResult> getNotifications({int page = 1}) async {
    final response = await _api.get('/user/notifications?page=$page');
    if (response.statusCode == 401) {
      throw Exception('401');
    }
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar notificacoes.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
    final meta = body['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return NotificationPageResult(
      notifications: items,
      unreadCount: (body['unread_count'] as num?)?.toInt() ?? 0,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? page,
    );
  }

  Future<int> unreadCount() async {
    final result = await getNotifications(page: 1);
    return result.unreadCount;
  }

  Future<void> markRead(int id) async {
    final response = await _api.post('/user/notifications/$id/read', {});
    if (response.statusCode != 200) {
      throw Exception('Erro ao marcar notificacao como lida.');
    }
  }

  Future<void> markAllRead() async {
    final response = await _api.post('/user/notifications/read-all', {});
    if (response.statusCode != 200) {
      throw Exception('Erro ao marcar notificacoes como lidas.');
    }
  }
}
