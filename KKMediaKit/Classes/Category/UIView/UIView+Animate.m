//
//  UIView+Animate.m
//  YiDian
//
//  Created by kkfinger on 2018/12/14.
//  Copyright © 2018 kkfinger. All rights reserved.
//

#import "UIView+Animate.h"

@implementation UIView(Animate)

+ (void)bounceIndicator:(CALayer *)indicator duration:(CGFloat)duration{
//    CGSize size = indicator.bounds.size;
//    
//    NSMutableArray *values = [NSMutableArray array];
//    CGFloat maxWidth = size.width;
//    CGFloat firstDamp = 1.0 - size.width / maxWidth;
//    CGFloat drift = size.width * firstDamp * -1.0;
//    for (NSInteger i = 0; i < duration / 0.15; i ++) {
//        [values addObject:[NSValue valueWithCGRect:CGRectMake(0, 0, size.width + drift, size.height)]];
//    }
//    // 最后状态
//    [values addObject:[NSValue valueWithCGRect:CGRectMake(0, 0, size.width, size.height)]];
//    CAKeyframeAnimation *keyanim = [CAKeyframeAnimation animation];
//    keyanim.keyPath = @"bounds";
//    keyanim.values = values;
//    keyanim.removedOnCompletion = NO;
//    keyanim.fillMode = kCAFillModeForwards;
//    keyanim.duration = bounceDuration;
//    keyanim.beginTime = [indicator convertTime:CACurrentMediaTime() fromLayer:nil] + duration * 0.25;
//    keyanim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
//    
//    [indicator addAnimation:keyanim forKey:nil];
}

@end
