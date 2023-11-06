import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/http/jandan_api.dart';
import '../../generated/l10n.dart';
import '../../init/locator.dart';
import '../../init/themes.dart';
import '../../models/card_item.dart';
import '../../page/image_viewer/image_viewer_page.dart';
import '../../utils/assets.dart';
import '../../utils/snackbar.dart';
import '../text/blod_text.dart';

const double cardMargin = 8;

class WuliaoCard extends StatefulWidget {
  WuliaoCard({Key? key, required this.item}) : super(key: key);
  final CardItem item;
  double? height;

  @override
  State<WuliaoCard> createState() => _WuliaoCardState();
}

class _WuliaoCardState extends State<WuliaoCard> {
  @override
  Widget build(BuildContext context) {
    //过滤不受欢迎的内容
    return Card(
      margin: const EdgeInsets.all(cardMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: SimpleBlodText(widget.item.comment_author)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Text(
              timeago.format(
                DateTime.parse(widget.item.comment_date),
                locale: Localizations.localeOf(context).languageCode,
              ),
              style: const TextStyle(fontSize: Styles.fontSizeSmall),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(10),
              child: Text(cleanText(widget.item.text_content))),
          _images(context),
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
              child: _actionRows(context))
        ],
      ),
    );
  }

  Widget _images(BuildContext context) {
    switch (widget.item.pics.length) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return _image(context, widget.item.pics.first, 0, true);
      default:
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: GridView.builder(
            itemCount: widget.item.pics.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, idx) {
              return _image(context, widget.item.pics[idx], idx, false);
            },
          ),
        );
    }
  }

  Widget _image(
      BuildContext context, String url, int index, bool showMoreText) {
    return InkWell(
      child: Center(
          child: ExtendedImage.network(
        url,
        cache: true,
        cacheMaxAge: const Duration(days: 30),
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return SizedBox(
                height: widget.height ?? 80,
                child: Image.asset(
                  Assets.assetsLoadLoading,
                  color: Theme.of(context).primaryColor,
                ),
              );
            case LoadState.completed:
              final image = state.extendedImageInfo?.image;
              widget.height = image?.height.toDouble();
              if (image?.height != null && image!.height / image.width >= 2) {
                return Stack(
                  children: [
                    ExtendedRawImage(
                      image: image,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      height: MediaQuery.of(context).size.width * 1.5,
                    ),
                    Visibility(
                      visible: showMoreText,
                      child: Positioned(
                        bottom: 0,
                        child: Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width -
                              (cardMargin * 2),
                          color: Colors.white60,
                          child: Text(locator<S>().tap_to_see_full_img),
                        ),
                      ),
                    )
                  ],
                );
              } else {
                return ExtendedRawImage(
                  image: image,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                );
              }
            case LoadState.failed:
              return GestureDetector(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.asset(
                      Assets.assetsLoadFailed,
                    ),
                    Positioned(
                      bottom: 0.0,
                      left: 0.0,
                      right: 0.0,
                      child: Text(
                        locator<S>().load_failed,
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
                onTap: () {
                  state.reLoadImage();
                },
              );
          }
        },
        enableLoadState: true,
      )),
      onTap: () {
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (c, a1, a2) => ImageViewerPage(
            images: [url],
            currentIndex: index,
          ),
          transitionsBuilder: (c, anim, a2, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ));
      },
    );
  }

  Widget _actionRows(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          //oo按钮
          onTap: () async {
            if (widget.item.ooxx != null) return;
            try {
              final res =
                  await JandanApi.ooxxComment(true, widget.item.comment_ID);
              if (res.code == 0) {
                setState(() {
                  widget.item.ooxx =
                      true; // 暂时使用临时数据保存ooxx状态，刷新网页后不出现红色，与网页版一致，后续考虑数据库
                  widget.item.vote_positive++;
                });
              } else {
                SnackBarUtil.showSnackbar(context, Text(res.msg));
                setState(() {
                  widget.item.ooxx = null;
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(locator<S>().failed_to_vote)));
              setState(() {
                widget.item.ooxx = null;
              });
            }
          },
          child: Text(
            "oo ${widget.item.vote_positive}",
            style: TextStyle(
                color: widget.item.ooxx == true
                    ? Theme.of(context).primaryColor
                    : null),
          ),
        ),
        const Spacer(),
        GestureDetector(
          //xx按钮
          onTap: () async {
            if (widget.item.ooxx != null) return;
            try {
              final res =
                  await JandanApi.ooxxComment(false, widget.item.comment_ID);
              if (res.code == 0) {
                setState(() {
                  widget.item.ooxx = false;
                  widget.item.vote_negative++;
                });
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(res.msg)));
                setState(() {
                  widget.item.ooxx = null;
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(locator<S>().failed_to_vote)));
              setState(() {
                widget.item.ooxx = null;
              });
            }
          },
          child: Text(
            "xx ${widget.item.vote_negative}",
            style: TextStyle(
                color: widget.item.ooxx == false
                    ? Theme.of(context).primaryColor
                    : null),
          ),
        ),
        const Spacer(),
        Text("${locator<S>().comments} ${widget.item.sub_comment_count}"),
        const Spacer(flex: 10),
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
                            "https://jandan.net/t/${widget.item.comment_ID}");
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
                                "${cleanText(widget.item.text_content)} https://jandan.net/t/${widget.item.comment_ID}",
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
          icon: const Icon(Icons.more_horiz_rounded),
        )
      ],
    );
  }
}

String cleanText(String text) {
  return text.replaceAll("#img#", "").replaceAll("[查看原图]", "").trim();
}
