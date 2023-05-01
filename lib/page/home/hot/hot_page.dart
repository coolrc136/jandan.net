import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/http/jandan_api.dart';
import '../../../models/card_item.dart';
import '../../../utils/provider.dart';
import '../../../widgets/card/wuliao_card.dart';
import '../pics/tucao_page.dart';

class HotPage extends StatefulWidget {
  const HotPage({
    Key? key,
    required this.scrollController,
  }) : super(key: key);
  // final RefreshController refreshController;
  final ScrollController scrollController;

  @override
  State<HotPage> createState() => _HotPageState();
}

class _HotPageState extends State<HotPage> with AutomaticKeepAliveClientMixin {
  final PagingController<int, CardItem> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int _page) async {
    try {
      final hots = await JandanApi.hot();
      var itemList =
          hots.comments.map<CardItem>((e) => e.toCardItem()).toList();
      if (Store.value<AppSetting>(context).hideUnwelcome) {
        itemList.removeWhere((element) =>
            element.vote_negative >= 5 &&
            element.vote_negative >= element.vote_positive);
      }
      _pagingController.appendLastPage(itemList);
    } catch (e) {
      _pagingController.error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => Future.sync(
        () => _pagingController.refresh(),
      ),
      child: PagedListView(
        cacheExtent: MediaQuery.of(context).size.height,
        scrollController: widget.scrollController,
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<CardItem>(
          itemBuilder: (context, item, index) => InkWell(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (builder) {
                  return TucaoPage(item: item);
                }),
              );
            },
            child: WuliaoCard(
              item: item,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
