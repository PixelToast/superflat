import 'dart:html';

import 'package:superflat/image_viewer.dart';
import 'package:vector_math/vector_math_64.dart';

class GalleryMeta {
  int width;
  int height;
  String thumb;
  String color;

  GalleryMeta(this.width, this.height, this.thumb, this.color);

  factory GalleryMeta.fromJson(data) =>
    GalleryMeta(
      data["width"],
      data["height"],
      data["thumb"],
      data["color"] ?? "#404040",
    );
}

abstract class GalleryContent {
  GalleryContent(this.meta);
  GalleryMeta meta;

  factory GalleryContent.fromJson(dynamic data) {
    var kind = data["kind"];
    if (kind == "image") {
      return GalleryImage.fromJson(data);
    }

    throw "Unknown gallery kind '$kind'";
  }
}

class GalleryImage extends GalleryContent {
  GalleryImage(this.src, this.mime, GalleryMeta meta) : super(meta);

  String src;
  String mime;

  factory GalleryImage.fromJson(data) =>
    GalleryImage(
      data["src"],
      data["mime"],
      GalleryMeta.fromJson(data),
    );
}

class GalleryScene extends GalleryContent {
  GalleryScene(this.cubemap, this.models, GalleryMeta meta) : super(meta);

  TextureSource cubemap;
  List<GalleryModel> models;
}

class GalleryModel {
  Vector3 pos;
  Vector3 rot;
  String obj;
  List<MaterialSource> mats;
}

enum TextureChannel {
  RGB, R, G, B,
}

class TextureSource {
  String src;
  TextureChannel channel;
  bool sRGB;
  double brightness;
  double gamma;
  double contrast;
}

class MaterialSource {
  TextureSource albeto;
  TextureSource normal;
  TextureSource metallic;
  TextureSource roughness;
  TextureSource occlusion;
}

class Modal {
  Modal(this.parent) {
    parent.onKeyDown.listen((ev) {
      if (ev.keyCode == 27) {
        close();
      }
    });
  }

  Element parent;
  DivElement modal;
  DivElement div;
  bool open = false;
  bool closing = false;

  void close() async {
    if (!open || closing) return;
    modal.style.opacity = "0";
    closing = true;
    await Future.delayed(Duration(milliseconds: 200));
    modal.remove();
    modal = null;
    div = null;
    closing = false;
    open = false;
  }

  Future<void> showContent(GalleryContent content) {
    if (content is GalleryImage) {
      return show(ImageViewer(content));
    }
    throw "Unknown content '${content.runtimeType}'";
  }

  Future<void> show(Viewer viewer) async {
    if (open) return;

    modal = DivElement()
      ..id = "modal"
      ..onClick.listen((_) => close());

    div = DivElement()
      ..id = "modal-content";

    modal.children.add(div);
    parent.children.add(modal);

    open = true;
    await Future.delayed(Duration.zero);
    modal.style.opacity = "1";
    viewer.modal = this;
    await viewer.show();
  }
}

abstract class Viewer {
  Modal modal;
  Future<void> show();
  void close() {}
}