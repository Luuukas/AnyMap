//
//  IndoorDestinationSet.m
//  AnyMap
//
//  Created by bytedance on 2020/10/18.
//  Copyright © 2020 hwl. All rights reserved.
//

#import "IndoorDestinationSet.h"
#include <math.h>

@interface IndoorDestinationSet ()
@property(nonatomic,strong)NSDictionary *destionations;
@property(nonatomic,strong)NSDictionary *askedDestionations;
@end

@implementation IndoorDestinationSet
- (instancetype)initWithBuilding:(NSString*)name {
    if(self=[super init]) {
        NSString *fullName = [[NSString alloc] initWithFormat:@"building-%@", name];
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:fullName ofType:@"plist"];
        _destionations = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        _askedDestionations = [[NSDictionary alloc] init];
    }
    return self;
}
- (NSDictionary*)destinationsAroundX:(CGFloat)x AroundY:(CGFloat)y AroundZ:(CGFloat)z WithRadius:(CGFloat)r {
    NSMutableDictionary *tDic = [[NSMutableDictionary alloc] init];
    [_destionations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL * _Nonnull stop) {
        CGFloat _x = [[obj objectForKey:@"x"] doubleValue];
        CGFloat _y = [[obj objectForKey:@"y"] doubleValue];
        CGFloat _z = [[obj objectForKey:@"z"] doubleValue];
        if(sqrt(pow(_x - x, 2) + pow(_y - y, 2) + pow(_z - z, 2) <= pow(r, 2))){
            [tDic setValue:obj forKey:key];
        }
    }];
    return tDic;
}
- (NSDictionary*)whereIsDestination:(NSString*)dest {
    return [NSDictionary valueForKey:dest];
}
- (NSDictionary*)destinationsAtZ:(CGFloat)z {
    NSMutableDictionary *tDic = [[NSMutableDictionary alloc] init];
    [_destionations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL * _Nonnull stop) {
        CGFloat _z = [[obj objectForKey:@"z"] doubleValue];
        if(pow(z-_z, 2) <= 0.000001){
            [tDic setValue:obj forKey:key];
        }
    }];
    return tDic;
}
@end
