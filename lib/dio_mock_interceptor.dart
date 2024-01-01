library dio_mock_interceptor;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class MockInterceptor extends Interceptor {
  late Future _futureManifestLoaded;
  final List<Future> _futuresBundleLoaded = [];
  final Map<String, Map<String, dynamic>> _routes = {};
  final RegExp _regexpIndex = RegExp(r'\$\{index\}');
  final RegExp _regexpTemplate = RegExp(r'"\$\{template\}"');

  MockInterceptor() {
    _futureManifestLoaded =
        rootBundle.loadString('AssetManifest.json').then((manifestContent) {
      Map<String, dynamic> manifestMap = json.decode(manifestContent);

      List<String> mockResourcePaths = manifestMap.keys
          .where((String key) => key.contains('mock/') && key.endsWith('.json'))
          .toList();
      if (mockResourcePaths.isEmpty) {
        return;
      }
      for (var path in mockResourcePaths) {
        Future bundleLoaded = rootBundle.load(path).then((ByteData data) {
          String routeModule = utf8.decode(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
          json.decode(routeModule).forEach((dynamic map) {
            Map<String, dynamic> route = map as Map<String, dynamic>;
            String path = route['path'] as String;
            _routes.putIfAbsent(path, () => route);
          });
        });
        _futuresBundleLoaded.add(bundleLoaded);
      }
    });
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    await _futureManifestLoaded;
    await Future.wait(_futuresBundleLoaded);

    Map<String, dynamic>? route = _routes[options.path];

    if (route == null) {
      handler.reject(DioException(
          requestOptions: options,
          error: "Can't find route setting: ${options.path}"));
      return;
    }

    String method = route['method'] as String;
    if (options.method != method) {
      handler.reject(DioException(
          requestOptions: options,
          error:
              "Can't find route setting: ${options.path}:${options.method}"));
      return;
    }

    int statusCode = route['statusCode'] as int;

    String? resData;
    Map<String, dynamic>? template = route['template'];

    Map<String, dynamic>? data = route['data'];

    if (template != null && data == null) {
      resData = _templateData(template);
    } else if (data != null) {
      resData = json.encode(data);

      dynamic opData = options.data;
      if (opData != null && opData is Map) {
        for (var entry in opData.entries) {
          RegExp regexpReqData = RegExp(r'\$\{req\.data\.' + entry.key + '\}');
          resData = resData?.replaceAll(regexpReqData, entry.value.toString());
        }
      }

      if (template != null) {
        String tData = _templateData(template)!;
        resData = resData?.replaceAll(_regexpTemplate, tData);
      }

      Map<String, dynamic>? templates = route['templates'];
      if (templates != null) {
        for (var entry in templates.entries) {
          Map<String, dynamic> template = entry.value;
          String tData = _templateData(template)!;
          RegExp regexpTemplate =
              RegExp(r'"\$\{templates\.' + entry.key + '\}"');
          resData = resData?.replaceAll(regexpTemplate, tData);
        }
      }
    }

    handler.resolve(Response(
      data: resData,
      requestOptions: options,
      statusCode: statusCode,
    ));
  }

  String? _templateData(Map<String, dynamic> template) {
    var content = template['content'];
    if (content == null) {
      return content;
    }

    int? size = template['size'];
    String sContent = json.encode(content);
    if (size == null) {
      return sContent.replaceAll(_regexpIndex, "0");
    }

    String joinString = List.generate(
        size, (index) => sContent.replaceAll(_regexpIndex, "$index")).join(",");
    return "[$joinString]";
  }
}
