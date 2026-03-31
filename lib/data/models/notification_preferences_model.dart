class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    required this.pushNewGrades,
    required this.pushScheduleChange,
    required this.pushAssignmentDeadlines,
    required this.pushCollegeNews,
    required this.pushCollegeEvents,
  });

  final bool pushNewGrades;
  final bool pushScheduleChange;
  final bool pushAssignmentDeadlines;
  final bool pushCollegeNews;
  final bool pushCollegeEvents;

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    bool b(dynamic v, {required bool fallback}) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
        if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
      }
      return fallback;
    }

    return NotificationPreferencesModel(
      pushNewGrades: b(json['push_new_grades'], fallback: true),
      pushScheduleChange: b(json['push_schedule_change'], fallback: true),
      pushAssignmentDeadlines: b(json['push_assignment_deadlines'], fallback: true),
      pushCollegeNews: b(json['push_college_news'], fallback: true),
      pushCollegeEvents: b(json['push_college_events'], fallback: true),
    );
  }

  Map<String, dynamic> toPatchJson() => {
        'push_new_grades': pushNewGrades,
        'push_schedule_change': pushScheduleChange,
        'push_assignment_deadlines': pushAssignmentDeadlines,
        'push_college_news': pushCollegeNews,
        'push_college_events': pushCollegeEvents,
      };

  NotificationPreferencesModel copyWith({
    bool? pushNewGrades,
    bool? pushScheduleChange,
    bool? pushAssignmentDeadlines,
    bool? pushCollegeNews,
    bool? pushCollegeEvents,
  }) {
    return NotificationPreferencesModel(
      pushNewGrades: pushNewGrades ?? this.pushNewGrades,
      pushScheduleChange: pushScheduleChange ?? this.pushScheduleChange,
      pushAssignmentDeadlines: pushAssignmentDeadlines ?? this.pushAssignmentDeadlines,
      pushCollegeNews: pushCollegeNews ?? this.pushCollegeNews,
      pushCollegeEvents: pushCollegeEvents ?? this.pushCollegeEvents,
    );
  }
}

