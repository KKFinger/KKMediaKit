//
//  UIImageView+URL.m
//  KKMedicalCircle
//
//  Created by kkfinger on 2018/5/15.
//  Copyright © 2018年 kkfinger. All rights reserved.
//

#import "UIImageView+URL.h"
#import <SDWebImageManager.h>
#import <ReactiveCocoa.h>
#import "UIImage+Extend.h"
#import <UIImageView+WebCache.h>

@implementation UIImageView(URL)

- (void)setImageWithUrl:(NSString *)url
            placeholder:(UIImage *)placeholder
            circleImage:(BOOL)circleImage
              animate:(BOOL)animate{
    if(!url.length){
        self.image = placeholder;
        return ;
    }
    SDImageCache *imageCache = [[SDWebImageManager sharedManager]imageCache];
    [imageCache queryCacheOperationForKey:url
                                     done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType)
    {
        if(image){
            self.image = image;
        }else{
            @weakify(self);
            [self sd_setImageWithURL:[NSURL URLWithString:url]
                    placeholderImage:placeholder
                           completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL)
            {
                @strongify(self);
                BOOL shouldStoreToDisk = (image != nil);
                UIImage *rstImage = image ;
                if(!rstImage){
                    rstImage = placeholder;
                }
                if(circleImage){
                    rstImage = [rstImage circleImage];
                }
                if(shouldStoreToDisk && imageURL.absoluteString.length){
                    [[SDImageCache sharedImageCache]storeImage:rstImage
                                                        forKey:imageURL.absoluteString
                                                    completion:nil];
                }else{
                    rstImage = placeholder;
                }
                self.image = rstImage ;
                
                if(animate){
                    self.alpha = 0.0;
                    [UIView transitionWithView:self
                                      duration:0.5
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{
                                        self.alpha = 1.0;
                                    }completion:^(BOOL finished) {
                                        
                                    }];
                }
            }];
        }
    }];
}

@end
