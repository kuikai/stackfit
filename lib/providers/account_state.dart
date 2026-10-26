import '../services/account/account_storage.dart';

enum SaveStatus { localOnly, saved, saving, offline, error }

class AccountState {
  const AccountState({
    this.session,
    this.saveStatus = SaveStatus.localOnly,
    this.errorMessage,
    this.hasUnmovedDeviceData = false,
    this.promptMove = false,
    this.busy = false,
  });

  final AccountSession? session;
  final SaveStatus saveStatus;
  final String? errorMessage;
  final bool hasUnmovedDeviceData;
  final bool promptMove;
  final bool busy;

  bool get isSignedIn => session != null;

  AccountState copyWith({
    AccountSession? session,
    bool clearSession = false,
    SaveStatus? saveStatus,
    String? errorMessage,
    bool clearError = false,
    bool? hasUnmovedDeviceData,
    bool? promptMove,
    bool? busy,
  }) {
    return AccountState(
      session: clearSession ? null : (session ?? this.session),
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasUnmovedDeviceData: hasUnmovedDeviceData ?? this.hasUnmovedDeviceData,
      promptMove: promptMove ?? this.promptMove,
      busy: busy ?? this.busy,
    );
  }
}
