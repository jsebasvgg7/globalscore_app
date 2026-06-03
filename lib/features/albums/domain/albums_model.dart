typedef CardType = String;
typedef FrameLevel = String;
typedef AlbumType = String;
// ─── Constantes ────────────────────────────────────────────
const Map<int, String> kStarLabels = {
  1: 'Actual Relevante',
  2: 'Momento Puntual',
  3: 'Culto',
  4: 'Leyenda',
  5: 'GOAT',
};

const Map<int, double> kDropRates = {
  1: 55,
  2: 25,
  3: 12,
  4: 7.5,
  5: 0.5,
};

const List<String> kLegendaryAlbumIds = [
  'legendary_1',
  'legendary_2',
  'legendary_3',
  'legendary_4',
  'legendary_5',
];

// ─── AlbumCard ─────────────────────────────────────────────
class AlbumCard {
  final String id;
  final CardType cardType;
  final String referenceId;
  final String name;
  final String? imagePath;
  final int? significanceLevel;
  final bool isActive;
  final String createdAt;

  const AlbumCard({
    required this.id,
    required this.cardType,
    required this.referenceId,
    required this.name,
    this.imagePath,
    this.significanceLevel,
    required this.isActive,
    required this.createdAt,
  });

  factory AlbumCard.fromMap(Map<String, dynamic> m) => AlbumCard(
        id:                 m['id'] as String,
        cardType:           m['card_type'] as String,
        referenceId:        m['reference_id'] as String,
        name:               m['name'] as String,
        imagePath:          m['image_path'] as String?,
        significanceLevel:  (m['significance_level'] as num?)?.toInt(),
        isActive:           m['is_active'] as bool? ?? true,
        createdAt:          m['created_at'] as String? ?? '',
      );

  bool get isGoat => significanceLevel == 5;
}

// ─── AlbumPacks ────────────────────────────────────────────
class AlbumPacks {
  final String id;
  final String userId;
  final int packsAvailable;
  final int totalPacksEarned;
  final int totalPacksOpened;
  final bool boostActive;
  final int boostPacksRemaining;
  final String updatedAt;

  const AlbumPacks({
    required this.id,
    required this.userId,
    required this.packsAvailable,
    required this.totalPacksEarned,
    required this.totalPacksOpened,
    required this.boostActive,
    required this.boostPacksRemaining,
    required this.updatedAt,
  });

  factory AlbumPacks.fromMap(Map<String, dynamic> m) => AlbumPacks(
        id:                   m['id'] as String,
        userId:               m['user_id'] as String,
        packsAvailable:       (m['packs_available'] as num?)?.toInt() ?? 0,
        totalPacksEarned:     (m['total_packs_earned'] as num?)?.toInt() ?? 0,
        totalPacksOpened:     (m['total_packs_opened'] as num?)?.toInt() ?? 0,
        boostActive:          m['boost_active'] as bool? ?? false,
        boostPacksRemaining:  (m['boost_packs_remaining'] as num?)?.toInt() ?? 0,
        updatedAt:            m['updated_at'] as String? ?? '',
      );

  /// Progreso hacia el próximo boost (cada 10 sobres → 3 sobres boost)
  int get barProgress => totalPacksOpened % 10;
  int get barThreshold => 10;
}

// ─── AlbumCollectionItem ───────────────────────────────────
class AlbumCollectionItem {
  final String id;
  final String userId;
  final String cardId;
  final int copies;
  final FrameLevel frameLevel;
  final String firstObtainedAt;
  final String lastObtainedAt;
  final AlbumCard? card;

  const AlbumCollectionItem({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.copies,
    required this.frameLevel,
    required this.firstObtainedAt,
    required this.lastObtainedAt,
    this.card,
  });

  factory AlbumCollectionItem.fromMap(Map<String, dynamic> m) {
    final cardMap = m['album_cards'] as Map<String, dynamic>?;
    return AlbumCollectionItem(
      id:               m['id'] as String,
      userId:           m['user_id'] as String,
      cardId:           m['card_id'] as String,
      copies:           (m['copies'] as num?)?.toInt() ?? 1,
      frameLevel:       m['frame_level'] as String? ?? 'normal',
      firstObtainedAt:  m['first_obtained_at'] as String? ?? '',
      lastObtainedAt:   m['last_obtained_at'] as String? ?? '',
      card:             cardMap != null ? AlbumCard.fromMap(cardMap) : null,
    );
  }

  bool get isDuplicate => copies > 1;
}

