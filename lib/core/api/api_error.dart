import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

@freezed
abstract class ApiErrorDto with _$ApiErrorDto {
  const factory ApiErrorDto({
    required String code,
    required String message,
    String? field,
    required bool retryable,
  }) = _ApiErrorDto;
  factory ApiErrorDto.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDtoFromJson(json);
}
