/// Сравнение semver `major.minor.patch` (как в контракте `/api/health`).
final class AppSemver {
  AppSemver({required this.major, required this.minor, required this.patch});

  final int major;
  final int minor;
  final int patch;

  static AppSemver? parse(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    final plus = s.indexOf('+');
    if (plus >= 0) s = s.substring(0, plus);
    final dash = s.indexOf('-');
    if (dash >= 0) s = s.substring(0, dash);
    final parts = s.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p.trim());
      if (n == null || n < 0) return null;
      nums.add(n);
    }
    while (nums.length < 3) {
      nums.add(0);
    }
    return AppSemver(major: nums[0], minor: nums[1], patch: nums[2]);
  }

  /// Отрицательно, если [this] < [other]; 0 — равны; положительно, если больше.
  int compareTo(AppSemver other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      if (pair.$1 != pair.$2) return pair.$1.compareTo(pair.$2);
    }
    return 0;
  }

  static bool isLessThan(String left, String right) {
    final a = parse(left);
    final b = parse(right);
    if (a == null || b == null) return false;
    return a.compareTo(b) < 0;
  }

  static bool isGreaterOrEqual(String left, String right) {
    final a = parse(left);
    final b = parse(right);
    if (a == null || b == null) return false;
    return a.compareTo(b) >= 0;
  }
}
