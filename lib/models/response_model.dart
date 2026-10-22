import 'dart:convert';

// =====================================================================================
// Parsing response (perilaku Gson: field String boleh berisi angka/boolean, field hilang = null)
// =====================================================================================

class GsonConversionException implements Exception {
  final String message;
  GsonConversionException(this.message);

  @override
  String toString() => 'GsonConversionException: $message';
}

String? gsonString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is num || v is bool) return v.toString();
  throw GsonConversionException('Expected a string but was ${v.runtimeType}');
}

bool gsonBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  throw GsonConversionException('Expected a boolean but was ${v.runtimeType}');
}

int? gsonLong(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.parse(v);
  throw GsonConversionException('Expected a long but was ${v.runtimeType}');
}

// =====================================================================================
// data/remote/response
// =====================================================================================

/// OrderFormModel.java
class OrderFormModel {
  String? id;
  String? question;
  String? answer;
  String? idQuestion; // @SerializedName("id_question")

  OrderFormModel({this.id, this.question, this.answer, this.idQuestion});

  factory OrderFormModel.fromJson(Map<String, dynamic> json) => OrderFormModel(
        id: gsonString(json['id']),
        question: gsonString(json['question']),
        answer: gsonString(json['answer']),
        idQuestion: gsonString(json['id_question']),
      );

  Map<String, dynamic> toPdfMap() => {'question': question, 'answer': answer};

  @override
  String toString() => 'OrderFormModel{id: $id, question: $question, answer: $answer, idQuestion: $idQuestion}';
}

/// OrderFormListDeserializer.java
///  - kreenconnect: real array
///  - jipremium: array encoded as a JSON string
List<OrderFormModel> orderFormListFromJson(dynamic json) {
  final List<OrderFormModel> result = [];

  if (json == null) {
    return result;
  }

  List jsonArray;

  if (json is List) {
    // kreenconnect: real array
    jsonArray = json;
  } else if (json is String) {
    // jipremium: array encoded as a JSON string
    final raw = json;
    if (raw.trim().isEmpty || raw.trim().toLowerCase() == "null") {
      return result;
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) {
        return result;
      }
      jsonArray = parsed;
    } catch (e) {
      return result;
    }
  } else {
    return result;
  }

  for (final el in jsonArray) {
    if (el is Map) {
      result.add(OrderFormModel.fromJson(Map<String, dynamic>.from(el)));
    } else if (el != null) {
      throw GsonConversionException('Expected BEGIN_OBJECT but was ${el.runtimeType}');
    }
  }
  return result;
}

/// DetailModel.java
class DetailModel {
  String? fullname;
  String? email;
  List<OrderFormModel>? orderForms; // @SerializedName("order_forms") @JsonAdapter(OrderFormListDeserializer)

  DetailModel({this.fullname, this.email, this.orderForms});

  factory DetailModel.fromJson(Map<String, dynamic> json) => DetailModel(
        fullname: gsonString(json['fullname']),
        email: gsonString(json['email']),
        // Gson tidak memanggil adapter kalau key tidak ada -> null
        orderForms: json.containsKey('order_forms') ? orderFormListFromJson(json['order_forms']) : null,
      );

  @override
  String toString() => 'DetailModel{fullname: $fullname, email: $email, orderForms: $orderForms}';
}

/// DataModel.java
class DataModel {
  String? id;
  String? showQr; // @SerializedName("show_qr")
  DetailModel? detail;

  DataModel({this.id, this.showQr, this.detail});

  factory DataModel.fromJson(Map<String, dynamic> json) => DataModel(
        id: gsonString(json['id']),
        showQr: gsonString(json['show_qr']),
        detail: json['detail'] is Map ? DetailModel.fromJson(Map<String, dynamic>.from(json['detail'])) : null,
      );

  @override
  String toString() => 'DataModel{id: $id, showQr: $showQr, detail: $detail}';
}

/// ResponseModel.java
class ResponseModel {
  bool success;
  DataModel? data;
  String? message;

  ResponseModel({this.success = false, this.data, this.message});

  factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
        success: gsonBool(json['success']),
        data: json['data'] is Map ? DataModel.fromJson(Map<String, dynamic>.from(json['data'])) : null,
        message: gsonString(json['message']),
      );
}

/// ListQuestionOrderFormResponse.QuestionOrderForm
class QuestionOrderForm {
  // FIXED: field aslinya "id_order_form_master", bukan "id_question"
  String? idQuestion;
  String? question;

  QuestionOrderForm({this.idQuestion, this.question});

  factory QuestionOrderForm.fromJson(Map<String, dynamic> json) => QuestionOrderForm(
        idQuestion: gsonString(json['id_order_form_master']),
        question: gsonString(json['question']),
      );
}

/// ListQuestionOrderFormResponse.java
class ListQuestionOrderFormResponse {
  bool success;
  String? message;
  List<QuestionOrderForm>? data;

  ListQuestionOrderFormResponse({this.success = false, this.message, this.data});

  factory ListQuestionOrderFormResponse.fromJson(Map<String, dynamic> json) => ListQuestionOrderFormResponse(
        success: gsonBool(json['success']),
        message: gsonString(json['message']),
        data: json['data'] is List
            ? (json['data'] as List).whereType<Map>().map((e) => QuestionOrderForm.fromJson(Map<String, dynamic>.from(e))).toList()
            : null,
      );
}

// =====================================================================================
// model/
// =====================================================================================

/// ModelLogo.java
class ModelLogo {
  String? id;
  String? img;

  ModelLogo({this.id, this.img});
}

/// SliderItem.java
class SliderItem {
  String? description;
  String? imageUrl;

  SliderItem({this.description, this.imageUrl});
}
