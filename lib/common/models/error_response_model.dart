import 'dart:convert';

/// errors : [{"code":"l_name","message":"The last name field is required."},{"code":"password","message":"The password field is required."}]

class ErrorResponseModel {
  List<Errors>? _errors;

  List<Errors>? get errors => _errors;

  ErrorResponseModel({List<Errors>? errors}) {
    _errors = errors;
  }

  ErrorResponseModel.fromJson(dynamic json) {
    final Map<String, dynamic>? data = _asMap(json);
    if (data == null) {
      return;
    }

    final dynamic errors = data["errors"];
    if (errors is List) {
      _errors = [];
      for (var v in errors) {
        final Errors? error = _parseError(v);
        if (error != null) {
          _errors!.add(error);
        }
      }
    } else if (errors is Map || errors is String) {
      final Errors? error = _parseError(errors);
      if (error != null) {
        _errors = [error];
      }
    } else if (data["message"] is String) {
      _errors = [Errors(message: data["message"] as String)];
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_errors != null) {
      map["errors"] = _errors!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Map<String, dynamic>? _asMap(dynamic json) {
  if (json is Map<String, dynamic>) {
    return json;
  }

  if (json is Map) {
    return Map<String, dynamic>.from(json);
  }

  if (json is String && json.isNotEmpty) {
    try {
      final dynamic decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Backend can return plain text (for example, "Internal Server Error").
      // Return a synthetic map so callers can still show a usable message.
      return {'message': json};
    }
  }

  return null;
}

Errors? _parseError(dynamic json) {
  if (json is Map<String, dynamic> || json is Map) {
    return Errors.fromJson(json);
  }

  if (json is String && json.isNotEmpty) {
    return Errors(message: json);
  }

  return null;
}

/// code : "l_name"
/// message : "The last name field is required."

class Errors {
  String? _code;
  String? _message;

  String? get code => _code;
  String? get message => _message;

  Errors({String? code, String? message}) {
    _code = code;
    _message = message;
  }

  Errors.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      _code = json["code"]?.toString();
      _message = json["message"]?.toString();
      return;
    }

    if (json is Map) {
      _code = json["code"]?.toString();
      _message = json["message"]?.toString();
      return;
    }

    if (json is String) {
      _message = json;
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["code"] = _code;
    map["message"] = _message;
    return map;
  }
}
