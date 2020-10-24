//
//  IndoorModelSet.m
//  AnyMap
//
//  Created by bytedance on 2020/10/18.
//  Copyright © 2020 hwl. All rights reserved.
//

#import "IndoorModelSet.h"
#import <math.h>

@implementation MSLocation
- (id)copyWithZone:(NSZone *)zone
{
    id aCopy = [[[self class] alloc] initWithLongitude:_longitude latitude:_latitude];
    if (aCopy) {
        [aCopy setMyHash:self.myHash];
    }
    return aCopy;
}
- (instancetype)initWithLongitude:(CGFloat)lo latitude:(CGFloat)la {
    if(self = [super init]){
        _myHash = (NSUInteger)self;
        _longitude = lo;
        _latitude = la;
    }
    return self;
}
- (NSUInteger)hash
{
    return _myHash;
}
- (BOOL)isEqual:(MSLocation*)object
{
    return self.myHash == object.myHash;
}
- (BOOL)isIncludedAtLongitude:(CGFloat)lo AtLatitude:(CGFloat)la WithRadius:(CGFloat)r {
    return pow(_longitude - lo, 2) - pow(_latitude - la, 2) <= pow(r, 2);
}
@end

@interface IndoorModelSet ()
@property (nonatomic, strong)NSDictionary<MSLocation*, SCNSceneSource*>* models;
@property (nonatomic, strong)NSDictionary<MSLocation*, SCNSceneSource*>* askedModels;
@end

@implementation IndoorModelSet
- (instancetype)initWithModelsList:(NSString *)modelsList {
    if(self=[super init]) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:modelsList ofType:@"plist"];
        NSArray *array = [[NSArray alloc] initWithContentsOfFile:plistPath];
        
        NSMutableDictionary<MSLocation*, SCNSceneSource*>* mmodels = [[NSMutableDictionary alloc] init];
        for(NSDictionary* model in array){
            NSNumber *longitude = [model objectForKey:@"longitude"];
            NSNumber *latitude = [model objectForKey:@"latiitude"];
            MSLocation *location = [[MSLocation alloc] initWithLongitude:[longitude doubleValue] latitude:[latitude doubleValue]];
            NSString *name = [model objectForKey:@"name"];
            SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:[[NSBundle mainBundle] URLForResource:name withExtension:@".scn"] options:nil];
            [mmodels setObject:sceneSource forKey:location];
        }
        _models = mmodels;
        _askedModels = [[NSDictionary alloc] init];
    }
    return self;
}

- (NSDictionary<MSLocation*, SCNSceneSource*>* )modelsAtLongitude:(CGFloat)longitude Latitude:(CGFloat)latitude withRadius:(CGFloat)radius {
    NSMutableDictionary<MSLocation*, SCNSceneSource*>* tDic = [[NSMutableDictionary alloc] init];
    [_models enumerateKeysAndObjectsUsingBlock:^(MSLocation *key, SCNSceneSource *obj, BOOL *stop){
        if ([key isIncludedAtLongitude:longitude AtLatitude:latitude WithRadius:radius]) {
            [tDic setObject:obj forKey:key];
        }
    }];
    return tDic;
}

- (BOOL)hasModelsAtLongitude:(CGFloat)longitude Latitude:(CGFloat)latitude withRadius:(CGFloat)radius{
    _askedModels = [self modelsAtLongitude:longitude Latitude:latitude withRadius:radius];
    return [_askedModels count] > 0;
}

- (NSDictionary<MSLocation*, SCNSceneSource*>*)modelsForJustAsk {
    return _askedModels;
}
@end
