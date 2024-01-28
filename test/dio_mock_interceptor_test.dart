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
    // connectTimeout: const Duration(seconds: 5),
  ));

  dio.interceptors.add(MockInterceptor());

  group('Test basic usages', () {
    test('test data usage', () async {
      Response response = await dio.post("/api/basic/data");
      String json = response.data;
      Map<String, dynamic> obj = jsonDecode(json);
      expect(obj['success'], true);
      expect(obj['code'], '0000');
      expect(obj['result']['test'], 'test');
    });

    test('test data usage with empty data', () async {
      Response response = await dio.post("/api/basic/data/empty");
      String json = response.data;
      Map<String, dynamic> obj = jsonDecode(json);
      expect(obj.isEmpty, true);
      expect(obj['success'], null);
    });
  });

  group('Test template usages', () {
    test('test template usage without data block', () async {
      Response response = await dio.post("/api/template/without-data-block");
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

    test('test template usage without data block, no content', () async {
      Response response =
          await dio.post("/api/template/without-data-block/no-content");
      String? json = response.data;

      expect(json, isNot(null));
      Map<String, dynamic> data = jsonDecode(json!);
      expect(data.isEmpty, true);
    });

    test('test template usage without data block, no size', () async {
      Response response =
          await dio.post("/api/template/without-data-block/no-size");
      String json = response.data;
      Map<String, dynamic> obj = jsonDecode(json);
      expect(obj['id'], "test0");
      expect(obj['name'], "name_0");
    });

    test('test template usage with data block', () async {
      Response response = await dio.post("/api/template/with-data-block");
      String json = response.data;
      Map<String, dynamic> data = jsonDecode(json);

      expect(data['id'], 'yong-xin');
      expect((data['listA'] as List).first['id'], 'test0');
      expect((data['listA'] as List).first['name'], 'name_0');
    });

    test('test template usage with data block ex2', () async {
      Response response = await dio.post("/api/template/with-data-block/ex2");
      String json = response.data;
      Map<String, dynamic> data = jsonDecode(json);

      expect(data['id'], 'yong-xin');
      expect((data['listA'] as List).first['id'], 'test0');
      expect((data['listA'] as List).first['name'], 'name_0');
      expect((data['field2']['listB'] as List).first['id'], 'test0');
    });
  });

  group('Test templates usages', () {
    test('test templates usage, ex1', () async {
      Response response = await dio.post("/api/templates/ex1");
      String json = response.data;
      Map<String, dynamic> data = jsonDecode(json);

      expect(data['id'], 'yong-xin');
      expect((data['listA'] as List).first['id'], 'test0');
      expect((data['listA'] as List).first['name'], 'name_0');
      expect((data['field']['listB'] as List).first['id'], 'test20');
      expect((data['field']['listB'] as List).first['name'], 'name2_0');
    });
  });

  group('Test expression usages', () {
    test('test data with req param', () async {
      Response response = await dio.post("/api/expression/req-data", data: {
        "name": 'Mercury',
        "name2": 'Ming',
      }, queryParameters: {
        "name3": 'Param',
      });
      String json = response.data;
      Map<String, dynamic> data = jsonDecode(json);

      expect(data['id'], 'yong-xin');
      expect(data['desc'], 'Hi Mercury, I am Ming_varSuffix');
      expect(data['desc2'], 'test header, application/json; charset=utf-8');
      expect(data['desc3'], 'test queryParameter, Param');
      expect(data['desc4'], 'test baseUrl, https://demo.yong-xin.tech');
      expect(data['desc5'], 'test method, POST');
      expect(data['desc6'], 'test path, /api/expression/req-data');
      //expect(data['desc7'], 'test uri, https://demo.yong-xin.tech/api/expression/req-data?name3=Param');
    });

    test('test data with req param(form data)', () async {
      Response response = await dio.post("/api/expression/req-data/form-data",
          data: FormData.fromMap({
            'name': 'dio',
            'date': DateTime.october,
          }));
      String json = response.data;
      Map<String, dynamic> data = jsonDecode(json);

      expect(data['desc'], 'Hi dio, test date: 10');
    });

    test('test templates with vars', () async {
      Response response =
          await dio.post("/api/expression/vars", data: {"name": 'Mercury'});
      String json = response.data;
      Map<String, dynamic> data = jsonDecode(json);

      expect(data['id'], 'yong-xin');
      expect(data['arry'], ["May", "YongXin", "John"]);
      expect(data['objA'], {"name": "objName"});
      expect((data['listA'] as List).first['id'], 'test0');
      expect((data['listA'] as List).first['name'], 'name_0');
      expect((data['listA'] as List).first['group'], 'g_May');
      expect((data['listA'] as List).elementAt(1)['group'], 'g_YongXin');
      expect((data['listA'] as List).elementAt(2)['group'], 'g_John');
      expect((data['listA'] as List).last['group'], 'g_May');
      expect((data['listA'] as List).last['req-data-name'], 'test_Mercury');
      expect((data['field']['listB'] as List).first['id'], 'test20');
      expect((data['field']['listB'] as List).first['name'], 'name2_0');
    });

    test('test template with vars, template example', () async {
      Response response = await dio
          .post("/api/expression/vars/template-ex", data: {"name": 'Mercury'});
      String json = response.data;
      Map<String, dynamic> data = jsonDecode(json);

      expect(data['id'], 'yong-xin');
      expect((data['listA'] as List).first['id'], 'test0');
      expect((data['listA'] as List).first['name'], 'name_0');
      expect((data['listA'] as List).first['group'], 'g_May');
      expect((data['listA'] as List).elementAt(1)['group'], 'g_YongXin');
      expect((data['listA'] as List).elementAt(2)['group'], 'g_John');
      expect((data['listA'] as List).last['group'], 'g_May');
      expect((data['listA'] as List).last['req-data-name'], 'test_a');
    });
  });
}
