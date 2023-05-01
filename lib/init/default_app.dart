import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/http/http.dart';
import '../generated/l10n.dart';
import '../utils/provider.dart';
import '../utils/sputils.dart';
import 'locator.dart';
import 'splash.dart';
import 'time_message.dart';

//默认App的启动
class DefaultApp {
  //运行app
  static void run() {
    WidgetsFlutterBinding.ensureInitialized();
    initFirst().then((value) => runApp(Store.init(const MyApp())));
    initApp();
  }

  /// 必须要优先初始化的内容
  static Future<void> initFirst() async {
    Logger.root.level = Level.ALL; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      log(record.message,
          name: record.loggerName,
          level: record.level.value,
          time: record.time,
          zone: record.zone,
          stackTrace: record.stackTrace,
          error: record.error,
          sequenceNumber: record.sequenceNumber);
    });
    await SPUtils.init();
    setupLocator();
  }

  /// 程序初始化操作
  static void initApp() {
    XHttp.init();
    timeago.setLocaleMessages('zh', CNTimeMessage());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSetting>(
      builder: (context, appTheme, _) {
        return MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: ThemeData(
            brightness: appTheme.brightness,
            primarySwatch: appTheme.themeColor,
            primaryColor: appTheme.themeColor,
          ),
          title: 'Jandan',
          home: const SplashPage(),
        );
      },
    );
  }
}
