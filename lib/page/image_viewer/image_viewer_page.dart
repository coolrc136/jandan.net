import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/log.dart';
import '../../generated/l10n.dart';
import '../../init/locator.dart';
import '../../utils/snackbar.dart';

typedef DoubleClickAnimationListener = void Function();

class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage(
      {Key? key, required this.images, required this.currentIndex})
      : super(key: key);

  static const routeName = "/image_viewer";
  static const paramImages = "images";
  static const paramIndex = "currentIndex";

  final List<String> images;
  final int currentIndex;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage>
    with TickerProviderStateMixin {
  late int currentIndex;

//https://github.com/fluttercandies/extended_image/blob/02031d799bd7ea175138b5a593aabfc46055c5da/example/lib/common/widget/pic_swiper.dart
  late AnimationController _doubleClickAnimationController;
  Animation<double>? _doubleClickAnimation;
  late DoubleClickAnimationListener _doubleClickAnimationListener;
  List<double> doubleTapScales = <double>[1.0, 2.0];

  @override
  void initState() {
    currentIndex = widget.currentIndex;
    _doubleClickAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Stack(
          children: [
            ExtendedImageGesturePageView.builder(
              itemBuilder: (BuildContext context, int index) {
                var item = widget.images[index];
                return ExtendedImage.network(
                  item,
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.gesture,
                  initGestureConfigHandler: (ExtendedImageState state) {
                    double? initialScale = 1.0;

                    if (state.extendedImageInfo != null) {
                      initialScale = initScale(
                          size: MediaQuery.of(context).size,
                          initialScale: initialScale,
                          imageSize: Size(
                              state.extendedImageInfo!.image.width.toDouble(),
                              state.extendedImageInfo!.image.height
                                  .toDouble()));
                    }
                    return GestureConfig(
                      inPageView: true,
                      initialScale: initialScale!,
                      maxScale: max(initialScale, 5.0),
                      animationMaxScale: max(initialScale, 5.0),
                      initialAlignment: InitialAlignment.center,
                      //you can cache gesture state even though page view page change.
                      //remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
                      cacheGesture: false,
                    );
                  },
                  onDoubleTap: (ExtendedImageGestureState state) {
                    ///you can use define pointerDownPosition as you can,
                    ///default value is double tap pointer down postion.
                    final Offset? pointerDownPosition =
                        state.pointerDownPosition;
                    final double? begin = state.gestureDetails!.totalScale;
                    double end;

                    //remove old
                    _doubleClickAnimation
                        ?.removeListener(_doubleClickAnimationListener);

                    //stop pre
                    _doubleClickAnimationController.stop();

                    //reset to use
                    _doubleClickAnimationController.reset();

                    if (begin == doubleTapScales[0]) {
                      end = doubleTapScales[1];
                    } else {
                      end = doubleTapScales[0];
                    }

                    _doubleClickAnimationListener = () {
                      //print(_animation.value);
                      state.handleDoubleTap(
                          scale: _doubleClickAnimation!.value,
                          doubleTapPosition: pointerDownPosition);
                    };
                    _doubleClickAnimation = _doubleClickAnimationController
                        .drive(Tween<double>(begin: begin, end: end));

                    _doubleClickAnimation!
                        .addListener(_doubleClickAnimationListener);

                    _doubleClickAnimationController.forward();
                  },
                );
              },
              itemCount: widget.images.length,
              onPageChanged: (int index) {
                currentIndex = index;
              },
              controller: ExtendedPageController(
                initialPage: widget.currentIndex,
              ),
              scrollDirection: Axis.horizontal,
            ),
            Positioned(
              bottom: 30,
              right: 30,
              child: Row(
                children: [
                  IconButton(
                    iconSize: 20,
                    onPressed: () async {
                      final imageData = await getNetworkImageData(
                          widget.images[currentIndex]);
                      try {
                        Directory tempDir = await getTemporaryDirectory();
                        final suffix = widget.images[currentIndex].substring(
                            widget.images[currentIndex].length -
                                36); //hash+后缀 32+4
                        Log.log.fine("save image" + suffix);
                        final file = await File(tempDir.path + suffix)
                            .writeAsBytes(imageData!);
                        final permissionStatus =
                            await Permission.storage.request();
                        if (!permissionStatus.isGranted) {
                          throw Exception("no permission");
                        }
                        final result =
                            await ImageGallerySaver.saveFile(file.path);
                        await file.delete();
                        if (result['isSuccess'] != true) {
                          throw Exception("");
                        }
                        SnackBarUtil.showSnackbar(
                            context, Text(locator<S>().save_success));
                        Log.log.fine(result);
                      } catch (e) {
                        SnackBarUtil.showSnackbar(
                            context, Text(locator<S>().failed_to_save));
                      }
                    },
                    icon: Icon(
                      Icons.download,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    //从图片缓存里获取文件，然后存入tmp进行分享
                    iconSize: 20,
                    onPressed: () async {
                      try {
                        final tempDir = await getTemporaryDirectory();
                        final shareDir = Directory(tempDir.path + "/share");
                        shareDir.createSync();
                        final suffix = widget.images[currentIndex].substring(
                            widget.images[currentIndex].length -
                                36); //hash+后缀 32+4
                        final file = File(shareDir.path + "/" + suffix);

                        if (!file.existsSync()) {
                          final imageData = await getNetworkImageData(
                              widget.images[currentIndex]);
                          await file.writeAsBytes(imageData!);
                        }

                        await Share.shareXFiles(
                          [XFile(file.path)],
                        );
                        await file.delete();
                      } catch (e) {
                        SnackBarUtil.showSnackbar(
                            context, Text(locator<S>().failed_to_share));
                      }
                    },
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _doubleClickAnimationController.dispose();
    clearGestureDetailsCache();
    //cancelToken?.cancel();
    super.dispose();
  }
}

double? initScale(
    {required Size imageSize, required Size size, double? initialScale}) {
  final double n1 = imageSize.height / imageSize.width;
  final double n2 = size.height / size.width;
  if (n1 > n2) {
    final FittedSizes fittedSizes =
        applyBoxFit(BoxFit.contain, imageSize, size);
    //final Size sourceSize = fittedSizes.source;
    final Size destinationSize = fittedSizes.destination;
    return size.width / destinationSize.width;
  } else if (n1 / n2 < 1 / 4) {
    final FittedSizes fittedSizes =
        applyBoxFit(BoxFit.contain, imageSize, size);
    //final Size sourceSize = fittedSizes.source;
    final Size destinationSize = fittedSizes.destination;
    return size.height / destinationSize.height;
  }

  return initialScale;
}
