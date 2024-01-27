# Flutter Dio Mock Interceptor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/yongxin-tech/Flutter_Dio_Mock_Interceptor/blob/63d859aba8b999b9e62431c5675a8bfa312667ae/LICENSE)


This widget help you to mock backend responses in flutter project.


# Environment

The widget was only tested on following environment,
* Flutter: 3.7.5+ (with sound null safety)
* Dio: 5.0.0+

# Usage

* Install: 
  ```yaml
  dev_dependencies:
	  dio_mock_interceptor: ^2.0.0+1
  ```

* Create a <code>mock</code> folder in your project, add json files to mock http responses, 
  example: <project>/mock/common.json
  
  ```json
  [
	  {
      "path": "/api/basic/data",
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
      "path": "/api/basic/data/empty",
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
  Response response = await dio.post("/api/basic/data");
  String json = response.data;
  if (json.isEmpty) {
    throw Exception('response is empty');
  }
  Map<String, dynamic> data = jsonDecode(json);
  bool isSuccess = data['success'] as bool; // true
  Map<String, dynamic> result = data['result']; // result['test'] = 'test'
  ```

* Template example:
  ```json
  [
	  {
      "path": "/api/template/without-data-block",
      "method": "POST",
      "statusCode": 200,
      "template": {
        "size": 100000,
        "content": {
          "id": "test${index}",
          "name": "name_${index}"
        }
      }
    },
    {
      "path": "/api/template/with-data-block",
      "method": "POST",
      "statusCode": 200,
      "data": {
        "id": "yong-xin",
        "listA": "${template}"
      },
      "template": {
        "size": 1000,
        "content": {
          "id": "test${index}",
          "name": "name_${index}"
        }
      }
    },
    {
      "path": "/api/template/with-data-block/ex2",
      "method": "POST",
      "statusCode": 200,
      "data": {
        "id": "yong-xin",
        "listA": "${template}",
        "field2": {
          "listB": "${template}"
        }
      },
      "template": {
        "size": 1000,
        "content": {
          "id": "test${index}",
          "name": "name_${index}"
        }
      }
    },
    {
      "path": "/api/templates/ex1",
      "method": "POST",
      "statusCode": 200,
      "data": {
        "id": "yong-xin",
        "listA": "${templates.name1}",
        "field": {
          "listB": "${templates.name2}"
        }
      },
      "templates": {
        "name1": {
          "size": 1000,
          "content": {
            "id": "test${index}",
            "name": "name_${index}"
          }
        },
        "name2": {
          "size": 10,
          "content": {
            "id": "test2${index}",
            "name": "name2_${index}"
          }
        }
      }
    }
  ]
  ```
* Expression example:
  ```json
  [
    {
      "path": "/api/expression/req-data",
      "method": "POST",
      "statusCode": 200,
      "data": {
        "id": "yong-xin",
        "desc": "Hi ${req['data']['name']}, I am ${req['data']['name2'] + '_varSuffix'}",
        "desc2": "test header, ${req['headers']['content-type']}"
      }
    },
    {
      "path": "/api/expression/vars",
      "method": "POST",
      "statusCode": 200,
      "data": {
        "id": "yong-xin",
        "listA": "${templates.name1}",
        "field": {
          "listB": "${templates.name2}"
        },
        "arry": "${groups}",
        "objA": "${obj}"
      },
      "vars": {
        "n": 5,
        "groups": [
          "May",
          "YongXin",
          "John"
        ],
        "obj": {
          "name": "objName"
        }
      },
      "templates": {
        "name1": {
          "size": 1000,
          "content": {
            "id": "test${index}",
            "group": "g_${groups[index%3]}",
            "name": "name_${index}",
            "req-data-name": "test_${req['data']['name']}"
          }
        },
        "name2": {
          "size": 10,
          "content": {
            "id": "test2${index}",
            "name": "name2_${index}"
          }
        }
      }
    },
    {
      "path": "/api/expression/vars/template-ex",
      "method": "POST",
      "statusCode": 200,
      "data": {
        "id": "yong-xin",
        "listA": "${template}"
      },
      "vars": {
        "n": 5,
        "groups": [
          "May",
          "YongXin",
          "John"
        ],
        "obj": {
          "name": "objName"
        }
      },
      "template": {
        "size": 1000,
        "content": {
          "id": "test${index}",
          "group": "g_${groups[index%3]}",
          "name": "name_${index}",
          "req-data-name": "test_${(req['data']['name'].contains('Mercury')? 'a':'b')}"
        }
      }
    }
  ]
  ```

# License

Copyright (c) 2023-present [Yong-Xin Technology Ltd.](https://yong-xin.tech/)

This project is licensed under the MIT License - see the [LICENSE](https://github.com/yongxin-tech/Flutter_Dio_Mock_Interceptor/blob/63d859aba8b999b9e62431c5675a8bfa312667ae/LICENSE) file for details.


