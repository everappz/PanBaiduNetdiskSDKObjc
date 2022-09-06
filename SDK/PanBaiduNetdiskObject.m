//
//  PanBaiduNetdiskObject.m
//  MyCloudHomeSDKObjc
//
//  Created by Artem on 10/19/19.
//  Copyright © 2019 Everappz. All rights reserved.
//

#import "PanBaiduNetdiskObject.h"
#import "PanBaiduNetdiskConstants.h"

@interface NSDictionary (PanBaiduNetdiskAdditions)

- (nullable id)PanBaiduNetdiskObjectForKey:(nonnull id)aKey withClass:(nonnull Class)classObj;

@end

@interface PanBaiduNetdiskObject()

@property (nonatomic,strong)NSDictionary *dictionary;

@end

@implementation PanBaiduNetdiskObject

- (instancetype)initWithDictionary:(NSDictionary *_Nonnull)dictionary{
    if(dictionary==nil){
        return nil;
    }
    self = [super init];
    if(self){
        self.dictionary = dictionary;
    }
    return self;
}

@end


@implementation PanBaiduNetdiskObject (Parsing)

+ (NSURL *)HTTPURLForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary{
    NSParameterAssert(key);
    NSParameterAssert(dictionary);
    NSURL *resultURL = nil;
    if(dictionary && key){
        NSString *URLString = [self stringForKey:key inDictionary:dictionary];
        if([URLString hasPrefix:@"http"]){
            resultURL = [NSURL URLWithString:URLString];
        }
    }
    return resultURL;
}

+ (NSString *)stringForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary{
    NSParameterAssert(key);
    NSParameterAssert(dictionary);
    NSString *result = [dictionary PanBaiduNetdiskObjectForKey:key withClass:[NSString class]];
    return result;
}

+ (NSDictionary *)dictionaryForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary{
    NSParameterAssert(key);
    NSParameterAssert(dictionary);
    NSDictionary *result = [dictionary PanBaiduNetdiskObjectForKey:key withClass:[NSDictionary class]];
    return result;
}

+ (NSNumber *)numberForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary{
    NSParameterAssert(key);
    NSParameterAssert(dictionary);
    NSNumber *result = [dictionary PanBaiduNetdiskObjectForKey:key withClass:[NSNumber class]];
    return result;
}

+ (NSArray<NSDictionary *> *)arrayForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary{
    NSParameterAssert(key);
    NSParameterAssert(dictionary);
    NSArray<NSDictionary *> *result = nil;
    if(dictionary && key){
        NSArray *obj = [dictionary PanBaiduNetdiskObjectForKey:key withClass:[NSArray class]];
        if([obj isKindOfClass:[NSArray class]] && ([[(NSArray *)obj firstObject] isKindOfClass:[NSDictionary class]] || [(NSArray *)obj count]==0)){
            result = obj;
        }
    }
    return result;
}

@end



@implementation NSDictionary (PanBaiduNetdiskAdditions)

- (nullable id)PanBaiduNetdiskObjectForKey:(nonnull id)aKey withClass:(nonnull Class)classObj{
    
    if(aKey==nil || classObj==nil){
        return nil;
    }
    
    id obj = [self objectForKey:aKey];
    
    if(obj==nil){
        return nil;
    }
    
    if([obj isKindOfClass:classObj]){
        return obj;
    }
    
    @try {
        NSString *stringObject = nil;
        NSNumber *numberObject = nil;
        NSDate *dateObject = nil;
        NSURL *urlObject = nil;
        NSData *dataObject = nil;
        NSString *stringFromDataObject = nil;
        
        if([obj isKindOfClass:[NSString class]]){
            stringObject = obj;
        }
        else if([obj isKindOfClass:[NSNumber class]]){
            numberObject = obj;
        }
        else if([obj isKindOfClass:[NSURL class]]){
            urlObject = obj;
        }
        else if([obj isKindOfClass:[NSData class]]){
            dataObject = obj;
        }
        else if([obj isKindOfClass:[NSDate class]]){
            dateObject = obj;
        }
        
        if(dataObject!=nil){
            stringFromDataObject = [[NSString alloc] initWithData:dataObject encoding:NSUTF8StringEncoding];
        }
        
        stringObject = (stringObject!=nil)?stringObject:stringFromDataObject;
        
        if(classObj==[NSString class]){
            if(stringObject!=nil){
                return stringObject;
            }
            else if(numberObject!=nil){
                return [numberObject stringValue];
            }
            else if(urlObject!=nil){
                return urlObject.absoluteString;
            }
            else if(dateObject!=nil){
                NSParameterAssert(NO);
                return nil;
            }
        }
        else if(classObj==[NSNumber class]){
            if(stringObject!=nil){
                if([stringObject rangeOfString:@"."].location!=NSNotFound){
                    return @([stringObject floatValue]);
                }
                else{
                    return @([stringObject integerValue]);
                }
            }
            else if(numberObject!=nil){
                return numberObject;
            }
            else if(dateObject!=nil){
                return @([dateObject timeIntervalSince1970]);
            }
        }
        else if(classObj==[NSURL class]){
            if(stringObject!=nil && [stringObject isKindOfClass:[NSString class]] &&  stringObject.length>0){
                NSURL *url = nil;
                @try {url = [[NSURL alloc] initWithString:stringObject];} @catch (NSException *exception) {}
                return url;
            }
            else if(urlObject!=nil){
                return urlObject;
            }
        }
        else if(classObj==[NSData class]){
            if(stringObject!=nil){
                return [stringObject dataUsingEncoding:NSUTF8StringEncoding];
            }
            else if(urlObject!=nil){
                return [urlObject.absoluteString dataUsingEncoding:NSUTF8StringEncoding];
            }
            else if(numberObject!=nil){
                return [numberObject.stringValue dataUsingEncoding:NSUTF8StringEncoding];
            }
            else if(dateObject!=nil){
                NSParameterAssert(NO);
                return nil;
            }
        }
        else if(classObj==[NSDate class]){
            if (stringObject!=nil) {
                NSParameterAssert(NO);
                return nil;
            }
            else if(numberObject!=nil){
                NSTimeInterval ti = [numberObject doubleValue];
                NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:ti];
                return date;
            }
        }
        
    } @catch (NSException *exception) {}
    
    NSParameterAssert(NO);
    return nil;
}

@end

