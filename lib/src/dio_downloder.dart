import 'dart:io';

import 'package:dio/dio.dart';
//import 'package:dio_http_formatter/dio_http_formatter.dart';

import 'file_dir_util.dart';



class FileDownloader {
  static Set<String> _runningTask = {};
  static Dio? _dio ;

  static set dio(Dio value) {
    _dio = value;
  }

  static bool _openLog = false;

  static set openLog(bool value) {
    _openLog = value;
  }

  static Dio initDio() {
    Dio dio = Dio();
    if(_openLog){
      //dio.interceptors.add(HttpFormatter());
    }
    return dio;
  }

  static String? globalSaveDir;
  static Map<String,CancelToken> _tokenMap = {};

  static void cancel(String url){
    _tokenMap.remove(url)?.cancel("user canceled");
    _runningTask.remove(url);
  }


  String url;
  String? filePath;
  String? saveDir;
  String? fileName;
  bool? forceRedownload;
  bool? notAcceptRanges;
  Map<String, dynamic> headers;
  int? fileSizeAlreadyKnown;
  int progressCallbackIntervalMills;
  int retryTimes;
  Map<String, Object> tags;
  void Function(String url, String filePath)? onStartReal;
  void Function(
      String url, String filePath, String code, String msg, Exception? e)?
  onFailed;
  void Function(String url, String filePath) onSuccess;
  void Function(String url, String filePath, int total, int alreadyReceived,
      int speed)? onProgress;
  void Function(String url, String filePath)? onCancel;

  FileDownloader({
    required this.url,
    this.filePath,
    this.fileName,
    this.forceRedownload,
    this.notAcceptRanges,
    this.headers = const {},
    this.fileSizeAlreadyKnown,
    this.onStartReal,
    this.onFailed,
    this.progressCallbackIntervalMills = 300,
    this.retryTimes = 1,
    this.tags = const {},
    required this.onSuccess,
    this.onProgress,
    this.onCancel,
  });




