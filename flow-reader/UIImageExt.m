//
//  UIImageExt.m
//  flow-reader
//
//  Created by Mikhno Sergey (Galexis) on 20.12.19.
//  Copyright © 2019 Sergey Mikhno. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIImageExt.h"

@implementation UIImage (G8FixOrientation)

- (UIImage *)fixOrientation
{
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;

    UIImage *result;

    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);

    [self drawInRect:(CGRect){0, 0, self.size}];
    result = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return result;
}

@end
