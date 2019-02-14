//
//  KKAppTools.h
//  KKPhotoKit
//
//  Created by finger on 2017/9/20.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface KKAppTools : NSObject
#pragma mark -- 返回当前类的所有属性
+ (NSArray *)getProperties:(Class)cls;
#pragma mark -- 视图是push还是present显示的
+ (BOOL)isPushWithCtrl:(UIViewController *)ctrl;
#pragma mark -- 字节大小转换
+ (NSString*)formatSizeFromByte:(long long)bytes;
#pragma mark -- 时长转换
+ (NSString *)convertDurationToString:(NSTimeInterval)duration;
#pragma mark -- Unicode转码
+ (NSString*)replaceUnicode:(NSString*)unicodeString;
#pragma mark -- 生成as和cp,数据请求时会用到
+ (void)generateAs:(NSString **)asStr cp:(NSString **)cpStr;
#pragma mark -- md5加密
+ (NSString *)md5String:(NSString *)content;
#pragma mark -- 十进制转16进制
+ (NSString *)toHexString:(long long)tmpid;
#pragma mark -- 验证电话号码是否合法
+ (BOOL)isMobilePhone:(NSString *)number;
#pragma mark -- 打印二进制数据
+(NSString *)byteArrToStr:(Byte *)bytes length:(int)length;
#pragma mark -- 获取ctrl最顶层的present出来的控制器
+ (UIViewController *)presentedCttl:(UIViewController *)ctrl;
#pragma mark -- 获取ctrl最底层的present出来的控制器
+ (UIViewController *)presentingCttl:(UIViewController *)ctrl;
#pragma mark -- 跳转到设置界面
+ (void)jumpToAppSetting;
#pragma mark -- 权限检测
+ (BOOL)photoLibraryAuthorization;
+ (BOOL)cameraAuthorization;
+ (BOOL)microphoneAuthorization;
+ (BOOL)remoteNotificationAuthorization;
+ (BOOL)locationAuthorization;
#pragma mark -- base64编解码
+ (NSString *)imageToBase64Str:(UIImage *)image;
+ (UIImage *)base64StrToUIImage:(NSString *)encodedImageStr;
#pragma mark -- 字符串长度计算
+ (NSInteger)getStringLength:(NSString *)string;
#pragma mark -- rootController
+ (UIViewController *)rootController;
#pragma mark -- 图片格式
+ (NSString *)contentTypeForImageData:(NSData *)data;
#pragma mark -- plist文件读写
+ (void)saveToPlist:(NSString *)plistName key:(NSString *)key value:(id)value;
+ (id)queryPlist:(NSString *)plistName key:(NSString *)key;
+ (void)deletePlist:(NSString *)plistName;
+ (void)deletePlistKey:(NSString *)plistName key:(NSString *)key;
#pragma mark -- 字段转字符串
+ (NSString *)dictToJsonString:(id)object;
#pragma mark -- 文件名检查是否重复
+ (NSString *)checkFileName:(NSString *)parentFolder fileName:(NSString *)fileName;
#pragma mark -- 协议解析,提取参数
+ (NSDictionary *)parseUrlParam:(NSString *)url;
#pragma mark -- 创建导航栏上的按钮
+ (UIBarButtonItem *)createItemWithTitle:(NSString *)title imageName:(NSString *)imageName target:(id)target selector:(SEL)selector isLeft:(BOOL)isLeft;
+ (UIButton *)createButtonWithTitle:(NSString *)title imageName:(NSString *)imageName target:(id)target selector:(SEL)selector isLeft:(BOOL)isLeft;
@end
