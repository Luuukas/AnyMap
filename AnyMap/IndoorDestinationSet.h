//
//  IndoorDestinationSet.h
//  AnyMap
//
//  Created by bytedance on 2020/10/18.
//  Copyright © 2020 hwl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IndoorDestinationSet : NSObject
- (instancetype)initWithBuilding:(NSString*)name;
- (NSDictionary*)destinationsAroundX:(CGFloat)x AroundY:(CGFloat)y AroundZ:(CGFloat)z WithRadius:(CGFloat)r;
- (NSDictionary*)whereIsDestination:(NSString*)dest;
- (NSDictionary*)destinationsAtZ:(CGFloat)z;
@end

NS_ASSUME_NONNULL_END
