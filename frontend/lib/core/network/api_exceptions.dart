import 'dart:io';
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final Map<String, String> fieldErrors;
  const ApiException(this.message, {this.status, this.fieldErrors = const {}});

  @override
  String toString() => message;

  static String _flat(dynamic v) {
    if (v is List) return v.map(_flat).join(' ');
    if (v is Map) return v.values.map(_flat).join(' ');
    return v.toString();
  }

  static String _defaultFor(int? code) {
    if (code == 401) return 'Your session has expired. Please sign in again.';
    if (code == 403) return "You don't have permission to do that.";
    if (code == 404) return 'We could not find what you were looking for.';
    if (code == 409) return 'That conflicts with an existing record.';
    if (code == 429) return 'Too many requests. Please wait a moment.';
    if (code != null && code >= 500) return 'Something went wrong on our side. Please try again shortly.';
    return 'Something went wrong. Please try again.';
  }

  factory ApiException.from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ApiException('The server took too long to respond. Please try again.');
        case DioExceptionType.connectionError:
          return const ApiException("Can't reach ErgoSpace. Check your internet connection and server address.");
        default:
          break;
      }
      if (e.error is SocketException) {
        return const ApiException("Can't reach ErgoSpace. Check your internet connection.");
      }
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final fields = <String, String>{};
      String? msg;
      if (data is Map) {
        data.forEach((k, v) {
          if (k == 'detail' || k == 'message' || k == 'error') {
            msg = _flat(v);
          } else {
            fields[k.toString()] = _flat(v);
          }
        });
      } else if (data is List) {
        msg = _flat(data);
      }
      msg ??= fields.isNotEmpty
          ? fields.entries.map((x) => x.key == 'non_field_errors' ? x.value : '${x.key}: ${x.value}').join('\n')
          : null;
      return ApiException(msg ?? _defaultFor(code), status: code, fieldErrors: fields);
    }
    return ApiException(e.toString());
  }
}

Future<T> guard<T>(Future<T> Function() f) async {
  try {
    return await f();
  } catch (e) {
    throw ApiException.from(e);
  }
}
