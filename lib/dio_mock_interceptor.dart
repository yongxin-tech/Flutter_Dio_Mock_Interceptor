library dio_mock_interceptor;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:template_expressions/template_expressions.dart';

class MockInterceptor extends Interceptor {
  late Future _futureManifestLoaded;
  final List<Future> _futuresBundleLoaded = [];
  final Map<String, Map<String, dynamic>> _routes = {};
  final RegExp _regexpIndex = RegExp(r'\$\{index\}');
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

    String? resData;
    Map<String, dynamic>? template = route['template'];
    Map<String, dynamic>? vars = route['vars'];
    Map<String, dynamic>? data = route['data'];

    var exContext = {
    };

    if (vars != null) {
      exContext.addAll(vars);
    }
    
    if (template != null && data == null) {
      resData = _templateData(template, exContext);
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
        String tData = _templateData(template, exContext)!;
        resData = resData?.replaceAll(_regexpTemplate, tData);
      }

      Map<String, dynamic>? templates = route['templates'];
      if (templates != null) {
        for (var entry in templates.entries) {
          Map<String, dynamic> template = entry.value;
          String tData = _templateData(template, exContext)!;
          RegExp regexpTemplate =
              RegExp(r'"\$\{templates\.' + entry.key + '\}"');
          resData = resData?.replaceAll(regexpTemplate, tData);
        }
      }

      if (vars != null) {
        vars.entries.forEach((element) {
            var vKey = element.key;
            var vValue = element.value;
            if (vValue is Iterable || vValue is Map) {
              resData = resData?.replaceAll(RegExp(r'"\$\{' + vKey + '\}"'), json.encode(vValue));
            }
        });

        var exTemplate = Template(
          syntax: [_exSyntax],
          value: resData!,
        );
        resData = exTemplate.process(context: exContext);
      }
    }

    handler.resolve(Response(
      data: resData,
      requestOptions: options,
      statusCode: statusCode,
    ));
  }

  String? _templateData(Map<String, dynamic> template, Map<dynamic, dynamic> exContext) {
    var content = template['content'];
    if (content == null) {
      return content;
    }

    int? size = template['size'];
    String sContent = json.encode(content);

    var exTemplate = Template(
      syntax: [_exSyntax],
      value: sContent,
    );

    if (size == null) {
      exContext.addAll({
        'index': 0,
      });
      return exTemplate.process(context: exContext);
    }

    String joinString = List.generate(size, (index) {
      exContext.addAll({'index': index});
      return exTemplate.process(context: exContext);
    }).join(",");
    return "[$joinString]";
  }
}
