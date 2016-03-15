//
//  UIImage+OCR.h
//  icc
//
//  Created by Hua Xiong on 16/3/15.
//
//

#import <Foundation/Foundation.h>

@interface UIImage(OCR)
- (UIImage *)ico_number_ocr_image_threshold:(int)threshold;
- (UIImage *)ico_ocr_image_threshold:(int)threshold;
@end
