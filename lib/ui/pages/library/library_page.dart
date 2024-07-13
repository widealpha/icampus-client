// 图书馆功能

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../../api/library_api.dart';
import '../../../bean/book.dart';
import 'book_info_page.dart';

///图书搜索类型
enum BookSearchType {
  all('任意词'),
  bookName('书名'),
  author('责任者'),
  publisher('出版社'),
  isbn('ISBN'),
  callNo('索书号');

  final String value;

  const BookSearchType(this.value);
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LibraryState();
  }
}

class _LibraryState extends State<LibraryPage> with TickerProviderStateMixin {
  final List<String> _tabBarText = ['馆藏查询'];
  late final TabController _controller =
      TabController(length: _tabBarText.length, vsync: this);
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }


  Widget _buildBody() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverAppBar(
              title: const Text('图书室'),
              // scrollController: ScrollController(),
              bottom: TabBar(
                controller: _controller,
                tabs: _tabBarText.map((name) => Tab(text: name)).toList(),
              ),
            ),
          ),
        ];
      },
      body: _getTabBarView(),
    );
  }

  Widget _getTabBarView() {
    return TabBarView(
      controller: _controller,
      children: const [
        SearchBookWidget(),
        // AppointLibraryWidget(),
        // AppointSeatWidget(),
      ],
    );
  }
}

///搜索书籍
class SearchBookWidget extends StatefulWidget {
  const SearchBookWidget({Key? key}) : super(key: key);

  @override
  State<SearchBookWidget> createState() => _SearchBookWidgetState();
}

