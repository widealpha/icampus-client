import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../utils/path_utils.dart';
import '../../utils/platform_utils.dart';
import 'toast.dart';

final _urlRegExp = RegExp(r'^(http|https|ftp)://');
final _base64RegExp = RegExp(r'^data:image/\w+;base64,');

enum ImageProviderType {
  ///网络图片
  network,

  ///本地文件图片
  localFile,

  ///asset内文件图片
  ///提交相对于asset路径,例如assets/qr_code.jpg
  asset,

  ///内存图片
  memory
}

class ImageView extends StatefulWidget {
  ImageView(this.imageSources,
      {super.key,
      this.initialIndex = 0,
      this.imageProviderType = ImageProviderType.network,
      this.headers})
      : assert(imageSources.isNotEmpty, 'imageSources can not be empty');

  ///所有的图片链接
  final List<dynamic> imageSources;

  ///网络图片的header
  final Map<String, String>? headers;

  ///起始展示的图片的索引
  final int initialIndex;

  ///图片的来源类型
  final ImageProviderType imageProviderType;

  ///自动判断传入的url类型选取合适的构造函数
  factory ImageView.auto(dynamic data, {initialIndex = 0}) {
    if (data is List<String>) {
      return ImageView(data, initialIndex: initialIndex);
    } else if (data is String) {
      if (_urlRegExp.hasMatch(data)) {
        return ImageView.network(
          data,
        );
      } else if (_base64RegExp.hasMatch(data)) {
        return ImageView.memory(base64.decode(data.split(';base64,')[1]));
      } else if (data.startsWith('assets/')) {
        return ImageView.asset(
          data,
        );
      } else {
        return ImageView.file(
          data,
        );
      }
    } else {
      throw UnsupportedError('不支持的data类型');
    }
  }

  factory ImageView.uri(Uri uri, {Map<String, String>? headers}) {
    if (uri.scheme == 'file') {
      return ImageView.file(
        uri.toFilePath(windows: Platform.isWindows),
      );
    } else if (uri.scheme.startsWith('http')) {
      return ImageView.network(
        uri.path,
      );
    } else if (uri.scheme == 'data') {
      UriData uriData = UriData.fromUri(uri);
      return ImageView.memory(
        uriData.contentAsBytes(),
      );
    } else {
      //不支持的scheme尝试
      return ImageView.file(
        Uri.decodeFull(uri.toString()),
      );
    }
  }

  ///单张网络图片构造函数
  ImageView.network(String url, {Key? key, Map<String, String>? headers})
      : this(
          [url],
          key: key,
          headers: headers,
        );

  ///单张文件图片构造函数
  ImageView.file(String path, {Key? key})
      : this(
          [path],
          key: key,
          imageProviderType: ImageProviderType.localFile,
        );

  ///单张资源图片构造函数
  ImageView.asset(String assetPath, {Key? key})
      : this(
          [assetPath],
          key: key,
          imageProviderType: ImageProviderType.asset,
        );

  ///单张资源图片构造函数
  ImageView.memory(Uint8List data, {Key? key})
      : this(
          [data],
          key: key,
          imageProviderType: ImageProviderType.memory,
        );

  @override
  State<StatefulWidget> createState() {
    return ImageViewState();
  }
}

class ImageViewState extends State<ImageView> with TickerProviderStateMixin {
  final List<ImageProvider> _imageProviders = [];
  late final _opacityAnimation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..animateTo(1);

  late final _scaleAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _curIndex = widget.initialIndex;

  VoidCallback? _scaleAnimationListener;

  int _downPoints = 0;
  bool _enableSwiper = true;

  bool get supportQrScan => PlatformUtils.isMobile;

