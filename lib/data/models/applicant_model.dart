/// Абитуриент из `GET /api/v1/admin/applicants`.
class ApplicantListItem {
  const ApplicantListItem({
    required this.id,
    required this.fullName,
    this.examScore,
    required this.status,
  });

  final int id;
  final String fullName;
  final double? examScore;
  final String status;

  factory ApplicantListItem.fromJson(Map<String, dynamic> json) {
    final scoreRaw = json['exam_score'];
    double? score;
    if (scoreRaw is num) {
      score = scoreRaw.toDouble();
    } else if (scoreRaw != null) {
      score = double.tryParse('$scoreRaw');
    }
    return ApplicantListItem(
      id: json['id'] as int,
      fullName: (json['full_name'] ?? '').toString(),
      examScore: score,
      status: (json['status'] ?? '').toString(),
    );
  }
}

/// Карточка абитуриента: `GET /api/v1/admin/applicants/{id}`.
class ApplicantDetail extends ApplicantListItem {
  const ApplicantDetail({
    required super.id,
    required super.fullName,
    super.examScore,
    required super.status,
    required this.email,
    this.phone,
    this.phoneExtra,
  });

  final String email;
  final String? phone;
  final String? phoneExtra;

  factory ApplicantDetail.fromJson(Map<String, dynamic> json) {
    final base = ApplicantListItem.fromJson(json);
    return ApplicantDetail(
      id: base.id,
      fullName: base.fullName,
      examScore: base.examScore,
      status: base.status,
      email: (json['email'] ?? '').toString(),
      phone: json['phone'] as String?,
      phoneExtra: json['phone_extra'] as String?,
    );
  }
}

class ApplicantsPageResult {
  const ApplicantsPageResult({required this.items, required this.total});

  final List<ApplicantListItem> items;
  final int total;

  factory ApplicantsPageResult.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final list = raw is List ? raw : const <dynamic>[];
    return ApplicantsPageResult(
      items: list
          .whereType<Map>()
          .map((e) => ApplicantListItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse('${json['total']}') ?? list.length,
    );
  }
}

class PaymentCutoffResult {
  const PaymentCutoffResult({this.cutoffScore});

  final double? cutoffScore;

  factory PaymentCutoffResult.fromJson(Map<String, dynamic> json) {
    final raw = json['cutoff_score'];
    if (raw == null) return const PaymentCutoffResult();
    if (raw is num) return PaymentCutoffResult(cutoffScore: raw.toDouble());
    return PaymentCutoffResult(cutoffScore: double.tryParse('$raw'));
  }
}

class SetPaymentCutoffResult {
  const SetPaymentCutoffResult({
    required this.cutoffScore,
    required this.movedToPaymentCount,
    required this.pushSent,
    required this.pushFailed,
  });

  final double cutoffScore;
  final int movedToPaymentCount;
  final int pushSent;
  final int pushFailed;

  factory SetPaymentCutoffResult.fromJson(Map<String, dynamic> json) {
    final scoreRaw = json['cutoff_score'];
    final score = scoreRaw is num
        ? scoreRaw.toDouble()
        : double.tryParse('$scoreRaw') ?? 0;
    return SetPaymentCutoffResult(
      cutoffScore: score,
      movedToPaymentCount: json['moved_to_payment_count'] is int
          ? json['moved_to_payment_count'] as int
          : int.tryParse('${json['moved_to_payment_count']}') ?? 0,
      pushSent: json['push_sent'] is int
          ? json['push_sent'] as int
          : int.tryParse('${json['push_sent']}') ?? 0,
      pushFailed: json['push_failed'] is int
          ? json['push_failed'] as int
          : int.tryParse('${json['push_failed']}') ?? 0,
    );
  }
}
