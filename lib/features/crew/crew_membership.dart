import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/config/app_env.dart';
import '../../data/api/secured_action_api_client.dart';

/// 크루 한 곳의 공개 정보(목록·검색에 쓴다).
@immutable
class CrewSummary {
  const CrewSummary({
    required this.id,
    required this.name,
    required this.emblem,
    required this.memberCount,
    required this.maxMembers,
    required this.totalDistanceKm,
    this.joinMode = 'open',
  });

  final String id;
  final String name;
  final String emblem;
  final int memberCount;
  final int maxMembers;
  final double totalDistanceKm;

  /// `open`(바로 가입) 또는 `approval`(크루장 승인).
  final String joinMode;

  bool get needsApproval => joinMode == 'approval';

  bool get isFull => memberCount >= maxMembers;

  factory CrewSummary.fromJson(Map<String, dynamic> json) => CrewSummary(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        emblem: json['emblem'] as String? ?? '',
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        maxMembers: (json['max_members'] as num?)?.toInt() ?? 100,
        totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
        joinMode: json['join_mode'] as String? ?? 'open',
      );
}

/// 크루 목록과, 내가 가입을 신청해 둔 크루(없으면 빈 문자열).
@immutable
class CrewListResult {
  const CrewListResult({this.crews = const [], this.pendingCrewId = ''});

  final List<CrewSummary> crews;
  final String pendingCrewId;
}

/// 들어오고 싶다고 신청한 사람.
@immutable
class CrewJoinRequest {
  const CrewJoinRequest({required this.uid, required this.nickname});

  final String uid;
  final String nickname;
}

@immutable
class CrewMember {
  const CrewMember({
    required this.uid,
    required this.nickname,
    required this.role,
  });

  final String uid;
  final String nickname;

  /// `leader` · `sub` · `member`
  final String role;

  factory CrewMember.fromJson(Map<String, dynamic> json) => CrewMember(
        uid: json['uid'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '러너',
        role: json['role'] as String? ?? 'member',
      );
}

/// 내가 들어 있는 크루와 내 역할, 크루원.
@immutable
class MyCrew {
  const MyCrew({
    required this.crew,
    required this.role,
    required this.members,
    this.pendingRequests = 0,
  });

  final CrewSummary crew;
  final String role;
  final List<CrewMember> members;

  /// 승인을 기다리는 가입 신청 수(크루장·부크루장에게만 채워진다).
  final int pendingRequests;

  bool get isLeader => role == 'leader';

  /// 신청을 받고 크루원을 내보낼 수 있는 사람.
  bool get isManager => role == 'leader' || role == 'sub';

  /// 나가기는 크루장이 아닌 사람만 할 수 있다.
  bool get canLeave => role == 'member' || role == 'sub';

  static MyCrew? fromJson(Map<String, dynamic> json) {
    final crew = json['crew'];
    if (crew is! Map<String, dynamic>) return null;
    return MyCrew(
      crew: CrewSummary.fromJson(crew),
      role: json['role'] as String? ?? 'member',
      pendingRequests: (json['pending_requests'] as num?)?.toInt() ?? 0,
      members: [
        if (json['members'] is List)
          for (final m in json['members'] as List)
            if (m is Map<String, dynamic>) CrewMember.fromJson(m),
      ],
    );
  }
}

/// 서버와 이야기할 수 있을 때만 API 클라이언트를 준다(로그인 전·목 데이터 모드에서는 null).
final crewApiProvider = Provider<SecuredActionApiClient?>((ref) {
  if (AppEnv.useLocalMockData) return null;
  try {
    final uid = ref.watch(authStateChangesProvider).asData?.value?.uid;
    if (uid == null || uid.isEmpty) return null;
    return ref.watch(securedActionApiClientProvider);
  } catch (_) {
    return null;
  }
});

/// 내 크루. 크루가 없거나 서버에 닿지 못하면 null.
final myCrewProvider = FutureProvider.autoDispose<MyCrew?>((ref) async {
  final api = ref.watch(crewApiProvider);
  if (api == null) return null;
  try {
    return await api.myCrew();
  } catch (_) {
    return null;
  }
});

/// 이름에 [query]가 들어간 크루(없으면 큰 크루부터). 서버에 닿지 못하면 빈 목록.
final crewListProvider =
    FutureProvider.autoDispose.family<CrewListResult, String>((ref, query) async {
  final api = ref.watch(crewApiProvider);
  if (api == null) return const CrewListResult();
  try {
    return await api.listCrews(query);
  } catch (_) {
    return const CrewListResult();
  }
});
