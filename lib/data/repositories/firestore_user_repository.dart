import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quest_genre.dart';
import '../models/quest_instance.dart';
import '../models/stat_progress.dart';
import '../models/user_profile.dart';
import 'user_repository.dart';

/// Firestoreへの実装（画面仕様書0-1のusers/{uid}に対応）。
/// アクティブなクエストはusers/{uid}/questInstances/{instanceId}に保存し、
/// 完了後もドキュメントは削除せず残す（無課金者のデータも削除しない、CLAUDE.mdの方針）。
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _questInstances(String uid) =>
      _userDoc(uid).collection('questInstances');

  @override
  Future<UserProfile> load(String uid) async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) {
      final initial = UserProfile.initial();
      await save(uid, initial);
      return initial;
    }

    final data = snapshot.data()!;
    final statsData = data['stats'] as Map<String, dynamic>? ?? {};
    final stats = <QuestGenre, StatProgress>{
      for (final genre in QuestGenre.values)
        genre: statsData.containsKey(genre.name)
            ? StatProgress.fromJson(
                Map<String, dynamic>.from(statsData[genre.name] as Map))
            : StatProgress.initial(),
    };

    QuestInstance? activeQuestInstance;
    final activeId = data['activeQuestInstanceId'] as String?;
    if (activeId != null) {
      final instanceSnapshot = await _questInstances(uid).doc(activeId).get();
      if (instanceSnapshot.exists) {
        activeQuestInstance =
            _instanceFromDoc(instanceSnapshot.id, instanceSnapshot.data()!);
      }
    }

    final equipmentData = data['equipmentValue'] as Map<String, dynamic>? ?? {};
    final equipmentValue = <QuestGenre, double>{
      for (final genre in QuestGenre.values)
        genre: (equipmentData[genre.name] as num?)?.toDouble() ?? 0,
    };

    final townData = data['townLevels'] as Map<String, dynamic>? ?? {};
    final townLevels = <QuestGenre, int>{
      for (final genre in QuestGenre.values) genre: (townData[genre.name] as int?) ?? 0,
    };

    return UserProfile(
      hasSeenWelcome: data['hasSeenWelcome'] as bool? ?? false,
      appState: AppRunState.values.byName(data['appState'] as String? ?? 'normal'),
      stats: stats,
      activeQuestInstance: activeQuestInstance,
      isPaidUser: data['isPaidUser'] as bool? ?? false,
      equipmentValue: equipmentValue,
      townLevels: townLevels,
    );
  }

  @override
  Future<void> save(String uid, UserProfile profile) async {
    final active = profile.activeQuestInstance;

    await _userDoc(uid).set({
      'hasSeenWelcome': profile.hasSeenWelcome,
      'appState': profile.appState.name,
      'isPaidUser': profile.isPaidUser,
      'stats': profile.stats.map((genre, stat) => MapEntry(genre.name, stat.toJson())),
      'equipmentValue': profile.equipmentValue.map((genre, value) => MapEntry(genre.name, value)),
      'townLevels': profile.townLevels.map((genre, value) => MapEntry(genre.name, value)),
      'activeQuestInstanceId': active?.id,
    }, SetOptions(merge: true));

    if (active != null) {
      await _questInstances(uid).doc(active.id).set(_instanceToDoc(active));
    }
  }

  @override
  Future<List<QuestInstance>> fetchQuestHistory(String uid, {DateTime? since}) async {
    Query<Map<String, dynamic>> query = _questInstances(uid)
        .where('completed', isEqualTo: true)
        .orderBy('acceptedAt', descending: true)
        .limit(50);
    if (since != null) {
      query = query.where('acceptedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _instanceFromDoc(doc.id, doc.data())).toList();
  }

  Map<String, dynamic> _instanceToDoc(QuestInstance instance) => {
        'questId': instance.questId,
        'questNameTextId': instance.questNameTextId,
        'genre': instance.genre.name,
        'acceptedAt': Timestamp.fromDate(instance.acceptedAt),
        'lockDurationSeconds': instance.lockDurationSeconds,
        'moodAtAccept': instance.moodAtAccept,
        'isTutorial': instance.isTutorial,
        'isQuickTier': instance.isQuickTier,
        'achievementScore': instance.achievementScore,
        'completed': instance.completed,
        'rewardExp': instance.rewardExp,
      };

  QuestInstance _instanceFromDoc(String id, Map<String, dynamic> data) => QuestInstance(
        id: id,
        questId: data['questId'] as String,
        questNameTextId: data['questNameTextId'] as String,
        genre: QuestGenre.values.byName(data['genre'] as String),
        acceptedAt: (data['acceptedAt'] as Timestamp).toDate(),
        lockDurationSeconds: data['lockDurationSeconds'] as int,
        moodAtAccept: data['moodAtAccept'] as int,
        isTutorial: data['isTutorial'] as bool,
        isQuickTier: data['isQuickTier'] as bool,
        achievementScore: data['achievementScore'] as int?,
        completed: data['completed'] as bool? ?? false,
        rewardExp: data['rewardExp'] as int?,
      );
}
