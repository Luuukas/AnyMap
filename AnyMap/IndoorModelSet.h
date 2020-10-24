//
//  IndoorModelSet.h
//  AnyMap
//
//  Created by bytedance on 2020/10/18.
//  Copyright © 2020 hwl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSLocation: NSObject
@property(nonatomic) CGFloat longitude;
@property(nonatomic) CGFloat latitude;

@property (nonatomic) NSUInteger myHash;
- (NSUInteger)hash;

- (BOOL)isEqual:(MSLocation*)object;


- (id)copyWithZone:(NSZone *)zone;

- (instancetype)initWithLongitude:(CGFloat)lo latitude:(CGFloat)la;
- (BOOL)isIncludedAtLongitude:(CGFloat)lo AtLatitude:(CGFloat)la WithRadius:(CGFloat)r;
@end

@interface IndoorModelSet : NSObject
- (instancetype)initWithModelsList:(NSString*)modelsList;
- (BOOL)hasModelsAtLongitude:(CGFloat)longitude Latitude:(CGFloat)latitude withRadius:(CGFloat)radius;
- (NSDictionary<MSLocation*, SCNSceneSource*>*)modelsAtLongitude:(CGFloat)longitude Latitude:(CGFloat)latitude withRadius:(CGFloat)radius;
- (NSDictionary<MSLocation*, SCNSceneSource*>*)modelsForJustAsk;

@end

NS_ASSUME_NONNULL_END