// ─── AlbumDefinition ──────────────────────────────────────
class AlbumDefinition {
  final String id;
  final String name;
  final String? description;
  final AlbumType albumType;
  final int sortOrder;
  final int? requiredUniquePlayers;
  final int requiredMinStars4;
  final int requiredMinStars5;
  final CardType? requiredCardType;
  final int? starFilter;
  final String? unlocksAlbumId;
  final String? rewardBannerId;
  final String? rewardTitle;
  final String? rewardDescription;
  final bool isActive;

  const AlbumDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.albumType,
    required this.sortOrder,
    this.requiredUniquePlayers,
    required this.requiredMinStars4,
    required this.requiredMinStars5,
    this.requiredCardType,
    this.starFilter,
    this.unlocksAlbumId,
    this.rewardBannerId,
    this.rewardTitle,
    this.rewardDescription,
    required this.isActive,
  });

  factory AlbumDefinition.fromMap(Map<String, dynamic> m) => AlbumDefinition(
        id:                     m['id'] as String,
        name:                   m['name'] as String,
        description:            m['description'] as String?,
        albumType:              m['album_type'] as String,
        sortOrder:              (m['sort_order'] as num?)?.toInt() ?? 0,
        requiredUniquePlayers:  (m['required_unique_players'] as num?)?.toInt(),
        requiredMinStars4:      (m['required_min_stars_4'] as num?)?.toInt() ?? 0,
        requiredMinStars5:      (m['required_min_stars_5'] as num?)?.toInt() ?? 0,
        requiredCardType:       m['required_card_type'] as String?,
        starFilter:             (m['star_filter'] as num?)?.toInt(),
        unlocksAlbumId:         m['unlocks_album_id'] as String?,
        rewardBannerId:         m['reward_banner_id'] as String?,
        rewardTitle:            m['reward_title'] as String?,
        rewardDescription:      m['reward_description'] as String?,
        isActive:               m['is_active'] as bool? ?? true,
      );

  bool get isLegendary => albumType == 'legendary';
  bool get isStars     => albumType == 'stars';
  bool get isCult      => albumType == 'cult';
}

// ─── AlbumProgress ────────────────────────────────────────
class AlbumProgress {
  final String id;
  final String userId;
  final String albumId;
  final int uniqueCards;
  final bool isCompleted;
  final String? completedAt;
  final bool rewardClaimed;
  final String updatedAt;

  const AlbumProgress({
    required this.id,
    required this.userId,
    required this.albumId,
    required this.uniqueCards,
    required this.isCompleted,
    this.completedAt,
    required this.rewardClaimed,
    required this.updatedAt,
  });

  factory AlbumProgress.fromMap(Map<String, dynamic> m) => AlbumProgress(
        id:            m['id'] as String,
        userId:        m['user_id'] as String,
        albumId:       m['album_id'] as String,
        uniqueCards:   (m['unique_cards'] as num?)?.toInt() ?? 0,
        isCompleted:   m['is_completed'] as bool? ?? false,
        completedAt:   m['completed_at'] as String?,
        rewardClaimed: m['reward_claimed'] as bool? ?? false,
        updatedAt:     m['updated_at'] as String? ?? '',
      );
}

// ─── PackOpenResult ───────────────────────────────────────
class PackOpenResult {
  final AlbumCard? player;
  final AlbumCard? team;
  final AlbumCard? competition;
  final AlbumCard? event;

  const PackOpenResult({
    this.player,
    this.team,
    this.competition,
    this.event,
  });

  List<AlbumCard> get allCards =>
      [player, team, competition, event].whereType<AlbumCard>().toList();

  bool get hasGoat => allCards.any((c) => c.isGoat);
}

// ─── AlbumsModel (estado global de la página) ─────────────
class AlbumsModel {
  final AlbumPacks? packs;
  final List<AlbumCollectionItem> collection;
  final List<AlbumDefinition> definitions;
  final Map<String, AlbumProgress> progressByAlbumId;

  const AlbumsModel({
    required this.packs,
    required this.collection,
    required this.definitions,
    required this.progressByAlbumId,
  });

  // Colección filtrada por tipo de álbum
  List<AlbumDefinition> get legendaryAlbums =>
      definitions.where((d) => d.isLegendary).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<AlbumDefinition> get starsAlbums =>
      definitions.where((d) => d.isStars).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<AlbumDefinition> get cultAlbums =>
      definitions.where((d) => d.isCult).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // Helpers de colección
  int get totalUniqueCards => collection.length;

  int get totalCopies =>
      collection.fold(0, (sum, item) => sum + item.copies);

  int get goatCards =>
      collection.where((i) => i.card?.isGoat == true).length;

  AlbumProgress? progressFor(String albumId) => progressByAlbumId[albumId];
}
