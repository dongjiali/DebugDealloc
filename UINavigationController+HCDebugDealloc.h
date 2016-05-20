//
//  UINavigationController+HCDebugDealloc.h
//  HealthCrowdfunding
//
//  Created by Curry on 16/3/31.
//  Copyright © 2016年 Curry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^EmptyBlock)(NSString *name);

@interface AKTestBlock : NSObject
@property (nonatomic, copy) NSString  *viewControllerName;
- (void)setDeallocBlock:(EmptyBlock)deallocBlock;
@end


@interface UINavigationController(HCDebugDealloc)
@property (nonatomic, strong) NSMutableArray    *viewControllerList;
+ (void)loadPopViewController;
@end
