import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resturant_delivery_boy/common/models/api_response_model.dart';
import 'package:resturant_delivery_boy/common/models/error_response_model.dart';
import 'package:resturant_delivery_boy/features/auth/screens/login_screen.dart';
import 'package:resturant_delivery_boy/features/splash/providers/splash_provider.dart';
import 'package:resturant_delivery_boy/localization/language_constrants.dart';
import 'package:resturant_delivery_boy/main.dart';

class ApiCheckerHelper {
  static void checkApi(ApiResponseModel apiResponse) {
    ErrorResponseModel error = getError(apiResponse);
    final Errors fallbackError =
        Errors(message: getTranslated('not_found', Get.context!)!);
    final Errors firstError = (error.errors != null && error.errors!.isNotEmpty)
        ? error.errors!.first
        : fallbackError;

    if (firstError.code == '401' || firstError.code == 'auth-001') {
      Provider.of<SplashProvider>(Get.context!, listen: false)
          .removeSharedData();
      Navigator.pushAndRemoveUntil(
          Get.context!,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false);
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
        content: Text(
            firstError.message ?? getTranslated('not_found', Get.context!)!,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
    }
  }

  static ErrorResponseModel getError(ApiResponseModel apiResponse) {
    ErrorResponseModel error;
    final dynamic payload = apiResponse.response?.data ?? apiResponse.error;

    try {
      error = ErrorResponseModel.fromJson(payload);
    } catch (_) {
      final String fallbackMessage = _extractErrorMessage(payload) ??
          apiResponse.error?.toString() ??
          getTranslated('not_found', Get.context!)!;
      error = ErrorResponseModel(
          errors: [Errors(code: '', message: fallbackMessage)]);
    }

    if (error.errors == null || error.errors!.isEmpty) {
      error = ErrorResponseModel(errors: [
        Errors(
            code: '',
            message: _extractErrorMessage(payload) ??
                apiResponse.error?.toString() ??
                getTranslated('not_found', Get.context!)!)
      ]);
    }

    return error;
  }

  static String? _extractErrorMessage(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is String) {
      final String message = payload.trim();
      return message.isNotEmpty ? message : null;
    }

    if (payload is Map) {
      final dynamic message = payload['message'] ?? payload['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return payload.toString();
  }
}