  Future<void> start() async {
    _dio ??= initDio();
    FileDownloader config = this;
    String url = config.url;
    String? filePath = config.filePath;
    bool forceRedownload = config.forceRedownload ?? false;
    bool notAcceptRanges = config.notAcceptRanges ?? false;
    int? fileSizeAlreadyKnown = config.fileSizeAlreadyKnown;

    config.onStartReal?.call(url, filePath ?? "");

    if (_runningTask.contains(url)) {
      printLog('该url已经在下载中 $url');
      config.onFailed?.call(url, filePath ?? "", '', '该url已经在下载中', null);
      return;
    }

    try {
      filePath = await FileAndDirUtil.dealFilePath(config);
      config.filePath = filePath;
    } catch (e) {
      printLog('下载失败0 $url \n $e');
      config.onFailed?.call(url, filePath ?? "", '', e.toString(), null);
      return;
    }
    try {
      File file = File(filePath);

      bool isRangeRequest = false;

      if (file.existsSync() && file.lengthSync() > 0 && forceRedownload) {
        file.deleteSync();
      }

      _runningTask.add(url);

      Map<String, dynamic> headers = {};
      headers.addAll(config.headers);

      if (file.existsSync() && file.lengthSync() > 0) {
        Response headResponse = await _dio!.head(url,options: Options(headers: config.headers));

        if (fileSizeAlreadyKnown == null || fileSizeAlreadyKnown == 0) {
          fileSizeAlreadyKnown =
              int.tryParse(headResponse.headers.value('content-length') ?? '0');
        }

        bool supportRanges =
            headResponse.headers.value('accept-ranges') == 'bytes';


        if (fileSizeAlreadyKnown != null && fileSizeAlreadyKnown > 0) {
          if (file.lengthSync() == fileSizeAlreadyKnown) {
            printLog('文件已存在并且大小与服务器匹配 $filePath');
            _runningTask.remove(url);
            config.onSuccess(url, filePath);
            return;
          } else if (supportRanges && !notAcceptRanges) {
            headers['Range'] = 'bytes=${file.lengthSync()}-';
            isRangeRequest = true;
          } else {
            file.deleteSync();
          }
        }
      }

      CancelToken cancelToken = CancelToken();
      _tokenMap[url] = cancelToken;
      Response<ResponseBody> response = await _dio!.get<ResponseBody>(url,
          options: Options(responseType: ResponseType.stream,headers: headers),
      cancelToken: cancelToken);

      if (response.statusCode != 200 && response.statusCode != 206) {
        printLog('下载失败: ${response.statusCode}, $url');
        _runningTask.remove(url);
        _tokenMap.remove(url);
        config.onFailed?.call(url, filePath, response.statusCode.toString(),
            '下载失败: ${response.statusMessage}', null);
        return;
      }

      var contentLength =
          int.tryParse(response.headers.value('content-length') ?? '0');

      fileSizeAlreadyKnown = fileSizeAlreadyKnown ??contentLength ;

      var totalBytesReceived = file.existsSync() ? file.lengthSync() : 0;

      var sink = isRangeRequest
          ? file.openWrite(mode: FileMode.append)
          : file.openWrite();
      int lastReceived = 0;
      int lastProgressTime = 0;
      await response.data!.stream.listen(
        (data) {
          sink.add(data);
          totalBytesReceived += data.length;
          if(lastProgressTime ==0){
            lastReceived = data.length;
            lastProgressTime = DateTime.now().millisecondsSinceEpoch;
            config.onProgress?.call(url, filePath!, fileSizeAlreadyKnown ?? 0,
                totalBytesReceived, 0);
          }else{
            if(DateTime.now().millisecondsSinceEpoch - lastProgressTime >= config.progressCallbackIntervalMills){
              int received = totalBytesReceived - lastReceived;
              int speed = (received * 1000 /(DateTime.now().millisecondsSinceEpoch - lastProgressTime)).round();
              lastProgressTime = DateTime.now().millisecondsSinceEpoch;
              lastReceived = totalBytesReceived;
              config.onProgress?.call(url, filePath!, fileSizeAlreadyKnown ?? 0,
                  totalBytesReceived, speed);
              int? size = fileSizeAlreadyKnown;
              if(fileSizeAlreadyKnown == null || fileSizeAlreadyKnown ==0){
                printLog("download-progress: unknown%, $url"
                    "\n${(totalBytesReceived/1024).toStringAsFixed(0)}KB, speed: ${(speed/1024).toStringAsFixed(0)}KB/s");
              }else{
                printLog("download-progress: ${(totalBytesReceived*100.0/(fileSizeAlreadyKnown)).toStringAsFixed(1)}%, $url"
                    "\n${(totalBytesReceived/1024).toStringAsFixed(0)}KB, speed: ${(speed/1024).toStringAsFixed(0)}KB/s");
              }

            }
          }

          /*if(!_runningTask.contains(url)){
            throw HttpException("canceled", uri: Uri.tryParse(url));
          }*/
        },
        onDone: () async {
          await sink.close();

          _runningTask.remove(url);
          _tokenMap.remove(url);
          if (fileSizeAlreadyKnown != null && fileSizeAlreadyKnown>0 &&
              file.lengthSync() != fileSizeAlreadyKnown) {
            printLog('下载失败: 文件大小不匹配 $url  ${file.lengthSync()}, $fileSizeAlreadyKnown');

            config.onFailed?.call(
              url,
              filePath!,
              'size not same',
              '文件大小不匹配: ${file.lengthSync()}, $fileSizeAlreadyKnown',
              null,
            );
            file.deleteSync();
          } else {
            config.onSuccess(url, filePath!);
            printLog('下载成功 $url  -> $filePath');
          }
        },
        onError: (e,s) {
          //HttpException: Connection closed while receiving data
          String text = e.toString();
          if(text.startsWith("HttpException: Connection closed while receiving data")){
            if(!_tokenMap.containsKey(url)){
              //为取消的请求:
              printLog('请求被手动取消: $url \n-> $e ->\n$s');
              config.onCancel?.call(url, filePath!);
              return;
            }
          }
          _runningTask.remove(url);
          _tokenMap.remove(url);
          config.onFailed?.call(url, filePath!, "", e.toString(), null);
          printLog('下载失败2: $url \n-> $e ->\n$s');

          //HttpException: Connection closed while receiving data
        },
        cancelOnError: true,
      );
    } catch (e) {
      _runningTask.remove(url);
      _tokenMap.remove(url);
      String msg = e.toString();
      if (e is DioError) {
        DioError error = e;
        msg = error.message;
      }
      config.onFailed?.call(url, filePath, "", msg, e as Exception);
      printLog('下载失败1: $url \n-> $msg');
    }
  }

  void printLog(String s) {
    if(_openLog){
      print(s);
    }
  }


}

void main() async {

  //init
  //open log , close default
  FileDownloader.openLog = true;
  //custom your dio . not necessary.
  //FileDownloader.dio = Dio();

  //default download save dir, must be set if not set filePath when download
  FileDownloader.globalSaveDir = "/Users/hss/Downloads";



  //var url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4";

  //response without content-length
  var url = "http://www.httpwatch.com/httpgallery/chunked/chunkedimage.aspx?0.04400023248109086";
 FileDownloader(
    url: url,
    //filePath: "/Users/hss/Downloads/WeAreGoingOnBullrun-2.mp4",
    onSuccess: (url, filePath) {
      //printLog('下载成功: $url -> $filePath');
    },
  ).start();

 //cancel download
 //Future.delayed(Duration(seconds: 3)).then((value) => FileDownloader.cancel(url));




}
