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
    [self.client getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable userModelDictionary, NSError * _Nullable error) {
        PanBaiduNetdiskUser *user = [[PanBaiduNetdiskUser alloc] initWithDictionary:userModelDictionary];
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
    UIButton *actionButton =  [UIButton buttonWithType:UIButtonTypeInfoLight];
    [actionButton addTarget:self action:@selector(actionShowMoreActions:) forControlEvents:UIControlEventTouchUpInside];
    actionButton.tag = indexPath.row + 16;
    cell.accessoryView = actionButton;
    return cell;
}

- (void)actionShowMoreActions:(UIButton *)sender {
    NSInteger index = sender.tag - 16;
    LSOnlineFile *file = [self.files objectAtIndex:index];
    UIAlertController *actionsController = [UIAlertController alertControllerWithTitle:@"More actions" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *infoController = [UIAlertController alertControllerWithTitle:error?@"Error":@"Result" message:[NSString stringWithFormat:@"%@",((error!=nil)?error:dictionary)] preferredStyle:UIAlertControllerStyleAlert];
        [infoController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf reloadContentDataAndUpdateViewInternal];
        }]];
        [self presentViewController:infoController animated:YES completion:nil];
    });
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
