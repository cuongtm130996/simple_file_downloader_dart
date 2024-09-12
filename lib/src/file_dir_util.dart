
import 'dart:io';

import 'dio_downloder.dart';



class FileAndDirUtil {
  static Future<String> dealFilePath(FileDownloader config) async {
    if (config.filePath != null && config.filePath!.isNotEmpty) {
      return config.filePath!;
    }

    String saveDir = await dealSaveDir(config);
    config.saveDir = saveDir;


    String name = dealFileName(config);
    config.fileName = name;

    File file = File('$saveDir/$name');

    if (await file.exists()) {
      config.filePath = file.path;
    } else {
      try {
        await file.create(recursive: true);
        config.filePath = file.path;
      } catch (e) {
        print('${e.runtimeType}, ${e.toString()}, ${file.path}');
        rethrow;
      }
    }

    return file.path;
  }

  static Future<String> dealSaveDir(FileDownloader config) async {
    String? saveDir = config.saveDir;
    if (saveDir == null || saveDir.isEmpty) {
      saveDir = FileDownloader.globalSaveDir;
    }
    if (saveDir == null || saveDir.isEmpty) {
      throw Exception('OkhttpDownloadUtil.globalSaveDir is not set!!!!');
    }

    Directory dir = Directory(saveDir);
    if (! dir.existsSync()) {
       await dir.create(recursive: true);
      if (!dir.existsSync()) {
        throw Exception('mkdirs failed: $saveDir');
      }
    } else {
      if (await File(saveDir).exists()) {
        print('warn: saveDir is a File, will try another name: $saveDir');
        dir = Directory('${dir.parent.path}/${dir.path}-dir');
         await dir.create(recursive: true);
        if (!dir.existsSync()) {
          throw Exception('mkdirs failed: ${dir.path}');
        }
      } else {
        List<FileSystemEntity> files = dir.listSync();
        int i = 0;
        while (files.length > 1000) {
          i++;
          dir = Directory('${dir.parent.path}/${dir.path}-$i');
          if (!await dir.exists()) {
            break;
          } else {
            if (!await dir.exists()) {
              await dir.delete();
            }
            files = dir.listSync();
          }
        }
      }
    }
    return dir.path;
  }

  static String dealFileName(FileDownloader config) {
    if(config.fileName !=null && config.fileName !=null){
      return config.fileName!;
    }
    String url = config.url;
    try {
      url = Uri.decodeFull(url);
    } catch (e) {
      print('$url, UnsupportedEncodingException: ${e.toString()}');
    }

    if (url.contains('?')) {
      url = url.split('?').first;
    }
    if (url.contains('/')) {
      if (url.endsWith('/')) {
        url = 'unknown.bin';
      } else {
        url = url.split('/').last;
      }
    }
    url = replaceSpecialCharacters(url);

    String suffix = '';
    String name = url;
    if (url.contains('.')) {
      suffix = url.substring(url.lastIndexOf('.'));
      name = url.substring(0, url.lastIndexOf('.'));
    }
    if (name.length > 150) {
      name = name.substring(0, 150);
    }
    return '$name$suffix';
  }

  static final RegExp pattern = RegExp(r'[\\s\\\/:\*?"<>|]');

  static String replaceSpecialCharacters(String dirPath) {
    dirPath = dirPath.replaceAll(pattern, '');
    dirPath = dirPath.replaceAll(' ', '-');
    dirPath = dirPath.replaceAll(RegExp(r'[^\u0009\u000a\u000d\u0020-\uD7FF\uE000-\uFFFD]'), '');
    dirPath = dirPath.replaceAll(
        RegExp(r'[\uD83D\uFFFD\uFE0F\u203C\u3010\u3011\u300A\u166D\u200C\u202A\u202C\u2049\u20E3\u300B\u300C\u3030\u065F\u0099\u0F3A\u0F3B\uF610\uFFFC]'), '');

    return dirPath;
  }
}


