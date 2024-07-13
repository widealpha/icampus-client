import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

import '../../../bean/book.dart';
import '../../widgets/toast.dart';

///书籍详情
class BookInfoPage extends StatefulWidget {
  final Book book;

  const BookInfoPage(this.book, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _BookInfoState();
  }
}

class _BookInfoState extends State<BookInfoPage> {
  late Book _book = widget.book;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _initBookInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text('书籍详情'),
      ),
      body: ListView(
        children: [
          BookItemCard(_book),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpansionTile(
                title: const Text("馆藏信息"),
                children: [
                  if (_book.collections.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      child: Text(
                        _initialLoading ? '馆藏信息加载中...' : '暂无馆藏信息',
                        style: TextStyle(color: Get.theme.disabledColor),
                      ),
                    ),
                  ..._book.collections.map((collection) =>
                      BookCollectionCard(bookCollection: collection))
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  void _initBookInfo() {
  }
}

class BookItemCard extends StatelessWidget {
  final Book book;

  const BookItemCard(this.book, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "《${book.title}》",
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16),
                )),
            _contentWidget('作者', book.author),
            _contentWidget('出版信息', '${book.publisher}·${book.publishYear}出版'),
            _contentWidget('主题信息', book.theme),
            _contentWidget('ISBN编码', book.isbn),
            _contentWidget('摘要信息', book.digest),
          ],
        ),
      ),
    );
  }

  Widget _contentWidget(String title, String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          "$title: $content",
          style: TextStyle(color: Get.theme.disabledColor, fontSize: 12),
        ),
      );
    }
  }
}

/// 馆藏信息
class BookCollectionCard extends StatelessWidget {
  final BookCollection bookCollection;

  const BookCollectionCard({super.key, required this.bookCollection});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Flex(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            direction: Axis.horizontal,
            children: [
              Expanded(child: title('索书号')),
              Expanded(child: title('条码号'))
            ],
          ),
          Flex(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            direction: Axis.horizontal,
            children: [
              Expanded(child: content(bookCollection.callNo)),
              Expanded(child: content(bookCollection.barcode))
            ],
          ),
          const Divider(),
          Flex(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            direction: Axis.horizontal,
            children: [
              Expanded(child: title('馆藏地')),
              Expanded(child: title('状态'))
            ],
          ),
          Flex(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            direction: Axis.horizontal,
            children: [
              Expanded(child: content(bookCollection.location)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                        onPressed: () {},
                        label: Text(
                          bookCollection.status.replaceFirst('：', '\n'),
                          textAlign: TextAlign.center,
                        ),
                        icon: const Icon(Icons.location_on_rounded)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget title(String title) {
    return Container(
      alignment: Alignment.center,
      child: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  Widget content(String content, {bool selectable = true}) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: selectable
          ? SelectableText(content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface,
              ))
          : Text(content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface,
              )),
    );
  }
}