  @override
  void initState() {
    super.initState();
    _initImageProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Listener(
              onPointerDown: (details) {
                _downPoints++;
                if (_downPoints > 1) {
                  setState(() {
                    _enableSwiper = false;
                  });
                }
              },
              onPointerUp: (detail) {
                setState(() {
                  _downPoints = 0;
                  _enableSwiper = true;
                });
              },
              onPointerCancel: (_) {
                setState(() {
                  _downPoints = 0;
                  _enableSwiper = true;
                });
              },
              child: MouseRegion(
                  onHover: (_) {
                    _showPreNextButton();
                  },
                  child: _buildImagePageView()),
            ),
          ),
          ..._buildFunctionalButton()
        ],
      ),
    );
  }

  @override
  void dispose() {
    _imageProviders.clear();
    _opacityAnimation.dispose();
    _scaleAnimation.dispose();
    clearGestureDetailsCache();
    super.dispose();
  }

  void _initImageProviders() {
    switch (widget.imageProviderType) {
      case ImageProviderType.network:
        for (var url in widget.imageSources) {
          _imageProviders.add(ExtendedNetworkImageProvider(url,
              cache: true, headers: widget.headers));
        }
        break;
      case ImageProviderType.localFile:
        for (var path in widget.imageSources) {
          _imageProviders.add(ExtendedFileImageProvider(File(path)));
        }
        break;
      case ImageProviderType.asset:
        for (var assetName in widget.imageSources) {
          _imageProviders.add(ExtendedAssetImageProvider(assetName));
        }
        break;
      case ImageProviderType.memory:
        for (var bytes in widget.imageSources) {
          _imageProviders.add(ExtendedMemoryImageProvider(bytes));
        }
        break;
    }
  }

  Widget _buildImagePageView() {
    Widget child = PageView.builder(
      controller: _pageController,
      itemCount: _imageProviders.length,
      physics: _enableSwiper ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return Container(
            color: Colors.black, child: _buildImageWidget(context, index));
      },
      onPageChanged: (index) {
        _curIndex = index;
        _showPreNextButton();
        clearGestureDetailsCache();
      },
    );
    return child;
  }

  List<Widget> _buildFunctionalButton() {
    ButtonStyle style = IconButton.styleFrom(
        backgroundColor: Colors.black12, foregroundColor: Colors.white);
    List<Widget> functionalButton = [];
    if (PlatformUtils.isDesktop) {
      functionalButton.add(AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (BuildContext context, Widget? child) {
          return Opacity(opacity: 1 - _opacityAnimation.value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Row(
            children: [
              IconButton(
                  style: style,
                  onPressed: () {
                    if (_curIndex == 0) {
                      Toast.show('没有上一张了');
                    } else {
                      _pageController.animateToPage(_curIndex - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear);
                    }
                  },
                  icon: const Icon(Icons.keyboard_arrow_left_rounded)),
              const Spacer(),
              IconButton(
                  style: style,
                  onPressed: () {
                    if (_curIndex == _imageProviders.length - 1) {
                      Toast.show('没有下一张了');
                    } else {
                      _pageController.animateToPage(_curIndex + 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear);
                    }
                  },
                  icon: const Icon(Icons.keyboard_arrow_right_rounded))
            ],
          ),
        ),
      ));
    }
    functionalButton.add(SafeArea(
      child: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            BackButton(style: style),
            const Spacer(),
            MenuAnchor(
              menuChildren: [
                if (supportQrScan)
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.qr_code_2_rounded),
                    child: const Text('扫描二维码'),
                    onPressed: () async {
                      var res = await _scan(_curIndex, onFailure: () {
                        Toast.show('识别失败');
                      });
                      if (res.isEmpty) {
                        Toast.show('未识别到二维码');
                      } else {
                        Uri uri = Uri.parse(res.first.rawValue!);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.save_alt_rounded),
                  child: const Text('保存图片'),
                  onPressed: () {
                    _save(_curIndex);
                  },
                ),
              ],
              builder: (context, controller, child) {
                return IconButton(
                    style: style,
                    tooltip: '更多',
                    onPressed: () {
                      controller.open();
                    },
                    icon: const Icon(Icons.more_horiz_rounded));
              },
            ),
          ],
        ),
      ),
    ));

    return functionalButton;
  }

  void _showPreNextButton() {
    if (_opacityAnimation.value < 0.1) {
      return;
    }
    _opacityAnimation.value = 0;
    _opacityAnimation.animateTo(1);
  }

  Widget _buildImageWidget(BuildContext context, int index) {
    return ExtendedImage(
      image: _imageProviders[index],
      mode: ExtendedImageMode.gesture,
      handleLoadingProgress: true,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(4),
              child: CircularProgressIndicator(
                  value: state.loadingProgress?.expectedTotalBytes == null
                      ? null
                      : state.loadingProgress!.cumulativeBytesLoaded /
                          state.loadingProgress!.expectedTotalBytes!),
            );
          case LoadState.completed:
            return null;
          case LoadState.failed:
            return GestureDetector(
              onTap: () {
                state.reLoadImage();
              },
              child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.broken_image_rounded, size: 24)),
            );
        }
      },
      onDoubleTap: (state) {
        var pointerDownPosition = state.pointerDownPosition;
        double begin = state.gestureDetails?.totalScale ?? 1;
        double end;
        if (begin != 1) {
          end = 1;
        } else {
          end = 4;
        }

        if (_scaleAnimationListener != null) {
          _scaleAnimation.removeListener(_scaleAnimationListener!);
        }
        _scaleAnimation.stop();

        //reset to use
        _scaleAnimation.reset();

        _scaleAnimationListener = () {
          state.handleDoubleTap(
              scale: begin + (end - begin) * _scaleAnimation.value,
              doubleTapPosition: pointerDownPosition);
        };

        _scaleAnimation.addListener(_scaleAnimationListener!);

        _scaleAnimation.forward();
      },
      initGestureConfigHandler: (state) {
        return GestureConfig(
            minScale: 0.5,
            maxScale: 5,
            cacheGesture: true,
            inPageView: true,
            reverseMousePointerScrollDirection: true);
      },
    );
  }

  Future<void> _save(int index) async {
    String suggestedName = '${DateTime.now().millisecondsSinceEpoch}.png';
    String? path;
    if (PlatformUtils.isDesktop) {
      final FileSaveLocation? location =
          await getSaveLocation(suggestedName: suggestedName);
      path = location?.path;
      if (path == null) {
        return;
      }
    }
    Uint8List bytes = await _loadImageBytes(index);
    if (bytes.isNotEmpty) {
      if (PlatformUtils.isDesktop) {
        final XFile file = XFile.fromData(bytes, name: suggestedName);
        await file.saveTo(path!);
        Toast.show("图片保存成功");
      } else if (PlatformUtils.isMobile) {
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          await Gal.requestAccess(toAlbum: true);
        }
        try {
          await Gal.putImageBytes(bytes);
          Toast.show('图片保存成功 ${hasAccess ? '' : '没有写入权限 ≠ 不能存'}');
        } on GalException catch (e) {
          if (e.type == GalExceptionType.accessDenied) {
            Toast.show('获取相册写入权限失败');
          }
        }
      }
    } else {
      Toast.show("图片保存失败");
    }
  }

  Future<List<Barcode>> _scan(int index, {VoidCallback? onFailure}) async {
    if (!supportQrScan) {
      return [];
    }
    String cacheFilePath = p.join(await PathUtils.cachePath(),
        '${DateTime.now().millisecondsSinceEpoch}.png');
    var bytes = await _loadImageBytes(index);
    XFile file = XFile.fromData(bytes);
    await file.saveTo(cacheFilePath);
    var scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    var inputImage = InputImage.fromFilePath(cacheFilePath);
    try {
      var result = await scanner.processImage(inputImage);
      return result;
    } catch (e) {
      onFailure?.call();
    } finally {
      scanner.close();
    }
    return [];
  }

  Future<Uint8List> _loadImageBytes(int index) async {
    Completer<Uint8List> completer = Completer();
    ImageProvider provider = _imageProviders[index];
    provider
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, synchronousCall) async {
      var image = info.image;
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData != null) {
        completer.complete(byteData.buffer.asUint8List());
      }
    }));
    return completer.future;
  }
}
