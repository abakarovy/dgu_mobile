/// Цели web handoff (см. docs/MOBILE_WEB_HANDOFF.md).
abstract final class StaffWebHandoff {
  static String target({required bool isNews, required bool isCreate}) {
    if (isNews) return isCreate ? 'news_create' : 'news_edit';
    return isCreate ? 'event_create' : 'event_edit';
  }
}
