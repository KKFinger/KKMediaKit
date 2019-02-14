//
//  UIImage+Extend.h
//  KKPhotoKit
//
//  Created by finger on 2017/8/6.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIImage+Extend.h"

@interface UIImage(UIImage)

#pragma mark -- 图片透明度

- (UIImage *)imageWithAlpha:(float)theAlpha;

#pragma mark -- 图片填充颜色

+ (UIImage *)imageWithColor:(UIColor *)color;

#pragma mark -- 图片圆角

- (UIImage*)imageWithCornerRadius:(CGFloat)radius;

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

#pragma mark -- 圆角图片

- (UIImage *)circleImage;

//图片压缩
- (UIImage *)scaleWithFactor:(float)scaleFloat quality:(CGFloat)compressionQuality;

// Create a UIImage from sample buffer data
+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

//可拉伸的图片
+(UIImage *)stretchableImageWithImgae:(UIImage *)image;

//重置图片大小
+ (UIImage *)image:(UIImage *)image scaleToWidth:(CGFloat)width;

//压缩图片大小
+ (UIImage *)compressImage:(UIImage *)image quality:(CGFloat)quality size:(CGSize)size;

//将图片压缩至指定的数据量大小
+ (NSData *)compressImage:(UIImage *)image toByte:(NSUInteger)toBytes quality:(CGFloat)quality;

@end
