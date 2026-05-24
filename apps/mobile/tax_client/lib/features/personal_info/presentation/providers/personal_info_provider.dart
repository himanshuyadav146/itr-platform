import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/personal_info/data/repositories/personal_info_repository_impl.dart';
import 'package:tax_client/features/personal_info/domain/usecases/add_personal_details.dart';
import 'package:tax_client/features/personal_info/domain/usecases/get_personal_details.dart';
import 'package:tax_client/features/personal_info/domain/usecases/get_itr_by_user.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';
import 'package:tax_client/features/personal_info/presentation/viewmodel/personal_info_view_model.dart';

import 'package:tax_client/core/common/enums/journey_type.dart';

/// DI: Exposes the `AddPersonalDetails` use case with its repository dependency.
/// Presentation layer consumes this without direct knowledge of repository wiring.
final addPersonalDetailsProvider = Provider<AddPersonalDetails>((ref) {
  return AddPersonalDetails(ref.watch(personalInfoRepositoryProvider));
});

/// StateProvider to manage the selected Journey Type (ITR, E-Verify, etc.)
final journeyTypeProvider = StateProvider<JourneyType>((ref) => JourneyType.ITR);


/// DI: Exposes the `GetPersonalDetails` use case with its repository dependency.
final getPersonalDetailsProvider = Provider<GetPersonalDetails>((ref) {
  return GetPersonalDetails(ref.watch(personalInfoRepositoryProvider));
});

/// DI: Exposes the `GetItrByUser` use case with its repository dependency.
final getItrByUserProvider = Provider<GetItrByUser>((ref) {
  return GetItrByUser(ref.watch(personalInfoRepositoryProvider));
});

/// DI: ViewModel provider managing personal info UI state and actions.
/// Injects the use case and exposes reactive state to widgets.
final personalInfoViewModelProvider =
    StateNotifierProvider<PersonalInfoViewModel, PersonalInfoState>((ref) {
  return PersonalInfoViewModel(
    ref.watch(addPersonalDetailsProvider),
    ref.watch(getPersonalDetailsProvider),
    ref.watch(getItrByUserProvider),
    ref.watch(tokenStorageProvider),
  );
});
