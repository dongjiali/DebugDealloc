//
//  UINavigationController+HCDebugDealloc.m
//  HealthCrowdfunding
//
//  Created by Curry on 16/3/31.
//  Copyright © 2016年 Curry. All rights reserved.
//

#import "UINavigationController+HCDebugDealloc.h"
#import <objc/runtime.h>

static const void *viewControllerListKey = &viewControllerListKey;

@implementation AKTestBlock
{
    EmptyBlock  _deallocBlock;
}
- (void)dealloc
{
    if (_deallocBlock) _deallocBlock(self.viewControllerName);
}

- (void)setDeallocBlock:(EmptyBlock)deallocBlock
{
    _deallocBlock = deallocBlock;
}
@end


@implementation UINavigationController(HCDebugDealloc)
@dynamic viewControllerList;

- (NSMutableArray *)viewControllerList
{
    return objc_getAssociatedObject(self, viewControllerListKey);
}

- (void)setViewControllerList:(NSMutableArray *)viewControllerList
{
    objc_setAssociatedObject(self, viewControllerListKey, viewControllerList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)loadPopViewController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(popViewControllerAnimated:);
        SEL swizzledSelector = @selector(hc_popViewControllerAnimated:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)hc_popViewControllerAnimated:(BOOL)animated
{
    [self getPopViewControllerName];
    [self hc_popViewControllerAnimated:animated];
}

- (void)getPopViewControllerName
{
    NSString *popVCName =  NSStringFromClass([self.viewControllers.lastObject
                                              class]);
    if ([[self popViewControllerArray]count]>5) {
        [self checkUnPopViewClassName];
    }
    
    if([[self popViewControllerArray] indexOfObject:popVCName] == NSNotFound) {
        [[self popViewControllerArray] addObject:popVCName];
    }
    
    AKTestBlock *vcBlock = [[AKTestBlock alloc] init];
    vcBlock.viewControllerName = [popVCName copy];
    __weak typeof(self) weakSelf = self;
    [vcBlock setDeallocBlock:^(NSString *name) {
        if ([name isEqualToString:[[weakSelf popViewControllerArray] lastObject]]) {
            [[weakSelf popViewControllerArray] removeLastObject];
            if ([[weakSelf popViewControllerArray] count]>0) {
                [weakSelf checkUnPopViewClassName];
            }
        }
    }];
    void *ptr = ((__bridge void *)vcBlock);
    objc_setAssociatedObject(self.viewControllers.lastObject, ptr, vcBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)checkUnPopViewClassName
{
    NSMutableString *string = [[NSMutableString alloc]initWithCapacity:1];
    for (NSString *str in self.viewControllerList) {
        [string appendFormat:@"%@，",str];
    }
    [[[UIAlertView alloc] initWithTitle:@"亲，可能有ViewContrller没有释放" message:string delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil]show];
}

- (NSMutableArray *)popViewControllerArray
{
    if (!self.viewControllerList) {
        self.viewControllerList = [[NSMutableArray alloc]initWithCapacity:1];
    }
    return self.viewControllerList;
}
@end

