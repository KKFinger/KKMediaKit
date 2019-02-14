//
//  KKAppTools.m
//  KKPhotoKit
//
//  Created by finger on 2017/9/20.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKAppTools.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <CoreLocation/CoreLocation.h>
#import "UIImage+Extend.h"

@implementation KKAppTools

#pragma mark -- 返回当前类的所有属性

+ (NSArray *)getProperties:(Class)cls{
    // 获取当前类的所有属性
    unsigned int count;// 记录属性个数
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    // 遍历
    NSMutableArray *mArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        // 获取属性的名称 C语言字符串
        const char *cName = property_getName(property);
        // 转换为Objective C 字符串
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        [mArray addObject:name];
    }
    
    return mArray.copy;
}

#pragma mark -- 跳转到设置界面

+ (void)jumpToAppSetting{
    NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if([[UIApplication sharedApplication] canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark -- 视图是push还是present显示的

+ (BOOL)isPushWithCtrl:(UIViewController *)ctrl{
    if ([ctrl respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        return NO;
    } else if ([ctrl.navigationController respondsToSelector:@selector(popViewControllerAnimated:)]) {
        return YES;
    }
    return YES ;
}

#pragma mark -- 字节大小转换

+ (NSString*)formatSizeFromByte:(long long)bytes{
    int multiplyFactor = 0;
    double convertedValue = bytes;
    NSArray *tokens = [NSArray arrayWithObjects:@"B",@"KB",@"MB",@"GB",@"TB",nil];
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    return [NSString stringWithFormat:@"%4.1f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

#pragma mark -- 时长转换

+ (NSString *)convertDurationToString:(NSTimeInterval)duration{
    NSInteger hour = duration / 3600;
    NSInteger minute = (duration - hour*3600) / 60;
    NSInteger seconds = (duration - hour *3600 - minute*60);
    NSString *strDuration  = @"";
    
    strDuration = [NSString stringWithFormat:@"%02ld:",hour];
    strDuration = [strDuration stringByAppendingFormat:@"%02ld:",minute];
    strDuration = [strDuration stringByAppendingFormat:@"%02ld",seconds];
    return strDuration;
}

#pragma mark -- Unicode转码

+ (NSString*)replaceUnicode:(NSString*)unicodeString{
    if(!unicodeString.length){
        return @"";
    }
    NSString*tempStr1 = [unicodeString stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString*tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString*tempStr3 = [[@"\"" stringByAppendingString:tempStr2]stringByAppendingString:@"\""];
    
    NSData*tepData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString*axiba = [NSPropertyListSerialization propertyListWithData:tepData options:NSPropertyListMutableContainers format:NULL error:NULL];
    
    return [axiba stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}

#pragma mark -- 生成as和cp,数据请求时会用到

+ (void)generateAs:(NSString **)asStr cp:(NSString **)cpStr{
    long long time = [[NSDate date]timeIntervalSince1970];
    NSString *key = [[self toHexString:time]uppercaseString];
    NSString *md5Key = [[self md5String:[NSString stringWithFormat:@"%lld",time]]uppercaseString];
    if (key.length != 8) {
        *asStr = @"479BB4B7254C150";
        *cpStr = @"7E0AC8874BB0985";
        return;
    } else {
        NSString *ascMd5 = [md5Key substringToIndex:5];
        NSString *descMd5 = [md5Key substringFromIndex:md5Key.length - 5];
        NSMutableString *as = [NSMutableString new];
        NSMutableString *cp = [NSMutableString new];
        
        for (int i=0; i<5; i++) {
            [as appendString:[ascMd5 substringWithRange:NSMakeRange(i, 1)]];
            [as appendString:[key substringWithRange:NSMakeRange(i, 1)]];
            [cp appendString:[key substringWithRange:NSMakeRange(i+3, 1)]];
            [cp appendString:[descMd5 substringWithRange:NSMakeRange(i, 1)]];
        }
        *asStr = [NSString stringWithFormat:@"A1%@%@",as,[key substringFromIndex:key.length-3]];
        *cpStr = [NSString stringWithFormat:@"%@%@E1",[key substringToIndex:3],cp];
    }
}

#pragma mark -- md5加密

+ (NSString *)md5String:(NSString *)content{
    const char *concat_str = [content UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(concat_str, strlen(concat_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
}

#pragma mark -- 十进制转16进制

+ (NSString *)toHexString:(long long)tmpid{
    NSString *nLetterValue;
    NSString *str =@"";
    uint16_t ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig){
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    return str;
}

#pragma mark -- 验证电话号码是否合法

+ (BOOL)isMobilePhone:(NSString *)number{
    if (number.length != 11){
        return NO;
    }
    /**
     * 手机号码:
     * 13[0-9], 14[5,7], 15[0, 1, 2, 3, 5, 6, 7, 8, 9], 17[0, 1, 6, 7, 8], 18[0-9]
     * 移动号段: 134,135,136,137,138,139,147,150,151,152,157,158,159,170,178,182,183,184,187,188
     * 联通号段: 130,131,132,145,155,156,170,171,175,176,185,186
     * 电信号段: 133,149,153,170,173,177,180,181,189
     */
    NSString *MOBILE = @"^1(3[0-9]|4[57]|5[0-35-9]|7[0135678]|8[0-9])\\d{8}$";
    
    /**
     * 中国移动：China Mobile
     * 134,135,136,137,138,139,147,150,151,152,157,158,159,170,178,182,183,184,187,188
     */
    NSString *CM = @"^1(3[4-9]|4[7]|5[0-27-9]|7[08]|8[2-478])\\d{8}$";
    
    /**
     * 中国联通：China Unicom
     * 130,131,132,145,155,156,170,171,175,176,185,186
     */
    NSString *CU = @"^1(3[0-2]|4[5]|5[56]|7[0156]|8[56])\\d{8}$";
    
    /**
     * 中国电信：China Telecom
     * 133,149,153,170,173,177,180,181,189
     */
    NSString *CT = @"^1(3[3]|4[9]|53|7[037]|8[019])\\d{8}$";
    
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    if (([regextestmobile evaluateWithObject:number] == YES)
        || ([regextestcm evaluateWithObject:number] == YES)
        || ([regextestct evaluateWithObject:number] == YES)
        || ([regextestcu evaluateWithObject:number] == YES)){
        return YES;
    }else{
        return NO;
    }
}

#pragma mark -- 打印二进制数据

+(NSString *)byteArrToStr:(Byte *)bytes length:(int)length {
     char *chars = malloc(length*8+1); chars[length*8] = '\0'; // c string end with '\0'
     for(int i=0;i<length;i++) {
         for(int j=0;j<8;j++) {
             chars[i*8+(7-j)] = ((bytes[i]>>j)&0x01) == 1 ? '1' : '0';
         }
     }
     NSString *string = [NSString stringWithCString:chars encoding:NSUTF8StringEncoding];
     free(chars);
     return string;
}

#pragma mark -- 获取ctrl最顶层的present出来的控制器

+ (UIViewController *)presentedCttl:(UIViewController *)ctrl{
    UIViewController *presentedCttl = ctrl ;
    while(presentedCttl.presentedViewController){
        presentedCttl = presentedCttl.presentedViewController;
    }
    return presentedCttl;
}

#pragma mark -- 获取ctrl最底层的present出来的控制器

+ (UIViewController *)presentingCttl:(UIViewController *)ctrl{
    UIViewController *presentingCttl = ctrl ;
    while(presentingCttl.presentingViewController){
        presentingCttl = presentingCttl.presentingViewController;
    }
    return presentingCttl;
}

#pragma mark -- 跳转到app设置

- (void)jumpToAppSetting{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

#pragma mark -- 权限检测

+ (BOOL)photoLibraryAuthorization{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted ||
        status == PHAuthorizationStatusDenied) {
        return NO ;
    }
    return YES ;
}

+ (BOOL)cameraAuthorization{
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted ||
        authStatus ==AVAuthorizationStatusDenied){
        return NO ;
    }
    return YES ;
}

+ (BOOL)microphoneAuthorization{
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusRestricted ||
        authStatus ==AVAuthorizationStatusDenied){
        return NO ;
    }
    return YES ;
}

+ (BOOL)remoteNotificationAuthorization{
    if([[UIApplication sharedApplication] currentUserNotificationSettings].types ==UIUserNotificationTypeNone) {
        return NO ;
    }
    return YES ;
}

+ (BOOL)locationAuthorization{
    if([CLLocationManager locationServicesEnabled] &&
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
        return NO ;
    }
    return YES ;
}

#pragma mark -- base64编解码

+ (NSString *)imageToBase64Str:(UIImage *)image{
    NSData *data = UIImageJPEGRepresentation(image, 1.0f);
    NSString *encodedImageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return encodedImageStr;
}

+ (UIImage *)base64StrToUIImage:(NSString *)encodedImageStr{
    NSData *decodedImageData = [[NSData alloc] initWithBase64EncodedString:encodedImageStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *decodedImage = [UIImage imageWithData:decodedImageData];
    return decodedImage;
}

#pragma mark -- 字符串长度计算

+ (NSInteger)getStringLength:(NSString *)string{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData* da = [string dataUsingEncoding:enc];
    return [da length];
}

#pragma mark -- 图片格式

//通过图片Data数据第一个字节 来获取图片扩展名
+ (NSString *)contentTypeForImageData:(NSData *)data{
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
        case 0x52:
            if ([data length] < 12) {
                return nil;
            }
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"webp";
            }
            return nil;
    }
    return nil;
}

#pragma mark -- plist文件读写

+ (void)saveToPlist:(NSString *)plistName key:(NSString *)key value:(id)value{
    if(!plistName.length){
        return ;
    }
    if(!key.length){
        return ;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *filePath = [path objectAtIndex:0];
    NSString *plistPath = [filePath stringByAppendingPathComponent:plistName];
    if(![fm fileExistsAtPath:plistPath]){
        [fm createFileAtPath:plistPath contents:nil attributes:nil];
        NSMutableDictionary *newsDict = [NSMutableDictionary dictionary];
        [newsDict writeToFile:plistPath atomically:YES];
    }
    NSMutableDictionary *plistInfos = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [plistInfos setObject:value forKey:key];
    [plistInfos writeToFile:plistPath atomically:YES];
}

+ (id)queryPlist:(NSString *)plistName key:(NSString *)key{
    if(!plistName.length){
        return nil;
    }
    if(!key.length){
        return nil;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *filePath = [path objectAtIndex:0];
    NSString *plistPath = [filePath stringByAppendingPathComponent:plistName];
    if(![fm fileExistsAtPath:plistPath]){
        [fm createFileAtPath:plistPath contents:nil attributes:nil];
        NSMutableDictionary *newsDict = [NSMutableDictionary dictionary];
        [newsDict writeToFile:plistPath atomically:YES];
    }
    NSMutableDictionary *plistInfos = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    return [plistInfos objectForKey:key];
}

+ (void)deletePlist:(NSString *)plistName{
    if(!plistName.length){
        return ;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *filePath = [path objectAtIndex:0];
    NSString *plistPath = [filePath stringByAppendingPathComponent:plistName];
    if([fm fileExistsAtPath:plistPath]){
        [fm removeItemAtPath:plistPath error:nil];
    }
}

+ (void)deletePlistKey:(NSString *)plistName key:(NSString *)key{
    if(!plistName.length){
        return;
    }
    if(!key.length){
        return;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *filePath = [path objectAtIndex:0];
    NSString *plistPath = [filePath stringByAppendingPathComponent:plistName];
    if(![fm fileExistsAtPath:plistPath]){
        [fm createFileAtPath:plistPath contents:nil attributes:nil];
        NSMutableDictionary *newsDict = [NSMutableDictionary dictionary];
        [newsDict writeToFile:plistPath atomically:YES];
    }
    NSMutableDictionary *plistInfos = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [plistInfos removeObjectForKey:key];
    [plistInfos writeToFile:plistPath atomically:YES];
}

+ (NSString *)dictToJsonString:(id)object{
    if(!object){
        return nil ;
    }
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

#pragma mark -- 文件名检查是否重复

+ (NSString *)checkFileName:(NSString *)parentFolder fileName:(NSString *)fileName{
    if(!parentFolder.length){
        return fileName;
    }
    if(!fileName.length){
        return fileName;
    }
    NSInteger index = 1 ;
    NSString *rstFileName = fileName;
    NSString *path = [parentFolder stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    while ([fileManager fileExistsAtPath:path]) {
        rstFileName = [NSString stringWithFormat:@"%@_%ld",fileName,index];
        path = [parentFolder stringByAppendingPathComponent:rstFileName];
        index ++ ;
    }
    return rstFileName;
}

#pragma mark -- 协议解析,提取参数

+ (NSDictionary *)parseUrlParam:(NSString *)url{
    if(!url.length){
        return nil ;
    }
    if(![url containsString:@"?"]){
        return nil ;
    }
    NSString *paramString = [[url componentsSeparatedByString:@"?"]lastObject];
    if(!paramString.length){
        return nil ;
    }
    NSMutableDictionary *dicInfo = [NSMutableDictionary new];
    NSArray *paramArray = [paramString componentsSeparatedByString:@"&"];
    for(NSString *str in paramArray){
        if(![str containsString:@"="]){
            continue ;
        }
        NSString *key = [[str componentsSeparatedByString:@"="]firstObject];
        NSString *value = [[str componentsSeparatedByString:@"="]lastObject];
        if(key.length && value.length){
            [dicInfo setObject:value forKey:key];
        }
    }
    return dicInfo ;
}

#pragma mark -- 创建导航栏上的按钮

+ (UIBarButtonItem *)createItemWithTitle:(NSString *)title imageName:(NSString *)imageName target:(id)target selector:(SEL)selector isLeft:(BOOL)isLeft{
    UIButton *backButton = [KKAppTools createButtonWithTitle:title imageName:imageName target:target selector:selector isLeft:isLeft];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    return backItem;
}

+ (UIButton *)createButtonWithTitle:(NSString *)title imageName:(NSString *)imageName target:(id)target selector:(SEL)selector isLeft:(BOOL)isLeft{
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.contentHorizontalAlignment = isLeft ? UIControlContentHorizontalAlignmentLeft : UIControlContentHorizontalAlignmentRight;
    backButton.frame = CGRectMake(0, 0, 60, 30);
    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    if (title != nil){
        [backButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:17.0]];
        [backButton setTitle:title forState:UIControlStateNormal];
        [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    if(imageName){
        [backButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [backButton setImage:[[UIImage imageNamed:imageName] imageWithAlpha:0.5] forState:UIControlStateHighlighted];
    }
    [backButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin];
    if(target && selector){
        [backButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    }
    return backButton;
}

@end

