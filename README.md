# PanBaiduNetdiskSDKObjc

Objective-C SDK for the [Baidu Pan (Baidu Netdisk) Open Platform API](https://pan.baidu.com/union/doc/).

Supports file listing, upload, download, copy, move, rename, delete, folder creation, and user info retrieval.

Minimum iOS version: 9.0

## Setup

Register your app and obtain developer keys at: https://pan.baidu.com/union/console/createapp

Install via CocoaPods:

```ruby
pod 'PanBaiduNetdiskSDKObjc'
```

## Usage

### Configure Auth Manager

Set up the shared auth manager in your `AppDelegate` with your app credentials:

```objc
#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [PanBaiduAppAuthManager setSharedManagerWithClientID:@"YOUR_CLIENT_ID"
                                            clientSecret:@"YOUR_CLIENT_SECRET"
                                                   appID:@"YOUR_APP_ID"
                                             redirectURI:@"YOUR_REDIRECT_URI"];
    return YES;
}
```

### Authenticate User

Start the OAuth flow using a `WKWebView` or a view controller:

```objc
// Option 1: Using WKWebView
[[PanBaiduAppAuthManager sharedManager]
    authFlowWithAutoCodeExchangeFromWebView:webView
                webViewDidStartLoadingBlock:^(WKWebView *webView) { /* show spinner */ }
               webViewDidFinishLoadingBlock:^(WKWebView *webView) { /* hide spinner */ }
               webViewDidFailWithErrorBlock:^(WKWebView *webView, NSError *error) { /* handle error */ }
                            completionBlock:^(PanBaiduNetdiskAuthState *authState, NSError *error) {
    if (authState) {
        // Authentication succeeded, create the API client
    }
}];

// Option 2: Using ASWebAuthenticationSession (via view controller)
[[PanBaiduAppAuthManager sharedManager]
    authFlowWithAutoCodeExchangeFromViewController:self
                                   completionBlock:^(PanBaiduNetdiskAuthState *authState, NSError *error) {
    if (authState) {
        // Authentication succeeded
    }
}];
```

### Create API Client

```objc
// From auth state (after successful authentication)
PanBaiduAppAuthProvider *authProvider =
    [[PanBaiduAppAuthProvider alloc] initWithIdentifier:userID state:authState];

PanBaiduNetdiskAPIClient *client =
    [[PanBaiduNetdiskAPIClient alloc] initWithURLSessionConfiguration:nil
                                                         authProvider:authProvider];

// Or restore from saved auth data
PanBaiduNetdiskAPIClient *client =
    [PanBaiduNetdiskAPIClient createNewOrGetCachedClientWithAuthData:savedAuthDictionary];
```

### Get User Info

```objc
[client getUserInfoWithCompletionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"User: %@", dictionary[@"baidu_name"]);
        NSLog(@"VIP type: %@", dictionary[@"vip_type"]);
    }
}];
```

### List Files

```objc
// List root directory
[client getFilesListAtPath:@"/"
           completionBlock:^(NSArray<NSDictionary *> *array, NSError *error) {
    for (NSDictionary *file in array) {
        NSLog(@"%@ (isdir: %@, size: %@)",
              file[@"server_filename"],
              file[@"isdir"],
              file[@"size"]);
    }
}];
```

### Get File Info

```objc
[client getInfoForFileWithID:@"123456789"
                       dlink:YES    // include download link
                       thumb:YES    // include thumbnail URL
                       extra:NO
                   needmedia:NO
             completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"Filename: %@", dictionary[@"filename"]);
        NSLog(@"Download link: %@", dictionary[@"dlink"]);
    }
}];
```

### Create Folder

```objc
[client createFolderAtPath:@"/my_new_folder"
           completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"Created folder fs_id: %@", dictionary[@"fs_id"]);
    }
}];
```

### Delete File

Moves the file to the recycle bin. Files are retained for 10 days (180 days for SVIP users).

```objc
[client deleteFileAtPath:@"/path/to/file.txt"
         completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"File moved to recycle bin");
    }
}];
```

### Rename File

```objc
[client renameFileAtPath:@"/path/to/old_name.txt"
                    name:@"new_name.txt"
         completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"File renamed");
    }
}];
```

### Move File

```objc
[client moveFileAtPath:@"/source/file.txt"
                toPath:@"/destination/file.txt"
       completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"File moved");
    }
}];
```

### Copy File

```objc
[client copyFileAtPath:@"/source/file.txt"
                toPath:@"/destination/file_copy.txt"
       completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"File copied");
    }
}];
```

### Download File to Disk

```objc
[client downloadContentForFileWithID:@"123456789"
                       progressBlock:^(float progress) {
    NSLog(@"Download progress: %.0f%%", progress * 100);
}
                     completionBlock:^(NSURL *location, NSError *error) {
    if (location) {
        // Move the file from the temporary location
        NSString *destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"downloaded_file.txt"];
        [[NSFileManager defaultManager] moveItemAtURL:location
                                                toURL:[NSURL fileURLWithPath:destPath]
                                                error:nil];
    }
}];
```

### Get Direct Download URL

```objc
[client getDirectURLForFileWithID:@"123456789"
                  completionBlock:^(NSURL *location, NSError *error) {
    if (location) {
        NSLog(@"Direct URL: %@", location);
        // Use with AVPlayer, external download manager, etc.
    }
}];
```

### Stream File Content

```objc
[client getContentForFileWithID:@"123456789"
              additionalHeaders:@{}  // or @{@"Range": @"bytes=0-1023"} for partial download
            didReceiveDataBlock:^(NSData *data) {
    // Process each data chunk as it arrives
}
        didReceiveResponseBlock:^(NSURLResponse *response) {
    NSLog(@"Content-Length: %lld", response.expectedContentLength);
}
                completionBlock:^(NSError *error) {
    if (!error) {
        NSLog(@"Download complete");
    }
}];
```

### Upload File

Uses chunked upload (4 MB chunks). Overwrites existing files at the same remote path.

```objc
NSString *localPath = [[NSBundle mainBundle] pathForResource:@"photo" ofType:@"jpg"];

[client uploadFileFromLocalPath:localPath
                   toRemotePath:@"/apps/myapp/photo.jpg"
                  progressBlock:^(float progress) {
    NSLog(@"Upload progress: %.0f%%", progress * 100);
}
                completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"Uploaded file fs_id: %@", dictionary[@"fs_id"]);
        NSLog(@"MD5: %@", dictionary[@"md5"]);
    }
}];
```

### Cancel All Requests

```objc
[client cancelAllRequests];
```

## Apps Using This SDK

[**Evermusic**](https://itunes.apple.com/us/app/evermusic/id885367198?ls=1&mt=8)

[**Evermusic Pro**](https://itunes.apple.com/us/app/evermusic-pro/id905746421?ls=1&mt=8)

[**Flacbox**](https://apps.apple.com/us/app/flacbox-flac-player-equalizer/id1097564256)

## Screenshots

<img src="https://raw.githubusercontent.com/everappz/PanBaiduNetdiskSDKObjc/main/Screenshots/login_screen.png" width="300"><img src="https://raw.githubusercontent.com/everappz/PanBaiduNetdiskSDKObjc/main/Screenshots/folder_content.png" width="300">

## Contacts

support@everappz.com

http://everappz.com/support/

## License

```
The MIT License (MIT)

Copyright (c) 2022 Artem Meleshko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

# PanBaiduNetdiskSDKObjc (中文)

百度网盘开放平台 Objective-C SDK。[官方 API 文档](https://pan.baidu.com/union/doc/)

支持文件列表、上传、下载、复制、移动、重命名、删除、创建文件夹及用户信息获取。

最低 iOS 版本：9.0

## 安装

在百度网盘开放平台注册应用并获取开发者密钥：https://pan.baidu.com/union/console/createapp

通过 CocoaPods 安装：

```ruby
pod 'PanBaiduNetdiskSDKObjc'
```

## 使用说明

### 配置认证管理器

在 `AppDelegate` 中使用您的应用凭证配置共享认证管理器：

```objc
#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [PanBaiduAppAuthManager setSharedManagerWithClientID:@"您的_CLIENT_ID"
                                            clientSecret:@"您的_CLIENT_SECRET"
                                                   appID:@"您的_APP_ID"
                                             redirectURI:@"您的_REDIRECT_URI"];
    return YES;
}
```

### 用户认证

通过 `WKWebView` 或视图控制器启动 OAuth 认证流程：

```objc
// 方式一：使用 WKWebView
[[PanBaiduAppAuthManager sharedManager]
    authFlowWithAutoCodeExchangeFromWebView:webView
                webViewDidStartLoadingBlock:^(WKWebView *webView) { /* 显示加载指示器 */ }
               webViewDidFinishLoadingBlock:^(WKWebView *webView) { /* 隐藏加载指示器 */ }
               webViewDidFailWithErrorBlock:^(WKWebView *webView, NSError *error) { /* 处理错误 */ }
                            completionBlock:^(PanBaiduNetdiskAuthState *authState, NSError *error) {
    if (authState) {
        // 认证成功，创建 API 客户端
    }
}];

// 方式二：使用 ASWebAuthenticationSession（通过视图控制器）
[[PanBaiduAppAuthManager sharedManager]
    authFlowWithAutoCodeExchangeFromViewController:self
                                   completionBlock:^(PanBaiduNetdiskAuthState *authState, NSError *error) {
    if (authState) {
        // 认证成功
    }
}];
```

### 创建 API 客户端

```objc
// 通过认证状态创建（认证成功后）
PanBaiduAppAuthProvider *authProvider =
    [[PanBaiduAppAuthProvider alloc] initWithIdentifier:userID state:authState];

PanBaiduNetdiskAPIClient *client =
    [[PanBaiduNetdiskAPIClient alloc] initWithURLSessionConfiguration:nil
                                                         authProvider:authProvider];

// 或从已保存的认证数据恢复
PanBaiduNetdiskAPIClient *client =
    [PanBaiduNetdiskAPIClient createNewOrGetCachedClientWithAuthData:savedAuthDictionary];
```

### 获取用户信息

```objc
[client getUserInfoWithCompletionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"用户名: %@", dictionary[@"baidu_name"]);
        NSLog(@"会员类型: %@", dictionary[@"vip_type"]);
    }
}];
```

### 获取文件列表

```objc
// 列出根目录
[client getFilesListAtPath:@"/"
           completionBlock:^(NSArray<NSDictionary *> *array, NSError *error) {
    for (NSDictionary *file in array) {
        NSLog(@"%@（是否目录: %@, 大小: %@）",
              file[@"server_filename"],
              file[@"isdir"],
              file[@"size"]);
    }
}];
```

### 获取文件信息

```objc
[client getInfoForFileWithID:@"123456789"
                       dlink:YES    // 包含下载链接
                       thumb:YES    // 包含缩略图 URL
                       extra:NO
                   needmedia:NO
             completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"文件名: %@", dictionary[@"filename"]);
        NSLog(@"下载链接: %@", dictionary[@"dlink"]);
    }
}];
```

### 创建文件夹

```objc
[client createFolderAtPath:@"/我的新文件夹"
           completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"已创建文件夹 fs_id: %@", dictionary[@"fs_id"]);
    }
}];
```

### 删除文件

将文件移动到回收站。普通用户保留 10 天，超级会员保留 180 天。

```objc
[client deleteFileAtPath:@"/path/to/file.txt"
         completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"文件已移至回收站");
    }
}];
```

### 重命名文件

```objc
[client renameFileAtPath:@"/path/to/old_name.txt"
                    name:@"new_name.txt"
         completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"文件已重命名");
    }
}];
```

### 移动文件

```objc
[client moveFileAtPath:@"/source/file.txt"
                toPath:@"/destination/file.txt"
       completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"文件已移动");
    }
}];
```

### 复制文件

```objc
[client copyFileAtPath:@"/source/file.txt"
                toPath:@"/destination/file_copy.txt"
       completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (!error) {
        NSLog(@"文件已复制");
    }
}];
```

### 下载文件到本地

```objc
[client downloadContentForFileWithID:@"123456789"
                       progressBlock:^(float progress) {
    NSLog(@"下载进度: %.0f%%", progress * 100);
}
                     completionBlock:^(NSURL *location, NSError *error) {
    if (location) {
        // 将文件从临时位置移动到目标位置
        NSString *destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"downloaded_file.txt"];
        [[NSFileManager defaultManager] moveItemAtURL:location
                                                toURL:[NSURL fileURLWithPath:destPath]
                                                error:nil];
    }
}];
```

### 获取直接下载链接

```objc
[client getDirectURLForFileWithID:@"123456789"
                  completionBlock:^(NSURL *location, NSError *error) {
    if (location) {
        NSLog(@"直接下载链接: %@", location);
        // 可用于 AVPlayer、外部下载管理器等
    }
}];
```

### 流式下载文件内容

```objc
[client getContentForFileWithID:@"123456789"
              additionalHeaders:@{}  // 或 @{@"Range": @"bytes=0-1023"} 用于部分下载
            didReceiveDataBlock:^(NSData *data) {
    // 逐块处理接收到的数据
}
        didReceiveResponseBlock:^(NSURLResponse *response) {
    NSLog(@"Content-Length: %lld", response.expectedContentLength);
}
                completionBlock:^(NSError *error) {
    if (!error) {
        NSLog(@"下载完成");
    }
}];
```

### 上传文件

使用分块上传（每块 4 MB）。如果远程路径已存在同名文件则覆盖。

```objc
NSString *localPath = [[NSBundle mainBundle] pathForResource:@"photo" ofType:@"jpg"];

