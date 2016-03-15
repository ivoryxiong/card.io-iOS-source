//
//  UIImage+OCR.m
//  icc
//
//  Created by Hua Xiong on 16/3/15.
//
//

#import "UIImage+OCR.h"
#include "opencv2/imgproc/imgproc_c.h"

@implementation UIImage(OCR)

- (UIImage *)ico_number_ocr_image_threshold:(int)threshold {
  IplImage* rgb_img = [self IplImageFromUIImage:self];
  IplImage* rgb_32f_img = cvCreateImage(cvGetSize(rgb_img),IPL_DEPTH_32F,rgb_img->nChannels);
  cvConvertScale(rgb_img, rgb_32f_img, 1.0/255.0, 0);
  IplImage* lab_img = cvCreateImage(cvGetSize(rgb_32f_img),IPL_DEPTH_32F,3);
  cvCvtColor(rgb_32f_img, lab_img, CV_BGR2Lab);
  [self remainBlackColor:lab_img];
  cvCvtColor(lab_img, rgb_32f_img, CV_Lab2RGB);
  cvReleaseImage(&lab_img);
  cvConvertScale(rgb_32f_img, rgb_img, 255, 0);
  
  IplImage* dst_img = cvCreateImage(cvGetSize(rgb_img),IPL_DEPTH_8U,1);
  cvCvtColor(rgb_img, dst_img, CV_RGB2GRAY);
  cvReleaseImage(&rgb_img);
  cvSmooth(dst_img, dst_img, CV_GAUSSIAN, 3, 0, 0, 0);
  
  [self removeSmallNoise:dst_img threshold:threshold];
  UIImage *img = [self UIImageFromIplImage:dst_img];
  cvReleaseImage(&dst_img);
  
  return img;
}

- (UIImage *)ico_ocr_image_threshold:(int)threshold {
  //!!!BGR
  IplImage* rgb_img = [self IplImageFromUIImage:self];
  IplImage* rgb_32f_img = cvCreateImage(cvGetSize(rgb_img),IPL_DEPTH_32F,rgb_img->nChannels);
  cvConvertScale(rgb_img, rgb_32f_img, 1.0/255.0, 0);
  IplImage* lab_img = cvCreateImage(cvGetSize(rgb_32f_img),IPL_DEPTH_32F,3);
  cvCvtColor(rgb_32f_img, lab_img, CV_BGR2Lab);
  [self remainBlackColor:lab_img];
  cvCvtColor(lab_img, rgb_32f_img, CV_Lab2RGB);
  cvReleaseImage(&lab_img);
  cvConvertScale(rgb_32f_img, rgb_img, 255, 0);
  
  IplImage* dst_img = cvCreateImage(cvGetSize(rgb_img),IPL_DEPTH_8U,1);
  cvCvtColor(rgb_img, dst_img, CV_RGB2GRAY);
  cvReleaseImage(&rgb_img);
  
  IplImage *ret_img = cvCreateImage(cvGetSize(dst_img),IPL_DEPTH_8U,1);
  cvAdaptiveThreshold(dst_img, ret_img, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 9, 11);
  cvReleaseImage(&dst_img);
  
  //  [self removeSmallNoise:ret_img threshold:threshold];
  UIImage *img = [self UIImageFromIplImage:ret_img];
  cvReleaseImage(&ret_img);
  
  return img;
}

- (void)remainBlackColor:(IplImage *)img {
  int width = img->width;
  int height = img->height;
  
  for(int r = 0; r < height; r++) {
    for(int c = 0; c < width; c++) {
      CvScalar s;
      s=cvGet2D(img,r,c); // get the (i,j) pixel value
      //distance to black
      double dis = s.val[0] * s.val[0] + s.val[1] * s.val[1] + s.val[2] * s.val[2];
      if (dis > 45 * 45) {
        s.val[0]=100;
        s.val[1]=0;
        s.val[2]=0;
        cvSet2D(img,r,c,s);
      }
    }
  }
}

- (void)removeSmallNoise:(IplImage *)img threshold:(int)threshold {
  int width = img->width;
  int height = img->height;
  
  NSMutableArray *sizes = [NSMutableArray array];
  for(int y = 0; y < height; y++) {
    for(int x = 0; x < width; x++) {
      uchar g = img->imageData[y * img->widthStep + x * img->nChannels];
      if (g == 0) {
        NSMutableSet *pixels = [NSMutableSet set];
        [self dfsImg:img atY:y atX:x blocks:pixels];
        [sizes addObject:@([pixels count])];
        if ([pixels count] < threshold) {
          for (NSNumber *idx in pixels) {
            img->imageData[[idx unsignedIntValue]] = 255;
          }
        }
      }
    }
  }
}

- (void)dfsImg:(IplImage *)img atY:(int)y atX:(int)x blocks:(NSMutableSet *)blocks {
  NSNumber *idx = @(y * img->widthStep + x * img->nChannels);
  uchar g = img->imageData[[idx unsignedIntValue]];
  
  if (g == 0 && ![blocks containsObject:idx]) {
    [blocks addObject:idx];
    for (int di = -1; di < 2; di += 2) {
      for (int dj = -1; dj < 2; dj += 2) {
        int ri = y + di;
        int rj = x + dj;
        if (ri >= 0 && ri < img->height && rj >=0 && rj < img->width) {
          [self dfsImg:img atY:ri atX:rj blocks:blocks];
        }
      }
    }
  }
}

- (IplImage*)IplImageFromUIImage:(UIImage*)img {
  CGImageRef imageRef = img.CGImage;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  IplImage *iplimage = cvCreateImage(cvSize((int)img.size.width,(int)img.size.height), IPL_DEPTH_8U, 4 );
  
  CGContextRef contextRef = CGBitmapContextCreate(
                                                  iplimage->imageData,
                                                  iplimage->width,
                                                  iplimage->height,
                                                  iplimage->depth,
                                                  iplimage->widthStep,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
  CGContextDrawImage(contextRef,
                     CGRectMake(0, 0, img.size.width, img.size.height),
                     imageRef);
  
  CGContextRelease(contextRef);
  CGColorSpaceRelease(colorSpace);
  
  IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
  cvCvtColor(iplimage, ret, CV_RGBA2BGR);
  //  NSLog(@"ip  = %@, ret = %@", iplimage, ret);
  cvReleaseImage(&iplimage);
  
  return ret;
}

- (UIImage*)UIImageFromIplImage:(IplImage*)img {
  CGColorSpaceRef colorSpace;
  if (img->nChannels == 1) {
    colorSpace = CGColorSpaceCreateDeviceGray();
  }
  else {
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cvCvtColor(img, img, CV_BGR2RGB);
  }
  NSData *data = [NSData dataWithBytes:img->imageData length:img->imageSize];
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
  CGImageRef imageRef = CGImageCreate(img->width,
                                      img->height,
                                      img->depth,
                                      img->depth * img->nChannels,
                                      img->widthStep,
                                      colorSpace,
                                      kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                      provider,
                                      NULL,
                                      false,
                                      kCGRenderingIntentDefault
                                      );
  UIImage *ret = [UIImage imageWithCGImage:imageRef];
  
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  
  return ret;
}
@end
