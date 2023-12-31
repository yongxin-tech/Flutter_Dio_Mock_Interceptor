library dio_mock_interceptor;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class MockInterceptor extends Interceptor {
  late Future _futureManifestLoaded;
  final List<Future> _futuresBundleLoaded = [];
  final Map<String, Map<String, dynamic>> _routes = {};

  MockInterceptor() {
    _futureManifestLoaded =
        rootBundle.loadString('AssetManifest.json').then((manifestContent) {
      Map<String, dynamic> manifestMap = json.decode(manifestContent);

      List<String> mockResourcePaths = manifestMap.keys
          .where(
              (String key) => key.contains('mock/') && key.endsWith('.json'))
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

    Map<String, dynamic>? template = route['template'];
    if (template != null) {
      String? templateData = _templateData(template);
      handler.resolve(Response(
        data: templateData,
        requestOptions: options,
        statusCode: statusCode,
      ));
      return;
    }

    Map<String, dynamic>? data = route['data'];
    if (data != null) {
      String jsonData = json.encode(data);
      handler.resolve(Response(
        data: jsonData,
        requestOptions: options,
        statusCode: statusCode,
      ));
      return;
    }
    
    handler.resolve(Response(
      data: null,
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
    if (size != null) {
      String sContent = json.encode(content);
      RegExp regexp = RegExp(r'\$\{index\}');
      String joinString = List.generate(size, (index) => sContent.replaceAll(regexp, "$index"))
        .join(",");
      return "[$joinString]";
    }
    return json.encode(content);
  }
}
