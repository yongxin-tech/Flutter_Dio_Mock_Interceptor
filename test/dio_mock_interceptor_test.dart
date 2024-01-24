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

  test('test data with template', () async {
    Response response = await dio.post("/api/data/template");
    String json = response.data;
    Map<String, dynamic> data = jsonDecode(json);

    expect(data['id'], 'yong-xin');
    expect((data['listA'] as List).first['id'], 'test0');
    expect((data['listA'] as List).first['name'], 'name_0');
  });

  test('test data2 with template', () async {
    Response response = await dio.post("/api/data/template2");
    String json = response.data;
    Map<String, dynamic> data = jsonDecode(json);

    expect(data['id'], 'yong-xin');
    expect((data['listA'] as List).first['id'], 'test0');
    expect((data['listA'] as List).first['name'], 'name_0');
    expect((data['field2']['listB'] as List).first['id'], 'test0');
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
    expect(obj['id'], "test0");
    expect(obj['name'], "name_0");
  });

  test('test data with templates', () async {
    Response response = await dio.post("/api/data/templates");
    String json = response.data;
    Map<String, dynamic> data = jsonDecode(json);

    expect(data['id'], 'yong-xin');
    expect((data['listA'] as List).first['id'], 'test0');
    expect((data['listA'] as List).first['name'], 'name_0');
    expect((data['field']['listB'] as List).first['id'], 'test20');
    expect((data['field']['listB'] as List).first['name'], 'name2_0');
  });

  test('test data with req param', () async {
    Response response = await dio.post("/api/data/req-param", data: {
      "name": 'Mercury',
      "name2": 'Ming',
    });
    String json = response.data;
    Map<String, dynamic> data = jsonDecode(json);

    expect(data['id'], 'yong-xin');
    expect(data['desc'], 'Hi, Mercury, I am Ming');
  });

  test('test template with vars', () async {
    Response response = await dio.post("/api/data/vars");
    String json = response.data;
    Map<String, dynamic> data = jsonDecode(json);

    expect(data['id'], 'yong-xin');
    expect(data['arry'], [
      "May",
      "YongXin",
      "John"
    ]);
    expect(data['objA'], {
      "name": "objName"
    });
    expect((data['listA'] as List).first['id'], 'test0');
    expect((data['listA'] as List).first['name'], 'name_0');
    expect((data['listA'] as List).first['group'], 'g_May');
    expect((data['listA'] as List).elementAt(1)['group'], 'g_YongXin');
    expect((data['listA'] as List).elementAt(2)['group'], 'g_John');
    expect((data['listA'] as List).last['group'], 'g_May');
    expect((data['field']['listB'] as List).first['id'], 'test20');
    expect((data['field']['listB'] as List).first['name'], 'name2_0');
  });
}
