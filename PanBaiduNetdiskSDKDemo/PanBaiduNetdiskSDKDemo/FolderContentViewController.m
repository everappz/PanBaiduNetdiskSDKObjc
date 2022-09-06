//
//  FolderContentViewController.m
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "FolderContentViewController.h"
#import "PanBaiduNetdiskHelper.h"
#import "LSOnlineFile.h"
#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>


NSString * const kTableViewCellIdentifier = @"kTableViewCellIdentifier";

@interface FolderContentViewController ()

@property (nonatomic,strong)id<PanBaiduNetdiskAPIClientCancellableRequest> request;

@property (nonatomic,strong)NSArray <LSOnlineFile *> *files;

@end

@implementation FolderContentViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.tableView.rowHeight = 52.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = self.rootDirectory.name;
    [self reloadContentDataAndUpdateView];
}

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
    [self.client getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable userIDInfoDictionary, NSError * _Nullable error) {
        PanBaiduNetdiskUser *user = [[PanBaiduNetdiskUser alloc] initWithDictionary:userIDInfoDictionary];
        NSString *userID = [user userID];
        if (completion) {
            completion (userID, error);
        }
    }];
}

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
        cell.imageView.image = [UIImage imageNamed:@"file.png"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", file.createdAt, [PanBaiduNetdiskHelper readableStringForByteSize:@(file.contentLength)]];
    }
    else{
        cell.imageView.image = [UIImage imageNamed:@"folder.png"];
        cell.detailTextLabel.text = nil;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LSOnlineFile *file = [self.files objectAtIndex:indexPath.row];
    if(file.directory){
        FolderContentViewController *contentViewController = [FolderContentViewController new];
        contentViewController.client = self.client;
        contentViewController.userID = self.userID;
        contentViewController.rootDirectory = file;
        [self.navigationController pushViewController:contentViewController animated:YES];
    }
}

@end
