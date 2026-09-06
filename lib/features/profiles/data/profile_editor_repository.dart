import '../../connection/domain/connected_router.dart';
import '../domain/profile_details.dart';
import '../domain/profile_draft.dart';
import '../domain/profile_edit_session.dart';

enum ProfileEditFailureKind {
  conflict,
  validation,
  apply,
  sessionExpired,
  unavailable,
}

class ProfileEditException implements Exception {
  const ProfileEditException(this.kind);

  final ProfileEditFailureKind kind;
}

abstract interface class ProfileEditorRepository {
  Future<ProfileEditSession> load(
    ConnectedRouter router,
    String section, {
    ProfileDetails? currentDetails,
  });

  Future<void> apply(
    ConnectedRouter router,
    ProfileEditSession session,
    ProfileDraft draft,
  );
}