class _SearchBookWidgetState extends State<SearchBookWidget>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController = RefreshController();
  String _searchKey = '';
  List<Book> _searchResultBooks = [];
  final TextEditingController _searchEditController = TextEditingController();
  final List<String> _libraries = [
    '中心校区图书馆',
    '蒋震图书馆',
    '洪家楼校区图书馆',
    '趵突泉校区图书馆',
    '千佛山校区图书馆',
    '兴隆山校区图书馆',
    '软件园校区图书馆',
    '青岛校区图书馆',
    '威海校区图书馆',
  ];
  final Map<String, bool> _searchLibraries = {
    '中心校区图书馆': true,
    '蒋震图书馆': true,
    '洪家楼校区图书馆': true,
    '趵突泉校区图书馆': true,
    '软件园校区图书馆': true,
    '兴隆山校区图书馆': true,
    '千佛山校区图书馆': true,
    '青岛校区图书馆': true,
    '威海校区图书馆': true,
  };
  BookSearchType _searchType = BookSearchType.all;

  final FocusNode _editFocusNode = FocusNode();
  bool _isSearching = false;
  int _searchPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SmartRefresher(
        footer: const ClassicFooter(),
        controller: _refreshController,
        enablePullUp: _searchKey.isNotEmpty && _searchResultBooks.isNotEmpty,
        enablePullDown: false,
        child: CustomScrollView(
          primary: false,
          controller: _scrollController,
          slivers: <Widget>[
            SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            SliverToBoxAdapter(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: const EdgeInsets.all(12),
                child: TextField(
                  focusNode: _editFocusNode,
                  controller: _searchEditController,
                  decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      prefixIcon: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Card(
                              color: Get.theme.colorScheme.primary,
                              child: Icon(
                                Icons.manage_search_rounded,
                                color: Get.theme.colorScheme.onPrimary,
                              ),
                            )),
                        onTap: () async {
                          _editFocusNode.unfocus();
                          if (await _showSearchChoiceDialog()) {
                            //更换种类重新搜索
                            _searchResultBooks.clear();
                            _searchPage = 1;
                            _doSearch(_searchEditController.text);
                          }
                        },
                      ),
                      hintText: '请输入查询内容',
                      suffixIcon: TextButton.icon(
                        icon: const Icon(
                          Icons.search_rounded,
                        ),
                        label: const Text('搜索 '),
                        onPressed: () => _doSearch(_searchEditController.text),
                      ),
                      border: InputBorder.none,
                      filled: true),
                  onSubmitted: (key) => _doSearch(key),
                ),
              ),
            ),
            SliverList(
                delegate: SliverChildListDelegate.fixed([
              ListTile(
                  title: Text(
                '搜索结果',
                style: TextStyle(color: Get.theme.colorScheme.primary),
              )),
              ..._buildSearchResult()
            ])),
          ],
        ),
        onLoading: () {
          // _loadMore();
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: UniqueKey(),
        child: const Icon(Icons.arrow_upward),
        onPressed: () {
          Scrollable.ensureVisible(context);
          _scrollController.animateTo(0,
              duration: Duration(milliseconds: 200), curve: Curves.linear);
        },
      ),
    );
  }

  List<Widget> _buildSearchResult() {
    if (_isSearching) {
      return [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(child: RefreshProgressIndicator()),
        )
      ];
    } else if (_searchResultBooks.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              '没有搜索结果哦',
              style: TextStyle(color: Get.theme.disabledColor),
            ),
          ),
        )
      ];
    } else {
      return _searchResultBooks.map((book) {
        return Column(
          children: [
            ListTile(
              title: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '作者:${book.author}\n'
                '出版社:${book.publisher} · ${book.publishYear}出版',
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (buildContext) => BookInfoPage(book),
                ));
              },
            ),
            const Divider(),
          ],
        );
      }).toList();
    }
  }

  Future<void> _doSearch(String searchKey) async {
    _editFocusNode.unfocus();
    if (_searchKey != searchKey) {
      _searchResultBooks.clear();
      _searchPage = 1;
    }
    _searchKey = searchKey;
    _refreshController.resetNoData();
    setState(() {
      _isSearching = true;
    });
    List<String> libraries = [];
    _searchLibraries.forEach((lib, value) {
      if (value) {
        libraries.add(lib);
      }
    });
    LibraryAPI().searchBooks(searchKey).then((result) {
      if (result.success) {
        _searchResultBooks = result.data!;
      }
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  // Future<void> _loadMore() async {
  //   if (_searchKey.isNotEmpty) {
  //     _searchPage++;
  //     try {
  //       List<String> libraries = [];
  //       _searchLibraries.forEach((lib, value) {
  //         if (value) {
  //           libraries.add(lib);
  //         }
  //       });
  //       LibraryAPI.searchBooks(_searchKey,
  //               page: _searchPage, type: _searchType, libraries: libraries)
  //           .then((bookList) {
  //         if (mounted) {
  //           if (bookList.isNotEmpty) {
  //             setState(() {
  //               _searchResultBooks.addAll(bookList);
  //             });
  //             _refreshController.loadComplete();
  //           } else {
  //             _refreshController.loadNoData();
  //           }
  //         }
  //       });
  //     } on Error {
  //       _refreshController.loadFailed();
  //     }
  //   }
  // }

  Future<bool> _showSearchChoiceDialog() async {
    BookSearchType tempSearchType = _searchType;
    Map<String, bool> tempSearchLibs = Map.of(_searchLibraries);
    bool? shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: StatefulBuilder(builder: (context, stateSetter) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '搜索类型',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                alignment: WrapAlignment.start,
                children: [
                  ...BookSearchType.values.map((type) => TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () {
                          stateSetter(() {
                            tempSearchType = type;
                          });
                        },
                        icon: IgnorePointer(
                          child: Radio(
                              value: type,
                              groupValue: tempSearchType,
                              onChanged: (_) {}),
                        ),
                        label: Text('${type.value}  '),
                      ))
                ],
              ),
              const Divider(),
              const Text(
                '搜索校区',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                children: [
                  ..._libraries.map(
                    (lib) => TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () {
                          stateSetter(() {
                            tempSearchLibs[lib] = !tempSearchLibs[lib]!;
                          });
                        },
                        icon: AbsorbPointer(
                            child: Checkbox(
                                value: tempSearchLibs[lib], onChanged: (_) {})),
                        label: Text(lib.replaceFirst('校区图书馆', '  '))),
                  )
                ],
              ),
            ],
          );
        }),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消')),
          TextButton(
              onPressed: () {
                _searchType = tempSearchType;
                //当没有选择校区时,默认选择所有校区
                if (tempSearchLibs.values.every((b) => !b)) {
                  tempSearchLibs.forEach((key, _) {
                    tempSearchLibs[key] = true;
                  });
                }
                _searchLibraries.clear();
                _searchLibraries.addAll(tempSearchLibs);
                Navigator.of(context).pop(true);
              },
              child: const Text('确认'))
        ],
      ),
    );
    return shouldRefresh ?? false;
  }

  @override
  bool get wantKeepAlive => true;
}

