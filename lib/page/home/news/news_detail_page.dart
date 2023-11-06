import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/http/jandan_api.dart';
import '../../../generated/l10n.dart';
import '../../../init/locator.dart';
import '../../../init/themes.dart';
import '../../../models/posts/news.dart';
import '../../../models/posts/post.dart';
import '../../../utils/snackbar.dart';
import '../../image_viewer/image_viewer_page.dart';
import 'news_tucao_page.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({Key? key, required this.post}) : super(key: key);
  static const routeName = "/news_detail";
  static const paramPost = "post";
  final Post post;

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  PostContent? postContent;

  @override
  void initState() {
    () async {
      try {
        postContent = await JandanApi.postContent(widget.post.id);
        setState(() {});
      } catch (e) {
        SnackBarUtil.showSnackbar(context, Text(locator<S>().network_error));
      }
    }.call();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(locator<S>().news),
      ),
      body: buildBody(context),
      bottomNavigationBar: Container(
        color: Theme.of(context).bottomAppBarColor,
        child: Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back)),
            const Spacer(),
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (builder) {
                      return NewsTucaoPage(post: widget.post);
                    }),
                  );
                },
                icon: const Icon(Icons.comment)),
            IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return ListView(
                        children: [
                          ListTile(
                            onTap: () {
                              Share.share(
                                  "https://jandan.net/p/${widget.post.id}");
                              Navigator.of(context).pop();
                            },
                            title: Text(locator<S>().share),
                          ),
                          ListTile(
                            onTap: () {
                              //TODO: 收藏夹
                              SnackBarUtil.showSnackbar(
                                  context, const Text("暂不支持收藏夹"));
                              Navigator.of(context).pop();
                            },
                            title: Text(locator<S>().add_to_fav),
                          ),
                          ListTile(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text:
                                      "${widget.post.title} https://jandan.net/p/${widget.post.id}",
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                            title: Text(locator<S>().copy_addr),
                          )
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.more_horiz_sharp))
          ],
        ),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return ListView(
      children: [
        ExtendedImage.network(
          widget.post.custom_fields.thumb_c[0],
          height: 200,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Styles.wigetHorizontalMargin, 10,
              Styles.wigetHorizontalMargin, 0),
          child: Text(
            widget.post.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: Styles.fontSizeBig),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Styles.wigetHorizontalMargin, 10,
              Styles.wigetHorizontalMargin, 0),
          child: Text(
            widget.post.author.name +
                " " +
                timeago.format(
                  DateTime.parse(widget.post.date),
                  locale: Localizations.localeOf(context).languageCode,
                ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: Styles.fontSizeSmall,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Styles.wigetHorizontalMargin, 10,
              Styles.wigetHorizontalMargin, 0),
          child: Text(
            widget.post.excerpt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: Styles.fontSizeMiddle),
          ),
        ),
        if (postContent != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Styles.wigetHorizontalMargin, 10,
                Styles.wigetHorizontalMargin, 0),
            child: Html(
              data: postContent?.post.content,
              onLinkTap: (url, attributes, element) {
                if (url != null) {
                  launchUrl(Uri.parse(url));
                }
              },
              extensions: [
                OnImageTapExtension(
                  onImageTap: (url, attributes, element) {
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (c, a1, a2) => ImageViewerPage(
                        images: [url!],
                        currentIndex: 0,
                      ),
                      transitionsBuilder: (c, anim, a2, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ));
                  },
                )
              ],
            ),
          ),
      ],
    );
  }
}
