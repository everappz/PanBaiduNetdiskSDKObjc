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
