//
//  FolderContentViewController.m
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "FolderContentViewController.h"
#import "PanBaiduNetdiskHelper.h"
#import "LSOnlineFile.h"
#import "LSPreviewItem.h"
#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>
#import <QuickLook/QuickLook.h>
#import <AVKit/AVKit.h>
#import <AVKit/AVPlayerViewController.h>

NSString * const kTableViewCellIdentifier = @"kTableViewCellIdentifier";

@interface FolderContentViewController ()<QLPreviewControllerDataSource,QLPreviewControllerDelegate,AVPlayerViewControllerDelegate>

@property (nonatomic,strong)id<PanBaiduNetdiskAPIClientCancellableRequest> request;
@property (nonatomic,strong)NSArray <LSOnlineFile *> *files;
@property (nonatomic,strong)LSPreviewItem *previewItem;

@end

@implementation FolderContentViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.tableView.rowHeight = 52.0;
    
    self.navigationItem.rightBarButtonItems =
    @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(actionCreateFolder:)],
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionUpload:)]];
    
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = self.rootDirectory.name;
    [self reloadContentDataAndUpdateView];
}

#pragma mark - Load Content

- (void)reloadContentDataAndUpdateView{
    if (self.userID == nil) {
        __weak typeof (self) weakSelf = self;
        [self loadUserIDWithCompletion:^(NSString *userID, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error){
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                   message:error.localizedDescription
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil]];
                    [weakSelf presentViewController:alert
                                           animated:YES
                                         completion:nil];
                    [weakSelf.tableView reloadData];
                }
                else{
                    [weakSelf reloadContentDataAndUpdateViewInternal];
                }
            });
        }];
    }
    else{
        [self reloadContentDataAndUpdateViewInternal];
    }
}

- (void)reloadContentDataAndUpdateViewInternal{
    __weak typeof (self) weakSelf = self;
    void(^completion)(NSArray<LSOnlineFile *> *, NSError *) = ^(NSArray<LSOnlineFile *> *files, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                               message:error.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [weakSelf presentViewController:alert
                                       animated:YES
                                     completion:nil];
            }
            weakSelf.files = files;
            weakSelf.navigationItem.title = weakSelf.rootDirectory.url.path;
            [weakSelf.tableView reloadData];
        });
    };
    
    NSParameterAssert(self.userID!=nil);
    [self loadFolderContent:self.rootDirectory completion:completion];
}

- (void)loadFolderContent:(LSOnlineFile *)directory
               completion:(void(^)(NSArray<LSOnlineFile *> *files,NSError *error))completion{
    
    NSString *itemPath = self.rootDirectory.url.path;
    
    __weak typeof (self) weakSelf = self;
    self.request = [self.client getFilesListAtPath:itemPath
                                   completionBlock:^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        if(error){
            if(completion){
                completion(nil,error);
            }
        }
        else if(array!=nil && [array isKindOfClass:[NSArray class]]==NO){
            if(completion){
                completion(nil,[PanBaiduNetdiskHelper unknownError]);
            }
        }
        else{
            NSMutableArray *files = [NSMutableArray new];
            [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                PanBaiduNetdiskFile *file = [[PanBaiduNetdiskFile alloc] initWithDictionary:obj];
                if(file){
                    [files addObject:file];
                }
            }];
            LSOnlineFile *parentDirectory = weakSelf.rootDirectory;
            NSArray<LSOnlineFile *> *resultFiles = [PanBaiduNetdiskHelper onlineFilesFromApiFiles:files parentDirectory:parentDirectory];
            if(completion){
                completion(resultFiles,nil);
            }
        }
    }];
}

