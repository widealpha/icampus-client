///书籍信息
class Book {
  ///书籍id
  final String bookId;

  ///书籍名称
  final String title;

  ///书籍作者
  final String author;

  ///馆藏总数
  final int collectionCount;

  ///可借数目
  final int freeCount;

  ///出版社
  final String publisher;

  ///出版时间
  final String publishYear;

  ///学科主题
  final String theme;

  ///国际标准书号
  final String isbn;

  ///摘要
  final String digest;

  ///馆藏列表
  final List<BookCollection> collections;

  Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.collectionCount,
    required this.freeCount,
    required this.publisher,
    required this.publishYear,
    required this.theme,
    required this.isbn,
    required this.digest,
    required this.collections,
  });

  Book copyWith({
    String? bookId,
    String? title,
    String? author,
    int? collectionCount,
    int? freeCount,
    String? publisher,
    String? publishYear,
    String? theme,
    String? isbn,
    String? digest,
    List<BookCollection>? collections,
  }) {
    return Book(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      collectionCount: collectionCount ?? this.collectionCount,
      freeCount: freeCount ?? this.freeCount,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      theme: theme ?? this.theme,
      isbn: isbn ?? this.isbn,
      digest: digest ?? this.digest,
      collections: collections ?? this.collections,
    );
  }

  factory Book.fromSearchBook(SearchBook searchBook) {
    return Book(
        bookId: searchBook.bookId,
        title: searchBook.title,
        author: searchBook.author,
        collectionCount: 0,
        freeCount: 0,
        publisher: searchBook.publisher,
        publishYear: searchBook.publishYear,
        theme: '',
        isbn: '',
        digest: '',
        collections: []);
  }

  factory Book.fromJson(Map jsonMap) {
    List list = jsonMap['collectionBooks'] ?? [];
    return Book(
      bookId: jsonMap['bookId'] ?? '',
      title: jsonMap['title'] ?? '',
      author: jsonMap['author'] ?? '',
      publisher: jsonMap['publisher'] ?? '',
      publishYear: jsonMap['publishYear'] ?? '*',
      collectionCount: jsonMap['collectionCount'] ?? 0,
      freeCount: jsonMap['freeCount'] ?? 0,
      theme: jsonMap['theme'] ?? '',
      isbn: jsonMap['isbn'] ?? '',
      digest: jsonMap['digest'] ?? '',
      collections: list.map((e) => BookCollection.fromJson(e)).toList(),
    );
  }
}

/// 馆藏书籍信息
class BookCollection {
  ///索书号
  final String callNo;

  ///条码号
  final String barcode;

  ///出版日期
  final String publishTime;

  ///馆藏地
  final String location;

  ///是否可借
  final String status;

  BookCollection({
    required this.callNo,
    required this.barcode,
    required this.publishTime,
    required this.location,
    required this.status,
  });

  factory BookCollection.fromJson(jsonMap) {
    return BookCollection(
      callNo: jsonMap['callNo'] ?? '',
      barcode: jsonMap['barcode'] ?? '',
      publishTime: jsonMap['publishTime'] ?? '',
      location: jsonMap['location'] ?? '',
      status: jsonMap['status'] ?? '不可借阅',
    );
  }
}

///搜索结果图书
class SearchBook {
  ///书籍id
  final String bookId;

  ///书籍名称
  final String title;

  ///书籍作者
  final String author;

  ///出版社
  final String publisher;

  ///出版年份
  final String publishYear;

  SearchBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.publisher,
    required this.publishYear,
  });

  factory SearchBook.fromJson(Map<String, dynamic> json) {
    return SearchBook(
      bookId: json["bookId"] ?? '',
      title: json["title"] ?? '',
      author: json["author"] ?? '',
      publisher: json["publisher"] ?? '',
      publishYear: json["publishYear"] ?? '',
    );
  }

  factory SearchBook.fromBook(Book book) {
    return SearchBook(
        author: book.author,
        bookId: book.bookId,
        title: book.title,
        publishYear: book.publishYear,
        publisher: book.publisher);
  }
}