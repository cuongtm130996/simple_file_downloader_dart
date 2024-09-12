import 'package:simple_file_downloader_dart/simple_file_downloader_dart.dart';

void main() {
  //init
  //open log , close default
  FileDownloader.openLog = true;
  //custom your dio . not necessary.
  //FileDownloader.dio = Dio();

  //default download save dir, must be set if not set filePath when download
  FileDownloader.globalSaveDir = "/Users/hss/Downloads";



 // var url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4";
  var url = "https://background-business-biz-service-test.oss-cn-hongkong.aliyuncs.com/other/ec79ac786e0a4611afda838510d4fe69116461.pdf"
      "?Expires=1728716365&OSSAccessKeyId=LTAI4Fg2iUt3nkSrCM2DfiXW&Signature=mKYoz9nLoWufaBpglc68xSI9DgM%3D";

  //response without content-length
  //var url = "http://www.httpwatch.com/httpgallery/chunked/chunkedimage.aspx?0.04400023248109086";
  FileDownloader(
    url: url,
    //filePath: "/Users/hss/Downloads/WeAreGoingOnBullrun-2.mp4",
    onSuccess: (url, filePath) {
      //print('下载成功: $url -> $filePath');
    },
  ).start();

  //cancel download
  //Future.delayed(Duration(seconds: 3)).then((value) => FileDownloader.cancel(url));
}
