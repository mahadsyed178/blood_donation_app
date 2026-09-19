enum SplashStatus {
  loading,
  authenticated,
  unauthenticated,

  /// A stored session couldn't be verified because the server is unreachable.
  error,
}

class SplashState {
  final SplashStatus status;
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.loading,
    this.errorMessage,
  });

  SplashState copyWith({
    SplashStatus? status,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


