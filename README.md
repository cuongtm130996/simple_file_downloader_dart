Dart version of  Simple file downloader 



## Features

* pure dart
* support resume from breakpoint
* support progress and speed callback

## Getting started



## Usage



```dart
  //init
  //open log , close default
  FileDownloader.openLog = true;
  //custom your dio . not necessary.
  //FileDownloader.dio = Dio();

  //default download save dir, must be set if not set filePath when download
  FileDownloader.globalSaveDir = "/Users/hss/Downloads";



  var url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4";
 FileDownloader(
    url: url,
    //filePath: "/Users/hss/Downloads/WeAreGoingOnBullrun-2.mp4",
    onSuccess: (url, filePath) {
      //print('下载成功: $url -> $filePath');
    },
  ).start();

 //cancel download
 Future.delayed(Duration(seconds: 3)).then((value) => FileDownloader.cancel(url));
```



the fileDownloader support configs:

```dart
  FileDownloader({
    required this.url,
    this.filePath,
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
```



# some case

### file already downloaded:

![image-20240906100706137](https://cdn.jsdelivr.net/gh/shuiniuhss/myimages@main/imagemac3/image-20240906100706137.png)



### reqeust started then canceled when downloading:

![image-20240906100913113](https://cdn.jsdelivr.net/gh/shuiniuhss/myimages@main/imagemac3/image-20240906100913113.png)

### resume downloading from breakpoint

![image-20240906101036223](https://cdn.jsdelivr.net/gh/shuiniuhss/myimages@main/imagemac3/image-20240906101036223.png)

And finally download success:

![image-20240906101100940](https://cdn.jsdelivr.net/gh/shuiniuhss/myimages@main/imagemac3/image-20240906101100940.png)



### a response without content-length:

![image-20240906101827962](https://cdn.jsdelivr.net/gh/shuiniuhss/myimages@main/imagemac3/image-20240906101827962.png)

## Additional information





