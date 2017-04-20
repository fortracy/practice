//
//  ImageUtils.m
//  practicework
//
//  Created by bleach on 16/6/26.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage *)composeImage:(NSArray *)images {
    if (images.count == 0) {
        return nil;
    }
    
    if (images.count == 1) {
        return [images objectAtIndex:0];
    }

    @autoreleasepool {
        CGSize imageSize = ((UIImage *)[images objectAtIndex:0]).size;
        CGFloat composeWidth = 0.0f;
        CGFloat composeHeight = imageSize.height;
        for (UIImage * image in images) {
            if (!CGSizeEqualToSize(imageSize, image.size)) {
                //合成需要是相等宽高的图片
                return nil;
            }
            composeWidth += image.size.width + 2.0f;
        }
        CGSize size = CGSizeMake(composeWidth, composeHeight);
        UIGraphicsBeginImageContext(size);
        
        NSUInteger index = 0;
        for (UIImage * image in images) {
            [image drawInRect:CGRectMake(index * (imageSize.width + 2.0f) + 1.0f, 0.0f, imageSize.width, imageSize.height)];
            index++;
        }
        
        UIImage * resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resultImage;
    }
}

@end
