/// Элемент ленты с контентом: карточка или слот рекламы.
sealed class FeedAdSlot {
  const FeedAdSlot();

  factory FeedAdSlot.content(int index) = FeedAdContentSlot;
  factory FeedAdSlot.ad(int slotId) = FeedAdAdSlot;
}

final class FeedAdContentSlot extends FeedAdSlot {
  const FeedAdContentSlot(this.contentIndex);
  final int contentIndex;
}

final class FeedAdAdSlot extends FeedAdSlot {
  const FeedAdAdSlot(this.slotId);
  final int slotId;
}

/// Пустой список → один слот рекламы; иначе реклама между карточками.
abstract final class FeedAdSlots {
  FeedAdSlots._();

  static List<FeedAdSlot> build({
    required int contentCount,
    required bool insertAds,
  }) {
    if (!insertAds) {
      return [for (var i = 0; i < contentCount; i++) FeedAdSlot.content(i)];
    }
    if (contentCount == 0) {
      return [FeedAdSlot.ad(0)];
    }
    final out = <FeedAdSlot>[];
    var adId = 0;
    for (var i = 0; i < contentCount; i++) {
      out.add(FeedAdSlot.content(i));
      if (i < contentCount - 1) {
        out.add(FeedAdSlot.ad(adId++));
      }
    }
    return out;
  }
}