- (void)loadUserIDWithCompletion:(void(^)(NSString *userID,NSError *error))completion{
    [self.client getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable userModelDictionary, NSError * _Nullable error) {
        PanBaiduNetdiskUser *user = [[PanBaiduNetdiskUser alloc] initWithDictionary:userModelDictionary];
        NSString *userID = [user userID];
        if (completion) {
            completion (userID, error);
        }
    }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kTableViewCellIdentifier];
    }
    LSOnlineFile *file = [self.files objectAtIndex:indexPath.row];
    cell.textLabel.text = file.name;
    if(file.directory == NO){
        cell.imageView.image = [PanBaiduNetdiskHelper imageWithImage:[UIImage imageNamed:@"file.png"] scaledToSize:CGSizeMake(32.0, 32.0)];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", file.createdAt, [PanBaiduNetdiskHelper readableStringForByteSize:@(file.contentLength)]];
    }
    else{
        cell.imageView.image = [PanBaiduNetdiskHelper imageWithImage:[UIImage imageNamed:@"folder.png"] scaledToSize:CGSizeMake(32.0, 32.0)];
        cell.detailTextLabel.text = nil;
    }
    UIButton *actionButton =  [UIButton buttonWithType:UIButtonTypeInfoLight];
    [actionButton addTarget:self action:@selector(actionShowMoreActions:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.tag = indexPath.row + 16;
    cell.accessoryView = actionButton;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LSOnlineFile *file = [self.files objectAtIndex:indexPath.row];
    if (file.directory) {
        FolderContentViewController *contentViewController = [FolderContentViewController new];
        contentViewController.client = self.client;
        contentViewController.userID = self.userID;
        contentViewController.rootDirectory = file;
        [self.navigationController pushViewController:contentViewController animated:YES];
    }
    else {
        UIProgressView *progressView = [self showProgressView];
        
        __weak typeof (self) weakSelf = self;
        
        [self.client downloadContentForFileWithID:file.identifier progressBlock:^(float progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressView.progress = progress;
            });
        } completionBlock:^(NSURL * _Nullable location, NSError * _Nullable error) {
            
            if (location) {
                
                NSString *destinationPath = [[FolderContentViewController applicationDocumentsDirectory].path stringByAppendingPathComponent:file.name];
                [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
                NSURL *fileURL = [NSURL fileURLWithPath:destinationPath];
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:nil];
                
                if (file.contentType == 1 || file.contentType == 2) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
                        AVPlayer *player = [AVPlayer playerWithURL:fileURL];
                        NSCParameterAssert(player);
                        __weak typeof (player) weakPlayer = player;
                        playerViewController.player = player;
                        
                        [weakSelf presentViewController:playerViewController animated:YES completion:^{
                            [weakPlayer play];
                        }];
                    });
                }
                else {
                    LSPreviewItem *item = [[LSPreviewItem alloc] init];
                    item.previewItemURL = fileURL;
                    item.previewItemTitle = file.name;
                    weakSelf.previewItem = item;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        QLPreviewController *controller = [QLPreviewController new];
                        controller.dataSource = weakSelf;
                        controller.delegate = weakSelf;
                        [weakSelf presentViewController:controller animated:YES completion:nil];
                    });
                }
                
            }
            else {
                [weakSelf processResultWithDictionary:nil error:error];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf hideProgressView];
            });
        }];
    }
}

- (UIProgressView *)showProgressView {
    NSParameterAssert([NSThread isMainThread]);
    UIToolbar *toolbar = self.navigationController.toolbar;
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    UIBarButtonItem *progressItem = [[UIBarButtonItem alloc] initWithCustomView:progressView];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(actionCancelAllOperations:)];
    UIBarButtonItem *spaceItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *spaceItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem *spaceItem3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    [toolbar setItems:@[spaceItem1,progressItem,spaceItem2,cancelItem,spaceItem3]];
    return progressView;
}

- (void)hideProgressView {
    NSParameterAssert([NSThread isMainThread]);
    UIToolbar *toolbar = self.navigationController.toolbar;
    [toolbar setItems:nil];
}

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Actions

- (void)actionCancelAllOperations:(id)sender {
    [self.client cancelAllRequests];
    [self.navigationController.toolbar setItems:nil];
}

- (void)actionCreateFolder:(id)sender {
    UIAlertController *createFolderController = [UIAlertController alertControllerWithTitle:@"Create Folder" message:nil preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof (createFolderController) weakCreateFolderController = createFolderController;
    __weak typeof (self) weakSelf = self;
    [createFolderController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    [createFolderController addAction:[UIAlertAction actionWithTitle:@"Create Folder" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *text = weakCreateFolderController.textFields[0].text;
        NSString *path = [weakSelf.rootDirectory.url.path stringByAppendingPathComponent:text];
        [weakSelf.client createFolderAtPath:path
                            completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            [weakSelf processResultWithDictionary:dictionary error:error];
        }];
    }]];
    [createFolderController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:createFolderController animated:YES completion:nil];
}

- (void)actionUpload:(id)sender {
    __weak typeof (self) weakSelf = self;
    UIProgressView *progressView = [self showProgressView];
    
    NSString *localPath = nil;
    if ((arc4random() % 2) == 1) {
        localPath = [[NSBundle mainBundle] pathForResource:@"file_example_WAV_10MG" ofType:@"wav"];
    }
    else {
        localPath = [[NSBundle mainBundle] pathForResource:@"file_example_2M" ofType:@"mp3"];
    }
    
    NSParameterAssert(localPath);
    [self.client uploadFileFromLocalPath:localPath
                            toRemotePath:[self.rootDirectory.url.path stringByAppendingPathComponent:localPath.lastPathComponent]
                           progressBlock:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressView.progress = progress;
        });
    } completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        [weakSelf processResultWithDictionary:dictionary error:error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideProgressView];
        });
    }];
}

