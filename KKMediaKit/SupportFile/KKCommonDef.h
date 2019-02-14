//
//  KKCommonDef.h
//  KKPhotoKit
//
//  Created by kkfinger on 2019/2/12.
//  Copyright © 2019 kkfinger. All rights reserved.
//

#ifndef KKCommonVariable_h
#define KKCommonVariable_h

#import <UIKit/UIKit.h>

#define IOS11_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"11.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS10_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS9_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS8_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS7_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS6_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS5_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS4_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"4.0" options:NSNumericSearch] != NSOrderedAscending )
#define IOS3_OR_LATER        ( [[[UIDevice currentDevice] systemVersion] compare:@"3.0" options:NSNumericSearch] != NSOrderedAscending )

#define IOS10_OR_EARLIER    ( !IOS11_OR_LATER )
#define IOS9_OR_EARLIER        ( !IOS10_OR_LATER )
#define IOS8_OR_EARLIER        ( !IOS9_OR_LATER )
#define IOS7_OR_EARLIER        ( !IOS8_OR_LATER )
#define IOS6_OR_EARLIER        ( !IOS7_OR_LATER )
#define IOS5_OR_EARLIER        ( !IOS6_OR_LATER )
#define IOS4_OR_EARLIER        ( !IOS5_OR_LATER )
#define IOS3_OR_EARLIER        ( !IOS4_OR_LATER )

//判断设备类型
#define iPhone4 ([UIScreen mainScreen].bounds.size.height == 480)
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size)) : NO)
#define iPhonePlus ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1125, 2001), [[UIScreen mainScreen] currentMode].size) || CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size)) : NO)
#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhoneXs ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhoneXsMax ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhoneXr ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1624), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhoneXSeries (iPhoneX || iPhoneXs || iPhoneXsMax || iPhoneXr)

//iPhoneX、iPhoneXS、iPhoneXsMax、iPhoneXR适配
#define KKStatusBarHeight (iPhoneXSeries ? 44 : 20)
#define KKNavBarHeight (iPhoneXSeries ? 88 : 64)
#define KKSafeAreaBottomHeight (iPhoneXSeries ? 34 : 0)
#define KKTabbarHeight (iPhoneXSeries ? 83 : 49)

#define KKAdjustsScrollViewInsets(scrollView)\
do {\
_Pragma("clang diagnostic push")\
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"")\
if ([scrollView respondsToSelector:NSSelectorFromString(@"setContentInsetAdjustmentBehavior:")]) {\
NSMethodSignature *signature = [UIScrollView instanceMethodSignatureForSelector:@selector(setContentInsetAdjustmentBehavior:)];\
NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];\
NSInteger argument = 2;\
invocation.target = scrollView;\
invocation.selector = @selector(setContentInsetAdjustmentBehavior:);\
[invocation setArgument:&argument atIndex:2];\
[invocation retainArguments];\
[invocation invoke];\
}\
_Pragma("clang diagnostic pop")\
} while (0)

//颜色相关
#define KKColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define randomColorValue arc4random_uniform(256)
#define KKRandomColor [UIColor colorWithRed:(randomColorValue)/255.0 green:(randomColorValue)/255.0 blue:(randomColorValue)/255.0 alpha:1.0]
#define rgba(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

#define UIDeviceScreenSize   [[UIScreen mainScreen] bounds].size
#define UIDeviceScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define UIDeviceScreenHeight [[UIScreen mainScreen] bounds].size.height

#define KKKeyWindow [[UIApplication sharedApplication]keyWindow]

/* 外边距、内边距 */
//外边距
static float const KKMarginSuper = 70.f;
static float const KKMarginMax = 55.f;
static float const KKMarginHuge = 45.f;
static float const KKMarginLarge = 40.f;
static float const KKMarginNormal = 30.f;
static float const KKMarginSmall = 20.f;
static float const KKMarginMin = 15.f;
static float const KKMarginTiny = 10.f;
//内边距
static float const KKPaddingSuper = 30.f;
static float const KKPaddingMax = 25.f;
static float const KKPaddingHuge = 20.f;
static float const KKPaddingLarge = 15.f;
static float const KKPaddingNormal = 10.f;
static float const KKPaddingSmall = 5.f;
static float const KKPaddingMin = 4.f;
static float const KKPaddingTiny = 2.f;

/* 图标、头像尺寸 */
//图标
static CGSize const KKIconSizeSuper = (CGSize){37.f, 37.f};
static CGSize const KKIconSizeMax = (CGSize){33.f, 33.f};
static CGSize const KKIconSizeHuge = (CGSize){27.f, 27.f};
static CGSize const KKIconSizeLarge = (CGSize){24.f, 24.f};
static CGSize const KKIconSizeNormal = (CGSize){22.f, 22.f};
static CGSize const KKIconSizeSmall = (CGSize){20.f, 20.f};
static CGSize const KKIconSizeMin = (CGSize){18.f, 18.f};
static CGSize const KKIconSizeTiny = (CGSize){15.f, 15.f};
static CGSize const KKIconSizeMinimum = (CGSize){12.f, 12.f};
//图片/头像
static CGSize const KKImageSizeSuper = (CGSize){105.f, 105.f};
static CGSize const KKImageSizeMax = (CGSize){90.f, 90.f};
static CGSize const KKImageSizeHuge = (CGSize){75.f, 75.f};
static CGSize const KKImageSizeLarge = (CGSize){62.f, 62.f};
static CGSize const KKImageSizeNormal = (CGSize){45.f, 45.f};
static CGSize const KKImageSizeSmall = (CGSize){42.f, 42.f};
static CGSize const KKImageSizeMin = (CGSize){40.f, 40.f};
static CGSize const KKImageSizeTiny = (CGSize){30.f, 30.f};
static CGSize const KKImageSizeMinimum = (CGSize){25.f, 25.f};

#endif /* TKKCommonVariable_h */
