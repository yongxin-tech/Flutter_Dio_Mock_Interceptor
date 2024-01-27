import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_mock_interceptor/dio_mock_interceptor.dart';

void main() async {
  Dio dio = Dio(BaseOptions());

  dio.interceptors.add(MockInterceptor());

  Response response =
      await dio.post("/api/basic/data"); // the same path as common.json
  String json = response.data;
  if (json.isEmpty) {
    throw Exception('response is empty');
  }

  Map<String, dynamic> data = jsonDecode(json);
  bool isSuccess = data['success'] as bool;
  print(isSuccess); // true
  Map<String, dynamic> result = data['result'];
  print(result['test']); //test
}
