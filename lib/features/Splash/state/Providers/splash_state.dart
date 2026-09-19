enum SplashStatus {
  loading,
  authenticated,
  unauthenticated,
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


