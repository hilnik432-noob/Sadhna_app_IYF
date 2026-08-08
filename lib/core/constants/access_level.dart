/// Permission level for a `users/{uid}` document — completely separate from
/// [UserRole] (sadhana_entry.dart), which is the student's sadhna-card
/// category (Student / Job Going / etc). Mixing those two into one Firestore
/// field ("role") was the original bug here — this enum is the ONLY thing
/// that should ever be read to decide what a signed-in account is allowed to
/// see, stored in the `accessLevel` field.
enum AccessLevel {
  student,
  facilitator,
  superAdmin;

  static AccessLevel fromString(String? value) {
    switch (value) {
      case 'facilitator':
        return AccessLevel.facilitator;
      case 'super_admin':
        return AccessLevel.superAdmin;
      default:
        return AccessLevel.student;
    }
  }

  /// Firestore field value — snake_case to match existing rules conventions.
  String get value {
    switch (this) {
      case AccessLevel.student:
        return 'student';
      case AccessLevel.facilitator:
        return 'facilitator';
      case AccessLevel.superAdmin:
        return 'super_admin';
    }
  }

  bool get canSeeOwnStudentsOnly => this == AccessLevel.facilitator;
  bool get canSeeAllStudents => this == AccessLevel.superAdmin;
}

/// The facilitators (by dikshitName) who are super_admins — shown on the
/// separate Admin Login screen instead of the regular Facilitator Login
/// dropdown. MUST stay in sync with SUPER_ADMIN_DIKSHIT_NAMES in
/// scripts/seed_facilitator_accounts.py — both sides list the same two
/// people by design, not derived from one shared source (Dart app vs.
/// Python script can't literally share a constant).
const kSuperAdminDikshitNames = {'Nitai Nimai Prabhu Ji', 'HG Vishuddh Parth Prabhuji'};
