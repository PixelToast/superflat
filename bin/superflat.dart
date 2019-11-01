import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

Future<Map<String, dynamic>> getConfig() async {
  return jsonDecode(await File("web/images.json").readAsString());
}

Future<void> writeConfig(Map<String, dynamic> conf) {
  return File("web/images.json").writeAsString(JsonEncoder.withIndent("  ").convert(conf));
}

Future<List<int>> getFile(String s) async {
  print("Reading file '$s'");
  var uri = Uri.parse(s);
  if (uri.scheme == "file") {
    return File.fromUri(uri).readAsBytes();
  } else if (uri.scheme == "http" || uri.scheme == "https") {
    return (await (await HttpClient().getUrl(uri)).close()).expand((e) => e).toList();
  } else {
    throw "Unknown scheme '${uri.scheme}'";
  }
}

Future<void> writeFile(String s, List<int> data) async {
  return File("web/$s").writeAsBytes(data);
}

Future<void> mkDir(String s) {
  return Directory("web/$s").create(recursive: true);
}

Future<Tuple2<int, int>> imgSize(String path) async {
  var proc = await Process.start("C:\\Program Files\\ImageMagick-7.0.9-Q16\\magick.exe", [
    "identify", "web/$path"
  ]);

  var buf = await proc.stdout.expand((e) => e).toList();

  var str = Utf8Decoder().convert(buf);
  var match = RegExp(r"(\d+)x(\d+)").firstMatch(str);

  if (match == null) throw "Could not get size: '$str'";
  return Tuple2(int.parse(match.group(1)), int.parse(match.group(2)));
}

Future<List<int>> makeThumbnail(String path) async {
  var proc = await Process.start("C:\\Program Files\\ImageMagick-7.0.9-Q16\\magick.exe", [
    "-define", "jpg:size=800x400", "-background", "#404040", "web/$path", "-thumbnail", "400x200>", "-"
  ]);
  stderr.addStream(proc.stderr);
  return proc.stdout.expand((e) => e).toList();
}

void main(List<String> args) async {
  var kind = args[0];
  if (kind == "image") {
    var config = await getConfig();
    var imgData = await getFile(args[1].replaceAll("\\", "/"));
    var id = md5.convert(imgData).toString();

    config["feed"] ??= [];
    config["pool"] ??= {};
    if (config["pool"][id] != null) throw "Image already exists;";

    var imgExtension = lookupMimeType(args[1], headerBytes: imgData).split("/")[1];

    await mkDir("content/$id");
    await writeFile("content/$id/full.$imgExtension", imgData);

    var thumbailData = await makeThumbnail("content/$id/full.$imgExtension");

    if (thumbailData.isEmpty) throw "Failed to make thumbnail";
    await writeFile("content/$id/thumb.jpg", thumbailData);

    var size = await imgSize("content/$id/full.$imgExtension");

    config["feed"].add(id);

    config["pool"][id] = {
      "width": size.item1,
      "height": size.item2,
      "src": "/content/$id/full.$imgExtension",
      "thumb": "/content/$id/thumb.jpg",
    };

    await writeConfig(config);
  } else {
    throw "Unknown kind '$kind'";
  }
}