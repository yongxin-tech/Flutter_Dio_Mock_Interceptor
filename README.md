# Flutter Dio Mock Interceptor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/yongxin-tech/Flutter_Dio_Mock_Interceptor/blob/63d859aba8b999b9e62431c5675a8bfa312667ae/LICENSE)


This widget help you to mock backend responses in flutter project.


# Environment

The widget was only tested on following environment,
* Flutter: Flutter 3.7.5 (with sound null safety)
* Dio: Dio 5.0.0

# Usage

* Install: 
  ```yaml
  dependencies:
	dio_mock_interceptor: ^1.0.0
  ```

* Create a <code>mock</code> folder in your project, add json files to mock http responses, 
  example: <project>/mock/common.json
  
  ```json
  [
	{
      "path": "/api/login",
      "method": "POST",
      "statusCode": 200,
      "data": {
        "success": true,
        "code": "0000",
		"result": {
			"test": "test"
		}
	  }
	},
	{
      "path": "/api/logout",
      "method": "POST",
      "statusCode": 200,
      "data": {}
	}
  ]
  ```
  
* Setup <code>mock</code> folder to <code>assets</code> section of <code>pubspec.yaml</code>: 
  ```yaml
    assets:
      - mock/
  ```

* Add interceptor to Dio:
  ```flutter
  import 'package:dio_mock_interceptor/dio_mock_interceptor.dart';
  
  dio.interceptors.add(MockInterceptor());
  ```

* Dio post example:
  ```flutter
  Response response = await dio.post("/api/login");
  String json = response.data;
  if (json.isEmpty) {
    throw Exception('response is empty');
  }
  Map<String, dynamic> data = jsonDecode(json);
  bool isSuccess = data['success'] as bool; // true
  Map<String, dynamic> result = data['result']; // result['test'] = 'test'
  ```


# License

Copyright (c) 2023-present [Yong-Xin Technology Ltd.](https://yong-xin.tech/)

This project is licensed under the MIT License - see the [LICENSE](https://github.com/yongxin-tech/Flutter_Dio_Mock_Interceptor/blob/63d859aba8b999b9e62431c5675a8bfa312667ae/LICENSE) file for details.


