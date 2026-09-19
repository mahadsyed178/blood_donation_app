import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../repositories/account_repositories.dart';
import '../repositories/auth_repository.dart';
import '../repositories/blood_request_repository.dart';
import '../repositories/chat_repository.dart';
import '../storage/token_storage.dart';

/// Dependency graph. Screens never touch these directly — they go through
/// the feature providers, which go through the repositories.

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStorage: ref.watch(tokenStorageProvider)),
);

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

final donorRepositoryProvider =
    Provider<DonorRepository>((ref) => DonorRepository(ref.watch(apiClientProvider)));

final requestorRepositoryProvider = Provider<RequestorRepository>(
  (ref) => RequestorRepository(ref.watch(apiClientProvider)),
);

final hospitalRepositoryProvider = Provider<InstitutionRepository>(
  (ref) => InstitutionRepository.hospital(ref.watch(apiClientProvider)),
);

final organizationRepositoryProvider = Provider<InstitutionRepository>(
  (ref) => InstitutionRepository.organization(ref.watch(apiClientProvider)),
);

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository(ref.watch(apiClientProvider)));

final bloodRequestRepositoryProvider = Provider<BloodRequestRepository>(
  (ref) => BloodRequestRepository(ref.watch(apiClientProvider)),
);

final requestMatchRepositoryProvider = Provider<RequestMatchRepository>(
  (ref) => RequestMatchRepository(ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);
