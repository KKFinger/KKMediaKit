//
//  UIImage+Extend.m
//  KKPhotoKit
//
//  Created by finger on 2017/8/6.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "UIImage+Extend.h"
#import "KKPhotoKitDef.h"

@implementation UIImage(Extend)

#pragma mark -- 图片透明度

- (UIImage *)imageWithAlpha:(float)theAlpha
{
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height) blendMode:kCGBlendModeNormal alpha:theAlpha];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark -- 图片填充颜色

+ (UIImage *)imageWithColor:(UIColor *)color {
    return [self imageWithColor:color size:CGSizeMake(1, 1)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark -- 图片圆角

- (UIImage*)imageWithCornerRadius:(CGFloat)radius{
    
    CGRect rect = (CGRect){0.f,0.f,self.size};

    // void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);
    //size——同UIGraphicsBeginImageContext,参数size为新创建的位图上下文的大小
    //    opaque—透明开关，如果图形完全不用透明，设置为YES以优化位图的存储。
    //    scale—–缩放因子
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [UIScreen mainScreen].scale);

    //根据矩形画带圆角的曲线
    CGContextAddPath(UIGraphicsGetCurrentContext(), [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius].CGPath);

    [self drawInRect:rect];

    //图片缩放，是非线程安全的
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();

    //关闭上下文
    UIGraphicsEndImageContext();

    return image;
}

- (UIImage *)scaleWithFactor:(float)scaleFloat quality:(CGFloat)compressionQuality
{
    CGSize size = CGSizeMake(self.size.width * scaleFloat, self.size.height * scaleFloat);
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    transform = CGAffineTransformScale(transform, scaleFloat, scaleFloat);
    CGContextConcatCTM(context, transform);
    
    [self drawAtPoint:CGPointMake(0.0f, 0.0f)];
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imagedata = UIImageJPEGRepresentation(newimg,compressionQuality);
    
    return [UIImage imageWithData:imagedata] ;
}

- (UIImage *)circleImage{
    CGFloat imageWH = MIN(self.size.width,self.size.height);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageWH, imageWH), NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if(!ctx){
        return nil ;
    }
    CGRect rect = CGRectMake(0, 0, imageWH, imageWH);
    CGContextAddEllipseInRect(ctx, rect);
    CGContextClip(ctx);
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Create a UIImage from sample buffer data
+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //锁定像素缓冲区的起始地址
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    //获取每行像素的字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    //获取像素缓冲区的宽度和高度
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //创建基于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace){
        NSLog(@"CGColorSpaceCreateDeviceRGB failure");
        return nil;
    }
    
    //获取像素缓冲区的起始地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    //获取像素缓冲区的数据大小
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    //使用提供的数据创建CGDataProviderRef
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize,NULL);
    
    //通过CGDataProviderRef，创建CGImageRef
    CGImageRef cgImage =
    CGImageCreate(width,
                  height,
                  8,
                  32,
                  bytesPerRow,
                  colorSpace,
                  kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  provider,
                  NULL,
                  true,
                  kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    //创建UIImage
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    //解锁像素缓冲区起始地址
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

+(UIImage *)stretchableImageWithImgae:(UIImage *)image{
    CGFloat w = image.size.width * 0.5;
    CGFloat h = image.size.height * 0.5;
    return [image stretchableImageWithLeftCapWidth:w topCapHeight:h];
}

+ (UIImage *)image:(UIImage *)image scaleToWidth:(CGFloat)width{
    
    // 如果传入的宽度比当前宽度还要大,就直接返回
    
    if (width > image.size.width) {
        return  image;
    }
    
    // 计算缩放之后的高度
    CGFloat height = (width / image.size.width) * image.size.height;
    
    // 初始化要画的大小
    CGRect  rect = CGRectMake(0, 0, width, height);
    
    // 1. 开启图形上下文
    UIGraphicsBeginImageContext(rect.size);
    
    // 2. 画到上下文中 (会把当前image里面的所有内容都画到上下文)
    [image drawInRect:rect];
    
    // 3. 取到图片
    
    UIImage *rstImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 4. 关闭上下文
    UIGraphicsEndImageContext();
    // 5. 返回
    return rstImage;
}

+ (UIImage *)compressImage:(UIImage *)image quality:(CGFloat)quality size:(CGSize)size{
    if(CGSizeEqualToSize(size, CGSizeZero)){
        size = UIDeviceScreenSize;
    }
    CGFloat hfactor = image.size.width / size.width;
    CGFloat vfactor = image.size.height / size.height;
    CGFloat factor = fmax(hfactor, vfactor);
    //画布大小
    CGFloat newWith = image.size.width / factor;
    CGFloat newHeigth = image.size.height / factor;
    CGSize newSize = CGSizeMake(newWith, newHeigth);
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newWith,newHeigth)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //图像压缩
    NSData *newImageData = UIImageJPEGRepresentation(newImage,quality);
    
    return [UIImage imageWithData:newImageData];
}

+ (NSData *)compressImage:(UIImage *)image toByte:(NSUInteger)toBytes quality:(CGFloat)quality{
    if(!image){
        return nil ;
    }
    if(quality < 0){
        quality = 0 ;
    }
    if(quality > 1){
        quality = 1 ;
    }
    
    NSData *data = UIImageJPEGRepresentation(image, quality);
    if (data.length < toBytes) {
        return data;
    }
    
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 10; ++i) {
        quality = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, quality);
        NSInteger dataLength = data.length;
        if (dataLength < toBytes * 0.9) {
            min = quality;
        } else if (dataLength > toBytes) {
            max = quality;
        } else {
            break;
        }
    }
    if (data.length < toBytes) {
        return data;
    }
    
    if(!data){
        return nil ;
    }
    
    // Compress by size
    NSUInteger lastDataLength = 0;
    UIImage *resultImage = [UIImage imageWithData:data];
    if(!resultImage){
        return nil ;
    }
    while (data.length > toBytes && data.length != lastDataLength) {
        lastDataLength = data.length;
        CGFloat ratio = (CGFloat)toBytes / data.length;
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                 (NSUInteger)(resultImage.size.height * sqrtf(ratio))); // Use NSUInteger to prevent white blank
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        data = UIImageJPEGRepresentation(resultImage, quality);
    }
    
    return data;
}

@end
