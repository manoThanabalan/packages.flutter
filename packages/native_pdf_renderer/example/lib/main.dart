import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:native_pdf_renderer_example/has_support.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  Future<PDFDocument> _getDocument() async {
    if (await hasSupport()) {
      return PDFDocument.openAsset('assets/sample.pdf');
    } else {
      throw Exception(
        'PDF Rendering does not '
        'support on the system of this version',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    final storage = Map<int, PDFPageImage>();

    return MaterialApp(
      title: 'PDF View example',
      color: Colors.white,
      home: Scaffold(
        body: FutureBuilder(
          future: _getDocument(),
          builder: (context, AsyncSnapshot<PDFDocument> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }

            return PageView(
              children: <Widget>[
                ImageLoader(
                  storage: storage,
                  document: snapshot.data,
                  pageNumber: 1,
                ),
                ImageLoader(
                  storage: storage,
                  document: snapshot.data,
                  pageNumber: 2,
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Swipe to right',
                  style: Theme.of(context).textTheme.title,
                ),
                Icon(Icons.keyboard_arrow_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageLoader extends StatelessWidget {
  ImageLoader({
    @required this.storage,
    @required this.document,
    @required this.pageNumber,
    Key key,
  }) : super(key: key);

  final Map<int, PDFPageImage> storage;
  final PDFDocument document;
  final int pageNumber;

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _renderPage(),
        builder: (context, AsyncSnapshot<PDFPageImage> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error'),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Image(
            image: MemoryImage(snapshot.data.bytes),
          );
        },
      );

  Future<PDFPageImage> _renderPage() async {
    if (storage.containsKey(pageNumber)) {
      return storage[pageNumber];
    }
    final page = await document.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PDFPageFormat.PNG,
    );
    await page.close();
    storage[pageNumber] = pageImage;
    return pageImage;
  }
}
