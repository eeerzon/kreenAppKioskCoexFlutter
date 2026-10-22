import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Hasil call ala Retrofit:
///  - [error] != null  -> onFailure(call, t)  (koneksi gagal / timeout / gagal parse body)
///  - selain itu       -> onResponse(call, response), [code] = response.code(), [body] = response.body()
class RetrofitResponse<T> {
  final int code;
  final T? body;
  final Object? error;

  const RetrofitResponse({this.code = 0, this.body, this.error});

  bool get isFailure => error != null;

  /// response.isSuccessful()
  bool get isSuccessful => error == null && code >= 200 && code < 300;
}

/// Volley onErrorResponse
class VolleyError implements Exception {
  final int? statusCode;
  final Object? cause;

  VolleyError({this.statusCode, this.cause});

  @override
  String toString() => 'VolleyError(statusCode: $statusCode, cause: $cause)';
}

class ApiService {
  static http.Client? _jipremiumClient;

  /// network_security_config.xml: jipremium.com -> @raw/gogetssl_intermediate + system
  static Future<http.Client> _jipremium() async {
    if (_jipremiumClient != null) return _jipremiumClient!;
    final context = SecurityContext(withTrustedRoots: true);
    try {
      final cert = await rootBundle.load('assets/certs/gogetssl_intermediate.pem');
      context.setTrustedCertificatesBytes(cert.buffer.asUint8List());
    } catch (e) {
      debugPrint('gogetssl_intermediate.pem not loaded: $e');
    }
    return _jipremiumClient = IOClient(HttpClient(context: context));
  }

  // ===================================================================================
  // Volley (VolleySingleton + StringRequest POST, getParams())
  // ===================================================================================

  /// DefaultRetryPolicy(ClassLib.time_out(), DEFAULT_MAX_RETRIES = 1, DEFAULT_BACKOFF_MULT = 1)
  /// -> percobaan ke-1 timeout 10 detik, retry 1x dengan timeout 20 detik.
  static Future<String> _volleyPost(String url, Map<String, String> params) async {
    Duration currentTimeout = timeOut;
    int retry = 0;
    while (true) {
      try {
        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
              body: params,
            )
            .timeout(currentTimeout);
        if (response.statusCode < 200 || response.statusCode > 299) {
          throw VolleyError(statusCode: response.statusCode);
        }
        // StringRequest.parseNetworkResponse: charset dari header, default ISO-8859-1 (Volley 1.2.1)
        return _decodeVolley(response);
      } on TimeoutException catch (e) {
        if (retry >= 1) throw VolleyError(cause: e);
        retry++;
        currentTimeout += currentTimeout * 1;
      } on VolleyError {
        rethrow;
      } catch (e) {
        throw VolleyError(cause: e);
      }
    }
  }

  static String _decodeVolley(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final match = RegExp(r'charset=([^;]+)', caseSensitive: false).firstMatch(contentType);
    final charset = match?.group(1)?.trim().toLowerCase();
    if (charset == null || charset == 'iso-8859-1') return latin1.decode(response.bodyBytes);
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  /// LoginEvent.check_event() -> Config.URL_CHECK_EVENT
  static Future<String> postCheckEvent(String idEvent) {
    final params = {"id_event": idEvent};
    debugPrint("par : $params");
    return _volleyPost(urlCheckEvent, params);
  }

  /// redeem_process_() (versi lama, Volley) -> Config.URL_BOOKING_REDEEM
  static Future<String> postBookingRedeem(String idRedeem, String idTicket, String idEvent) {
    final params = {"id_redeem": idRedeem, "id_ticket": idTicket, "id_event": idEvent};
    debugPrint("par : $params");
    return _volleyPost(urlBookingRedeem, params);
  }

  // ===================================================================================
  // Retrofit (RetrofitClient / JipremiumRetrofitClient + GsonConverterFactory)
  // ===================================================================================

  static final http.Client _defaultClient = http.Client();

  static Future<RetrofitResponse<T>> _retrofitPost<T>(
    String url,
    Map<String, String> fields, {
    Map<String, String> headers = const {},
    required Duration timeout,
    required T Function(Map<String, dynamic>) fromJson,
    http.Client? client,
  }) async {
    try {
      final response = await (client ?? _defaultClient)
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/x-www-form-urlencoded', ...headers},
            body: fields,
          )
          .timeout(timeout);
      debugPrint("<-- ${response.statusCode} $url\n${response.body}");
      if (response.statusCode < 200 || response.statusCode > 299) {
        return RetrofitResponse(code: response.statusCode);
      }
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded == null) return RetrofitResponse(code: response.statusCode);
      if (decoded is! Map) {
        return RetrofitResponse(error: GsonConversionException('Expected BEGIN_OBJECT but was ${decoded.runtimeType}'));
      }
      return RetrofitResponse(code: response.statusCode, body: fromJson(Map<String, dynamic>.from(decoded)));
    } catch (e) {
      return RetrofitResponse(error: e);
    }
  }

  /// ApiService.fetchData -> @POST("booking_redeem3_coex_kiosk")
  static Future<RetrofitResponse<ResponseModel>> fetchData(String idRedeem, String idTicket, String idEvent) {
    return _retrofitPost(
      "${baseUrl}booking_redeem3_coex_kiosk",
      {"id_redeem": idRedeem, "id_ticket": idTicket, "id_event": idEvent},
      timeout: timeOut,
      fromJson: ResponseModel.fromJson,
    );
  }

  /// ApiService.listQuestionOrderForm -> @POST("listQuestionOrderForm") + @Header("API-Secret-Key")
  static Future<RetrofitResponse<ListQuestionOrderFormResponse>> listQuestionOrderForm(String secretKey, String idEvent) {
    return _retrofitPost(
      "${baseUrl}listQuestionOrderForm",
      {"id_event": idEvent},
      headers: {"API-Secret-Key": secretKey},
      timeout: timeOut,
      fromJson: ListQuestionOrderFormResponse.fromJson,
    );
  }

  /// ApiServiceJipremium.checkBooking -> @POST("order/check-qrcode") (+ interceptor API-Secret-Key)
  static Future<RetrofitResponse<ResponseModel>> checkBooking(String idOrder, String idEvent) async {
    return _retrofitPost(
      "${baseUrlJipremium}order/check-qrcode",
      {"id_order": idOrder, "id_event": idEvent},
      headers: {"API-Secret-Key": jipremiumSecretKey},
      timeout: timeOutJipremium,
      fromJson: ResponseModel.fromJson,
      client: await _jipremium(),
    );
  }
}