// class LibraryAppbar extends StatefulWidget {
//   final ScrollController scrollController;
//   final PreferredSizeWidget bottom;
//
//   const LibraryAppbar(
//       {super.key, required this.scrollController, required this.bottom});
//
//   @override
//   LibraryAppbarState createState() => LibraryAppbarState();
// }
//
// class LibraryAppbarState extends State<LibraryAppbar> {
//   /// 获取系统默认的toolbar的高度
//   final double _toolbarHeight = kToolbarHeight;
//
//   /// 获取系统状态栏高度,适配全面屏异形屏
//   final double _statusBarHeight = Get.mediaQuery.padding.top;
//
//   /// 头像最大的大小,对应初始大小
//   final double _maxImageSize = 90;
//
//   /// 头像最小的大小,对应最终大小
//   final double _minImageSize = 36;
//
//   /// appbar能展开的最大高度
//   final double _expandedHeight = 200;
//
//   /// appbar的最小高度(只算空闲部分)
//   final double _minAppbarHeight = 0;
//
//   /// appbar的最大高度(只算空闲部分),这个-1我也不知道哪儿多出来的,但是就是差一个像素
//   final double _maxAppbarHeight = 200 - kTextTabBarHeight - kToolbarHeight - 1;
//
//   /// 头像距离屏幕顶部的最小距离(最终位置)
//   double _minPaddingTop = Get.mediaQuery.padding.top;
//
//   /// 头像距离屏幕顶部的最大距离(初始位置)
//   double _maxPaddingTop = kToolbarHeight + Get.mediaQuery.padding.top;
//
//   /// 头像距离屏幕左侧的最小距离(初始位置)
//   double _minPaddingLeft = Get.width / 2 - 45;
//
//   /// 头像距离屏幕顶部的最大距离(最终位置)
//   double _maxPaddingLeft = Get.width - 72;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     _minPaddingTop = MediaQuery.of(context).padding.top;
//     _maxPaddingTop = kToolbarHeight + _minPaddingTop;
//     _minPaddingLeft = MediaQuery.of(context).size.width / 2 - 45;
//     _maxPaddingLeft = MediaQuery.of(context).size.width - 72;
//     return SliverLayoutBuilder(builder: (context, constraints) {
//       double ratio = (constraints.cacheOrigin + _maxAppbarHeight) /
//           (_maxAppbarHeight - _minAppbarHeight);
//       ratio = Math.max(0, ratio);
//       double size =
//           _maxImageSize - (_maxImageSize - _minImageSize) * (1 - ratio);
//       double paddingTop =
//           _maxPaddingTop - (_maxPaddingTop - _minPaddingTop) * (1 - ratio);
//       double paddingLeft =
//           _minPaddingLeft + (_maxPaddingLeft - _minPaddingLeft) * (1 - ratio);
//       double paddingTopOffset = (1 - ratio) * 12;
//       return SliverAppBar(
//           pinned: true,
//           floating: false,
//           snap: false,
//           primary: true,
//           expandedHeight: _expandedHeight,
//           title: const Text('图书室'),
//           flexibleSpace: Stack(
//             children: [
//               Opacity(
//                 opacity: 0.5,
//                 child: Container(
//                   decoration: BoxDecoration(color: Colors.grey.shade200),
//                   child: const Icon(Icons.account_circle),
//                 ),
//               ),
//               Positioned(
//                 top: paddingTop,
//                 left: paddingLeft,
//                 child: Container(
//                   padding: EdgeInsets.only(top: paddingTopOffset),
//                   child: const Icon(
//                     Icons.account_circle
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           bottom: widget.bottom);
//     });
//   }
// }
