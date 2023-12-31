import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_mock_interceptor/dio_mock_interceptor.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    Dio dio = Dio(BaseOptions(
        baseUrl: "https://demo.yong-xin.tech",
        headers: {"content-type": "application/json; charset=utf-8"},
    ));

    dio.interceptors.add(MockInterceptor());
    
    test('test object data', () async {
        Response response = await dio.post("/api/login");
        String json = response.data;
        Map<String, dynamic> obj = jsonDecode(json);
        expect(obj['success'], true);
        expect(obj['code'], '0000');
        expect(obj['result']['test'], 'test');
    });

    test('test empty data', () async {
        Response response = await dio.post("/api/logout");
        String json = response.data;
        Map<String, dynamic> obj = jsonDecode(json);
        expect(obj.isEmpty, true);
        expect(obj['success'], null);
    });

    test('test list template', () async {
        Response response = await dio.post("/api/template/list");
        String json = response.data;
        List<dynamic> list = jsonDecode(json);
        expect(list.length, 100000);
        expect(list.first['id'], 'test0');
        expect(list.first['name'], 'name_0');
        expect(list[3]['id'], 'test3');
        expect(list[3]['name'], 'name_3');
        expect(list.last['id'], 'test99999');
        expect(list.last['name'], 'name_99999');
    });

    test('test no content template', () async {
        Response response = await dio.post("/api/template/nocontent");
        String? json = response.data;
        expect(json, null);
    });

    test('test no size template', () async {
        Response response = await dio.post("/api/template/nosize");
        String json = response.data;
        Map<String, dynamic> obj = jsonDecode(json);
        expect(obj['id'], "test\${index}");
        expect(obj['name'], "name_\${index}");
    });
}
