//
//  ViewController.m
//  PanBaiduNetdiskSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import <PanBaiduNetdiskSDKObjc/PanBaiduNetdiskSDKObjc.h>
#import "ViewController.h"
#import "PanBaiduNetdiskAuthViewController.h"
#import "PanBaiduNetdiskHelper.h"
#import "FolderContentViewController.h"
#import "LSOnlineFile.h"


NSString * const kViewControllerPanBaiduNetdiskAuthKey = @"kViewControllerPanBaiduNetdiskAuthKey";

@interface ViewController ()<PanBaiduNetdiskAuthViewControllerDelegate>

@property (nonatomic,strong)UIStackView *stackView;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(authProviderDidChangeNotification:)
                                                 name:PanBaiduAppAuthProviderDidChangeState
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)authProviderDidChangeNotification:(NSNotification *)notification
{
    PanBaiduAppAuthProvider *provider = notification.object;
    NSParameterAssert([provider isKindOfClass:[PanBaiduAppAuthProvider class]]);
    if ([provider isKindOfClass:[PanBaiduAppAuthProvider class]] == NO) {
        return;
    }
    
    PanBaiduNetdiskAuthState *authState = provider.authState;
    NSParameterAssert(authState);
    NSMutableDictionary *authStateDictionary = [NSMutableDictionary new];
    
    NSDictionary *previousAuth = [self loadAuth];
    if (previousAuth) {
        [authStateDictionary addEntriesFromDictionary:previousAuth];
    }
    
    if (authState) {
        NSData *authData = [NSKeyedArchiver archivedDataWithRootObject:authState.token
                                                 requiringSecureCoding:YES
                                                                 error:nil];
        NSParameterAssert(authData);
        
        [authStateDictionary setObject:authData?:[NSData data] forKey:PanBaiduNetdiskAccessTokenDataKey];
    }
    [self saveAuth:authStateDictionary];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.stackView removeFromSuperview];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 20.0;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stackView];
    [stackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40.0].active = YES;
    [stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40.0].active = YES;
    [stackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    self.stackView = stackView;
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startButton setTitle:@"Start New Auth" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [startButton.titleLabel setFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]];
    [startButton setBackgroundColor:[UIColor systemBlueColor]];
    startButton.layer.cornerRadius = 25.0;
    [startButton addTarget:self action:@selector(actionStart:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:startButton];
    startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [startButton.widthAnchor constraintEqualToConstant:300.0].active = YES;
    
    if ([self loadAuth] != nil) {
        UIButton *usePreviousAuthButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [usePreviousAuthButton setTitle:@"Continue With Previous Auth" forState:UIControlStateNormal];
        [usePreviousAuthButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [usePreviousAuthButton.titleLabel setFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]];
        [usePreviousAuthButton setBackgroundColor:[UIColor systemBlueColor]];
        usePreviousAuthButton.layer.cornerRadius = 25.0;
        [usePreviousAuthButton addTarget:self action:@selector(actionContinue:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:usePreviousAuthButton];
        usePreviousAuthButton.translatesAutoresizingMaskIntoConstraints = NO;
        [usePreviousAuthButton.widthAnchor constraintEqualToConstant:300.0].active = YES;
        
        UIButton *cleanPreviousAuthButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cleanPreviousAuthButton setTitle:@"Clean Previous Auth" forState:UIControlStateNormal];
        [cleanPreviousAuthButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [cleanPreviousAuthButton.titleLabel setFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]];
        [cleanPreviousAuthButton setBackgroundColor:[UIColor systemBlueColor]];
        cleanPreviousAuthButton.layer.cornerRadius = 25.0;
        [cleanPreviousAuthButton addTarget:self action:@selector(actionContinue:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:cleanPreviousAuthButton];
        cleanPreviousAuthButton.translatesAutoresizingMaskIntoConstraints = NO;
        [cleanPreviousAuthButton.widthAnchor constraintEqualToConstant:300.0].active = YES;
    }
}

- (void)actionStart:(id)sender
{
    PanBaiduNetdiskAuthViewController *authController = [PanBaiduNetdiskAuthViewController new];
    authController.delegate = self;
    __weak typeof (authController) weakAuthViewController = authController;
    [self presentViewController:authController animated:YES completion:^{
        [weakAuthViewController start];
    }];
}

- (void)actionContinue:(id)sender
{
    NSDictionary *savedAuth = [self loadAuth];
    [self showFolderContentWithAuth:savedAuth];
}

- (void)panBaiduNetdiskAuthViewController:(PanBaiduNetdiskAuthViewController *)viewController
                         didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof (self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }];
    });
}

- (void)panBaiduNetdiskAuthViewController:(PanBaiduNetdiskAuthViewController *)viewController
                       didSuccessWithAuth:(NSDictionary *)auth
{
    [self saveAuth:auth];
    [self showFolderContentWithAuth:auth];
}

- (void)showFolderContentWithAuth:(NSDictionary *)auth
{
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof (self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            NSString *userID = [auth objectForKey:PanBaiduNetdiskUserIDKey];
            PanBaiduNetdiskAPIClient *client = [PanBaiduNetdiskHelper createClientWithAuthData:auth];
            
            FolderContentViewController *contentViewController = [FolderContentViewController new];
            contentViewController.client = client;
            contentViewController.userID = userID;
            
            LSOnlineFile *rootFile = [[LSOnlineFile alloc] init];
            rootFile.url = [NSURL fileURLWithPath:@"/"];
            rootFile.directory = YES;
            contentViewController.rootDirectory = rootFile;
            
            UINavigationController *flowNavigationController =
            [[UINavigationController alloc] initWithRootViewController:contentViewController];
            [flowNavigationController setToolbarHidden:NO];
            [weakSelf presentViewController:flowNavigationController
                                   animated:YES
                                 completion:nil];
        }];
    });
}

- (void)saveAuth:(NSDictionary *)authDictionary
{
    if (authDictionary) {
        NSParameterAssert([authDictionary objectForKey:PanBaiduNetdiskAccessTokenDataKey]);
        NSParameterAssert([authDictionary objectForKey:PanBaiduNetdiskUserIDKey]);
        NSParameterAssert([authDictionary objectForKey:PanBaiduNetdiskUserNameKey]);
        [[NSUserDefaults standardUserDefaults] setObject:authDictionary forKey:kViewControllerPanBaiduNetdiskAuthKey];
    }
    else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kViewControllerPanBaiduNetdiskAuthKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (nullable NSDictionary *)loadAuth
{
    NSDictionary *authDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:kViewControllerPanBaiduNetdiskAuthKey];
    if (authDictionary == nil) {
        return nil;
    }
    
    NSParameterAssert([authDictionary objectForKey:PanBaiduNetdiskAccessTokenDataKey]);
    NSParameterAssert([authDictionary objectForKey:PanBaiduNetdiskUserIDKey]);
    NSParameterAssert([authDictionary objectForKey:PanBaiduNetdiskUserNameKey]);
    
    if ([authDictionary objectForKey:PanBaiduNetdiskAccessTokenDataKey]) {
        return authDictionary;
    }
    return nil;
}

@end
