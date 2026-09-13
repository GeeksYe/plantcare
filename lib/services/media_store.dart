import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 媒体持久化：把拍照/相册/视频得到的临时文件复制到应用私有目录，
/// 避免被系统清理后内容丢失（当前阶段不上传服务器）
class MediaStore {
  MediaStore._();

  /// 返回持久化后的文件绝对路径
  static Future<String> save(String sourcePath, {String kind = 'image'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final lower = sourcePath.toLowerCase();
    var ext = kind == 'video' ? '.mp4' : '.jpg';
    for (final e in ['.jpg', '.jpeg', '.png', '.webp', '.mp4', '.mov', '.m4v']) {
      if (lower.endsWith(e)) {
        ext = e == '.mov' ? '.mov' : e;
        break;
      }
    }
    final target =
        '${dir.path}/post_${kind}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(sourcePath).copy(target);
    return target;
  }
}
