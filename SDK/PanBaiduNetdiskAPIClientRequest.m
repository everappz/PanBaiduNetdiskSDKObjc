//
//  PanBaiduNetdiskAPIClientRequest.m
//  PanBaiduNetdiskSDKObjc
//
//  Created by Artem on 3/2/21.
//

#import "PanBaiduNetdiskAPIClientRequest.h"

@interface PanBaiduNetdiskAPIClientRequest(){
    BOOL _сancelled;
}

@property (nonatomic, strong) NSRecursiveLock *lock;

@end



@implementation PanBaiduNetdiskAPIClientRequest

- (instancetype)initWithInternalRequest:(id<PanBaiduNetdiskAPIClientCancellableRequest> _Nullable)internalRequest{
    self = [super init];
    if(self){
        self.internalRequest = internalRequest;
        self.lock = [NSRecursiveLock new];
    }
    return self;
}

- (void)cancel{
    [self.internalRequest cancel];
    [self.lock lock];
    _сancelled = YES;
    [self.lock unlock];
}

- (BOOL)isCancelled{
    BOOL flag = NO;
    [self.lock lock];
    flag = _сancelled;
    [self.lock unlock];
    return flag;
}

@end

