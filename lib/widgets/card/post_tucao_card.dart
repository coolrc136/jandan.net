import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../core/http/jandan_api.dart';
import '../../generated/l10n.dart';
import '../../init/locator.dart';
import '../../init/themes.dart';
import '../../models/posts/post_comments.dart';
import '../layout/comment_navigation_bar.dart';
import '../text/blod_text.dart';

class PostTucaoCard extends StatefulWidget {
  const PostTucaoCard(
      {Key? key,
      required this.idx,
      required this.tucaoList,
      required this.commentController})
      : super(key: key);
  final int idx;
  final List<PostCommentItem> tucaoList;
  final CommentController commentController;

  @override
  _PostTucaoCardState createState() => _PostTucaoCardState();
}

class _PostTucaoCardState extends State<PostTucaoCard> {
  @override
  Widget build(BuildContext context) {
    final tucao = widget.tucaoList[widget.idx];
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text(tucao.name),
              children: [
                ListTile(
                  title: Text(locator<S>().reply),
                  onTap: () {
                    widget.commentController.prefix =
                        "@<a href='#comment-${tucao.id}'>${tucao.name}</a>: ";
                    widget.commentController.hintText =
                        locator<S>().reply + tucao.name;
                    widget.commentController.textEditingController.text = "";
                    widget.commentController.refresh();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text(locator<S>().copy_comment),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: tucao.content));
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
      },
      child: Padding(
        padding: Styles.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SimpleBlodText(tucao.name),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    if (tucao.ooxx != null) return;
                    try {
                      final res = await JandanApi.ooxxComment(
                          true, tucao.id.toString());
                      if (res.code == 0) {
                        setState(() {
                          tucao.ooxx = true;
                          tucao.vote_positive++;
                        });
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(res.msg)));
                        setState(() {
                          tucao.ooxx = null;
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(locator<S>().failed_to_vote)));
                      setState(() {
                        tucao.ooxx = null;
                      });
                    }
                  },
                  child: Text(
                    "oo ${tucao.vote_positive}",
                    style: TextStyle(
                        color: tucao.ooxx == true
                            ? Theme.of(context).primaryColor
                            : null),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () async {
                    if (tucao.ooxx != null) return;
                    try {
                      final res = await JandanApi.ooxxComment(
                          false, tucao.id.toString());
                      if (res.code == 0) {
                        setState(() {
                          tucao.ooxx = false;
                          tucao.vote_negative++;
                        });
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(res.msg)));
                        setState(() {
                          tucao.ooxx = null;
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(locator<S>().failed_to_vote)));
                      setState(() {
                        tucao.ooxx = null;
                      });
                    }
                  },
                  child: Text(
                    "xx ${tucao.vote_negative}",
                    style: TextStyle(
                        color: tucao.ooxx == false
                            ? Theme.of(context).primaryColor
                            : null),
                  ),
                )
              ],
            ),
            Text(
              timeago.format(
                DateTime.parse(tucao.date),
                locale: Localizations.localeOf(context).languageCode,
              ),
            ),
            Html(
              data: tucao.content.trim(),
              onLinkTap: (url, attributes, element) {
                if (url != null) {
                  launchUrl(Uri.parse(url));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
