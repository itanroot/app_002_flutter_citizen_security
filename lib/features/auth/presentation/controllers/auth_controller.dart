import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seguridad_ciudadana_app/features/auth/domain/entities/user_entity.dart';
import 'package:seguridad_ciudadana_app/injection/injection.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserEntity? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  AuthController(this.ref) : super(AuthState());

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase.execute(username, password);

    if (result.isLeft()) {
      result.fold((failure) {
        // devolver el mensaje de error que genera el backend en "result"
        state = state.copyWith(isLoading: false, error: failure.message);
        
      }, (_) {});
      return;
    }

    final getUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    final userResult = await getUserUseCase.execute();
    userResult.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final registerUseCase = ref.read(registerUseCaseProvider);
    final result = await registerUseCase.execute(name, email, password);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase.execute();
    state = AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
