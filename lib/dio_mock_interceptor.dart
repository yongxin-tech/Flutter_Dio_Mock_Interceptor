library dio_mock_interceptor;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:template_expressions/template_expressions.dart';

class MockInterceptor extends Interceptor {
  late Future _futureManifestLoaded;
  final List<Future> _futuresBundleLoaded = [];
  final Map<String, Map<String, dynamic>> _routes = {};
  final RegExp _regexpTemplate = RegExp(r'"\$\{template\}"');
  static const StandardExpressionSyntax _exSyntax = StandardExpressionSyntax();

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

    Map<String, dynamic>? template = route['template'];
    Map<String, dynamic>? data = route['data'];

    if (template == null && data == null) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: statusCode,
      ));
      return;
    }

    Map<String, dynamic>? vars = route['vars'];
    var exContext = vars ?? {};

    exContext.putIfAbsent(
        'req',
        () => {
              'headers': options.headers,
            });

    if (options.data != null && options.data is Map) {
      exContext.update('req', (value) {
        value['data'] = options.data;
        return value;
      });
    }

    if (template != null && data == null) {
      String resData = _templateData(template, exContext);
      if (vars != null && vars.isNotEmpty) {
        resData = _replaceVarObjs(resData, vars);
      }

      resData = Template(
        syntax: [_exSyntax],
        value: resData,
      ).process(context: exContext);

      handler.resolve(Response(
        data: resData,
        requestOptions: options,
        statusCode: statusCode,
      ));
      return;
    }

    String resData = json.encode(data);

    if (template != null) {
      String tData = _templateData(template, exContext);
      resData = resData.replaceAll(_regexpTemplate, tData);
    }

    Map<String, dynamic>? templates = route['templates'];
    if (templates != null && templates.isNotEmpty) {
      for (var entry in templates.entries) {
        Map<String, dynamic> template = entry.value;
        String tData = _templateData(template, exContext);
        RegExp regexpTemplate = RegExp(r'"\$\{templates\.' + entry.key + '}"');
        resData = resData.replaceAll(regexpTemplate, tData);
      }
    }

    if (vars != null && vars.isNotEmpty) {
      resData = _replaceVarObjs(resData, vars);
    }

    resData = Template(
      syntax: [_exSyntax],
      value: resData,
    ).process(context: exContext);

    handler.resolve(Response(
      data: resData,
      requestOptions: options,
      statusCode: statusCode,
    ));
  }

  String _replaceVarObjs(String resData, Map<String, dynamic>? vars) {
    if (vars == null || vars.isEmpty) {
      return resData;
    }
    for (var element in vars.entries) {
      var vKey = element.key;
      var vValue = element.value;
      if (vValue is Iterable || vValue is Map) {
        resData = resData.replaceAll(
            RegExp(r'"\$\{' + vKey + '\}"'), json.encode(vValue));
      }
    }
    return resData;
  }

  String _templateData(
      Map<String, dynamic> template, Map<String, dynamic> exContext) {
    var content = template['content'];
    if (content == null) {
      return "{}";
    }

    int? size = template['size'];
    String sContent = json.encode(content);

    var exTemplate = Template(
      syntax: [_exSyntax],
      value: sContent,
    );

    if (size == null) {
      exContext.putIfAbsent('index', () => 0);
      return exTemplate.process(context: exContext);
    }

    String joinString = List.generate(size, (index) {
      exContext.addAll({'index': index});
      return exTemplate.process(context: exContext);
    }).join(",");
    return "[$joinString]";
  }
}
