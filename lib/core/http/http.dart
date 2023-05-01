import 'package:dio/dio.dart';

import '../../generated/l10n.dart';
import '../../init/locator.dart';
import '../utils/log.dart';

class XHttp {
  XHttp._internal();

  ///网络请求配置
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://i.jandan.net",
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        "User-Agent": "Jandan Android App V5.2.0.0",
      },
    ),
  );

  ///初始化dio
  static void init() {
    //添加拦截器
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (RequestOptions options, handler) {
      Log.http.fine("Request: ${options.uri} ?? ${options.data}");
      return handler.next(options);
    }, onResponse: (Response response, handler) {
      if (response.requestOptions.responseType == ResponseType.json) {
        Log.http.info("Response: ${response.statusCode} ${response.data}");
      } else {
        Log.http.fine("Response: ${response.statusCode}");
      }
      return handler.next(response);
    }, onError: (DioError e, handler) {
      handleError(e);
      return handler.next(e);
    }));
  }

  ///error统一处理
  static void handleError(DioError e) {
    switch (e.type) {
      case DioErrorType.connectionTimeout:
        Log.http.severe("连接超时");
        throw NetWorkException(locator<S>().connect_timeout,
            request: e.requestOptions.toString());
      case DioErrorType.sendTimeout:
        Log.http.severe("请求超时");
        throw NetWorkException(locator<S>().send_timeout,
            request: e.requestOptions.toString());
      case DioErrorType.receiveTimeout:
        Log.http.severe("响应超时");
        throw NetWorkException(locator<S>().receive_timeout,
            request: e.requestOptions.toString());
      case DioErrorType.badResponse:
        Log.http.severe("出现异常");
        throw NetWorkException(locator<S>().response,
            request: e.requestOptions.toString(),
            response: e.response.toString());
      case DioErrorType.cancel:
        Log.http.severe("请求取消");
        throw NetWorkException(locator<S>().request_cancle,
            request: e.requestOptions.toString());
      default:
        Log.http.severe("未知错误");
        Log.http.severe(e.type);
        Log.http.severe(e.requestOptions.uri);
        throw NetWorkException(locator<S>().unknow_error,
            request: e.requestOptions.toString(),
            response: e.response.toString());
    }
  }

  ///get请求
  static Future get(String url, [Map<String, dynamic>? params]) async {
    try {
      Response response;
      if (params != null) {
        response = await dio.get(url, queryParameters: params);
      } else {
        response = await dio.get(url);
      }
      return response.data;
    } on DioError catch (e) {
      handleError(e);
    }
  }

  ///post 表单请求
  static Future post(String url, Map<String, dynamic> params) async {
    try {
      Response response = await dio.post(url, data: FormData.fromMap(params));
      return response.data;
    } on DioError catch (e) {
      handleError(e);
    }
  }

  ///post body请求
  static Future postJson(String url, dynamic data) async {
    try {
      Response response = await dio.post(url, data: data);
      return response.data;
    } on DioError catch (e) {
      handleError(e);
    }
  }

  ///下载文件
  static Future downloadFile(urlPath, savePath) async {
    Response response;
    try {
      response = await dio.download(urlPath, savePath,
          onReceiveProgress: (int count, int total) {
        //进度
        Log.http.info("$count $total");
      });
      return response.data;
    } on DioError catch (e) {
      handleError(e);
    }
  }
}

class NetWorkException implements Exception {
  final String message;
  final String request;
  final String response;

  NetWorkException(this.message, {this.request = "", this.response = ""});

  @override
  String toString() {
    return message;
  }
}
