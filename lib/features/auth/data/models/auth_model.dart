import "package:freezed_annotation/freezed_annotation.dart";
import "package:seguridad_ciudadana_app/features/auth/data/models/user_model.dart";

part "auth_model.freezed.dart";
part "auth_model.g.dart";

@freezed
class AuthModel with _$AuthModel {
  const factory AuthModel({
    required String token,
    required UserModel user,
  }) = _AuthModel;

  factory AuthModel.fromJson(Map<String, dynamic> json) => _$AuthModelFromJson(json);
}
