import 'dart:convert';

import '../platform/kv_store.dart';

class AIChatRepo {
  AIChatRepo(this._store);

  final KeyValueStore _store;

  static const _kPrefix = 'vkp_ai_chat_v1_';

  String _indexKey(String layoutId) => '${_kPrefix}index_$layoutId';
  String _sessionKey(String layoutId, String sessionId) =>
      '${_kPrefix}s_${layoutId}_$sessionId';

  Future<List<AIChatSessionMeta>> listSessions(String layoutId) async {
    final raw = _store.getString(_indexKey(layoutId));
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => AIChatSessionMeta.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<AIChatSession?> loadSession(String layoutId, String sessionId) async {
    final raw = _store.getString(_sessionKey(layoutId, sessionId));
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return AIChatSession.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<AIChatSession> createSession(
    String layoutId, {
    String? title,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    final session = AIChatSession(
      id: id,
      title: (title == null || title.trim().isEmpty) ? '新会话' : title.trim(),
      createdAt: now,
      updatedAt: now,
      messages: const [],
      provider: 'deepseek',
      useThinkingModel: false,
      agentPlan: const [],
      agentDoneCount: 0,
    );
    await saveSession(layoutId, session);
    return session;
  }

  Future<void> saveSession(String layoutId, AIChatSession session) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = session.copyWith(updatedAt: now);

    await _store.setString(
      _sessionKey(layoutId, next.id),
      jsonEncode(next.toJson()),
    );

    final metas = await listSessions(layoutId);
    final nextMeta = AIChatSessionMeta(
      id: next.id,
      title: next.title,
      createdAt: next.createdAt,
      updatedAt: next.updatedAt,
    );
    final merged = <AIChatSessionMeta>[nextMeta];
    for (final m in metas) {
      if (m.id == next.id) continue;
      merged.add(m);
    }
    await _store.setString(
      _indexKey(layoutId),
      jsonEncode(merged.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteSession(String layoutId, String sessionId) async {
    await _store.remove(_sessionKey(layoutId, sessionId));
    final metas = await listSessions(layoutId);
    final next = metas.where((m) => m.id != sessionId).toList();
    await _store.setString(
      _indexKey(layoutId),
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}

class AIChatSessionMeta {
  const AIChatSessionMeta({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIChatSessionMeta.fromJson(Map<String, dynamic> json) {
    return AIChatSessionMeta(
      id: json['id'] as String,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : '新会话',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;
  final int createdAt;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class AIChatSession {
  const AIChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.provider,
    required this.useThinkingModel,
    required this.agentPlan,
    required this.agentDoneCount,
  });

  factory AIChatSession.fromJson(Map<String, dynamic> json) {
    final msgs = json['messages'];
    return AIChatSession(
      id: json['id'] as String,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : '新会话',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
      messages: msgs is List
          ? msgs
              .whereType<Map>()
              .map((e) => AIChatStoredMessage.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      provider: (json['provider'] as String?)?.trim().isNotEmpty == true
          ? (json['provider'] as String).trim()
          : 'deepseek',
      useThinkingModel: json['useThinkingModel'] == true,
      agentPlan: (json['agentPlan'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          const [],
      agentDoneCount: (json['agentDoneCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;
  final int createdAt;
  final int updatedAt;
  final List<AIChatStoredMessage> messages;
  final String provider;
  final bool useThinkingModel;
  final List<String> agentPlan;
  final int agentDoneCount;

  AIChatSession copyWith({
    String? title,
    int? updatedAt,
    List<AIChatStoredMessage>? messages,
    String? provider,
    bool? useThinkingModel,
    List<String>? agentPlan,
    int? agentDoneCount,
  }) {
    return AIChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      provider: provider ?? this.provider,
      useThinkingModel: useThinkingModel ?? this.useThinkingModel,
      agentPlan: agentPlan ?? this.agentPlan,
      agentDoneCount: agentDoneCount ?? this.agentDoneCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'messages': messages.map((e) => e.toJson()).toList(),
        'provider': provider,
        'useThinkingModel': useThinkingModel,
        if (agentPlan.isNotEmpty) 'agentPlan': agentPlan,
        if (agentDoneCount != 0) 'agentDoneCount': agentDoneCount,
      };
}

class AIChatStoredMessage {
  const AIChatStoredMessage({
    required this.role,
    required this.content,
    required this.banners,
    this.capabilities = const [],
  });

  factory AIChatStoredMessage.fromJson(Map<String, dynamic> json) {
    final raw = json['banners'];
    final capsRaw = json['capabilities'];
    return AIChatStoredMessage(
      role: (json['role'] as String?) ?? 'assistant',
      content: (json['content'] as String?) ?? '',
      banners: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => AIChatStoredBanner.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      capabilities: capsRaw is List
          ? capsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }

  final String role;
  final String content;
  final List<AIChatStoredBanner> banners;
  final List<String> capabilities;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (banners.isNotEmpty) 'banners': banners.map((e) => e.toJson()).toList(),
        if (capabilities.isNotEmpty) 'capabilities': capabilities,
      };
}

class AIChatStoredBanner {
  const AIChatStoredBanner({
    required this.kind,
    required this.label,
    required this.count,
  });

  factory AIChatStoredBanner.fromJson(Map<String, dynamic> json) {
    return AIChatStoredBanner(
      kind: (json['kind'] as String?) ?? 'other',
      label: (json['label'] as String?) ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String kind;
  final String label;
  final int count;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'label': label,
        'count': count,
      };
}
