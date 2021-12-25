import '../../models/lomo/lomo.dart';
import '../../models/posts/news.dart';
import '../../models/resp/ooxx.dart';
import '../../models/wuliao/hot.dart';
import '../../models/wuliao/tucao.dart';
import '../../models/wuliao/wuliao.dart';
import '../utils/log.dart';
import 'http.dart';

class JandanApi {
  static Future<Wuliao> wuliao({int page = 0}) async {
    final resp = await XHttp.get(
        "/", {"oxwlxojflwblxbsapi": "jandan.get_pic_comments", "page": page});
    Log.log.fine(resp);
    return Wuliao.fromMap(resp);
  }

  static Future<News> news({int page = 0}) async {
    final resp = await XHttp.get("/", {
      "oxwlxojflwblxbsapi": "get_recent_posts",
      "include":
          "url,date,tags,author,title,excerpt,comment_count,comment_status,custom_fields",
      "custom_fields": "thumb_c,views",
      "page": page
    });
    Log.log.fine(resp);
    return News.fromMap(resp);
  }

  static Future<Hot> hot() async {
    final resp =
        await XHttp.get("http://api.moyu.today/jandan/hot?category=recent");
    Log.log.fine(resp);
    return Hot.fromMap(resp);
  }

  /**
   * startid 上一页最后一个条目的id
   */
  static Future<Lomo> lomo({String? startid}) async {
    String param = "";
    if (startid != null) param = "?start_id=" + startid;
    final resp = await XHttp.get(
        "https://api.jandan.net/api/v1/comment/list/21183" + param);
    Log.log.fine(resp);
    return Lomo.fromMap(resp);
  }

  static Future<OOXXResp> ooxxComment(bool positive, String commentId) async {
    final resp =
        await XHttp.post("https://api.jandan.net/api/v1/vote/comment", {
      "vote_type": positive ? "pos" : "neg",
      "comment_id": commentId,
    });
    Log.log.fine(resp);
    return OOXXResp.fromMap(resp);
  }

  static Future<OOXXResp> ooxxTucao(bool positive, String commentId) async {
    final resp = await XHttp.post("https://api.jandan.net/api/v1/vote/tucao", {
      "vote_type": positive ? "pos" : "neg",
      "comment_id": commentId,
    });
    Log.log.fine(resp);
    return OOXXResp.fromMap(resp);
  }

  static Future<TuCao> getTucao(String commentId) async {
    final resp =
        await XHttp.get("https://api.jandan.net/api/v1/tucao/list/$commentId");
    Log.log.fine(resp);
    return TuCao.fromMap(resp);
  }
}