- (void)actionShowMoreActions:(UIButton *)sender {
    NSInteger index = sender.tag - 16;
    LSOnlineFile *file = [self.files objectAtIndex:index];
    UIAlertController *actionsController = [UIAlertController alertControllerWithTitle:@"More actions" message:@"Please select file action." preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof (self) weakSelf = self;
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Show Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.client getInfoForFileWithID:file.identifier
                                        dlink:YES
                                        thumb:YES
                                        extra:YES
                                    needmedia:YES
                              completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            [weakSelf processResultWithDictionary:dictionary error:error];
        }];
    }]];
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Get Direct URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.client getDirectURLForFileWithID:file.identifier
                                   completionBlock:^(NSURL * _Nullable location, NSError * _Nullable error) {
            NSMutableDictionary *resultDictionary = [NSMutableDictionary new];
            if (location) {
                [resultDictionary setObject:location forKey:@"location"];
            }
            [weakSelf processResultWithDictionary:resultDictionary error:error];
        }];
    }]];
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Get First 10 bytes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.client getContentForFileWithID:file.identifier additionalHeaders:@{@"":@""} didReceiveDataBlock:^(NSData * _Nullable data) {
            NSMutableDictionary *resultDictionary = [NSMutableDictionary new];
            if (data) {
                [resultDictionary setObject:[NSString stringWithFormat:@"%@",data] forKey:@"data"];
            }
            [weakSelf processResultWithDictionary:resultDictionary error:nil];
        } didReceiveResponseBlock:^(NSURLResponse * _Nullable response) {
            NSMutableDictionary *resultDictionary = [NSMutableDictionary new];
            if (response) {
                [resultDictionary setObject:[NSString stringWithFormat:@"%@",response] forKey:@"response"];
            }
            [weakSelf processResultWithDictionary:resultDictionary error:nil];
        } completionBlock:^(NSError * _Nullable error) {
            [weakSelf processResultWithDictionary:nil error:error];
        }];
    }]];
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Rename File" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *renameController = [UIAlertController alertControllerWithTitle:@"Rename" message:nil preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof (renameController) weakRenameController = renameController;
        [renameController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = file.url.path.lastPathComponent;
        }];
        [renameController addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *name = weakRenameController.textFields[0].text;
            [weakSelf.client renameFileAtPath:file.url.path name:name completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                [weakSelf processResultWithDictionary:dictionary error:error];
            }];
        }]];
        [renameController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [weakSelf presentViewController:renameController animated:YES completion:nil];
    }]];
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Move File" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *moveController = [UIAlertController alertControllerWithTitle:@"Move" message:nil preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof (moveController) weakMoveController = moveController;
        [moveController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = file.url.path;
        }];
        [moveController addAction:[UIAlertAction actionWithTitle:@"Move" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *text = weakMoveController.textFields[0].text;
            [weakSelf.client moveFileAtPath:file.url.path toPath:text completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                [weakSelf processResultWithDictionary:dictionary error:error];
            }];
        }]];
        [moveController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [weakSelf presentViewController:moveController animated:YES completion:nil];
    }]];
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Copy File" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *copyController = [UIAlertController alertControllerWithTitle:@"Copy" message:nil preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof (copyController) weakCopyController = copyController;
        [copyController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = file.url.path;
        }];
        [copyController addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *text = weakCopyController.textFields[0].text;
            [weakSelf.client copyFileAtPath:file.url.path toPath:text completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
                [weakSelf processResultWithDictionary:dictionary error:error];
            }];
        }]];
        [copyController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [weakSelf presentViewController:copyController animated:YES completion:nil];
    }]];
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Delete File" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.client deleteFileAtPath:file.url.path completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
            [weakSelf processResultWithDictionary:dictionary error:error];
        }];
    }]];
    
    [actionsController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionsController animated:YES completion:nil];
}

- (void)processResultWithDictionary:(NSDictionary * _Nullable)dictionary
                              error:(NSError * _Nullable )error
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *infoController = [UIAlertController alertControllerWithTitle:error?@"Error":@"Result" message:[NSString stringWithFormat:@"%@",((error!=nil)?error:dictionary)] preferredStyle:UIAlertControllerStyleAlert];
        [infoController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf reloadContentDataAndUpdateViewInternal];
        }]];
        [self presentViewController:infoController animated:YES completion:nil];
    });
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.previewItem != nil ? 1 : 0;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    return self.previewItem;
}

#pragma mark - QLPreviewControllerDelegate

- (void)previewControllerDidDismiss:(QLPreviewController *)controller {
    self.previewItem = nil;
}

@end