[client uploadFileFromLocalPath:localPath
                   toRemotePath:@"/apps/myapp/photo.jpg"
                  progressBlock:^(float progress) {
    NSLog(@"上传进度: %.0f%%", progress * 100);
}
                completionBlock:^(NSDictionary *dictionary, NSError *error) {
    if (dictionary) {
        NSLog(@"已上传文件 fs_id: %@", dictionary[@"fs_id"]);
        NSLog(@"MD5: %@", dictionary[@"md5"]);
    }
}];
```

### 取消所有请求

```objc
[client cancelAllRequests];
```

## 使用本 SDK 的应用

[**Evermusic**](https://itunes.apple.com/us/app/evermusic/id885367198?ls=1&mt=8)

[**Evermusic Pro**](https://itunes.apple.com/us/app/evermusic-pro/id905746421?ls=1&mt=8)

[**Flacbox**](https://apps.apple.com/us/app/flacbox-flac-player-equalizer/id1097564256)

## 截图

<img src="https://raw.githubusercontent.com/everappz/PanBaiduNetdiskSDKObjc/main/Screenshots/login_screen.png" width="300"><img src="https://raw.githubusercontent.com/everappz/PanBaiduNetdiskSDKObjc/main/Screenshots/folder_content.png" width="300">

## 联系方式

support@everappz.com

http://everappz.com/support/
