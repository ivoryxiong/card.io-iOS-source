//
//  CardIOIplImage.m
//  See the file "LICENSE.md" for the full license governing this code.
//

#if USE_CAMERA

#import "CardIOIplImage.h"
#import "dmz.h"
#import "CardIOCGGeometry.h"
#include "opencv2/imgproc/imgproc_c.h"

#define VISITED  0x7F

@interface CardIOIplImage ()

@property(nonatomic, assign, readwrite) IplImage *image;

@end


@implementation CardIOIplImage


+ (CardIOIplImage *)imageWithSize:(CvSize)size depth:(int)depth channels:(int)channels {
  IplImage *newImage = cvCreateImage(size, depth, channels);
  return [self imageWithIplImage:newImage];
}

+ (CardIOIplImage *)imageFromYCbCrBuffer:(CVImageBufferRef)imageBuffer plane:(size_t)plane {
  char *planeBaseAddress = (char *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, plane);
  
  size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, plane);
  size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, plane);
  size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, plane);
  
  int numChannels = plane == Y_PLANE ? 1 : 2;
  IplImage *colocatedImage = cvCreateImageHeader(cvSize((int)width, (int)height), IPL_DEPTH_8U, numChannels);
  colocatedImage->imageData = planeBaseAddress;
  colocatedImage->widthStep = (int)bytesPerRow;
  
  return [self imageWithIplImage:colocatedImage];
}

+ (CardIOIplImage *)imageWithIplImage:(IplImage *)anImage {
  return [[self alloc] initWithIplImage:anImage];
}

- (id)initWithIplImage:(IplImage *)anImage {
  if((self = [super init])) {
    self.image = anImage;
  }
  return self;
}

+ (CardIOIplImage *)rgbImageWithY:(CardIOIplImage *)y cb:(CardIOIplImage *)cb cr:(CardIOIplImage *)cr {
  IplImage *rgb = NULL;
  dmz_YCbCr_to_RGB(y.image, cb.image, cr.image, &rgb);
  return [self imageWithIplImage:rgb];
}


- (NSArray *)split {
  if(self.image->nChannels == 1) {
    return [NSArray arrayWithObject:self];
  }
  assert(self.image->nChannels == 2); // not implemented for more
  IplImage *channel1;
  IplImage *channel2;
  dmz_deinterleave_uint8_c2(self.image, &channel1, &channel2);
  CardIOIplImage *image1 = [[self class] imageWithIplImage:channel1];
  CardIOIplImage *image2 = [[self class] imageWithIplImage:channel2];
  return [NSArray arrayWithObjects:image1, image2, nil];
}

- (NSString *)description {
  CvSize s = self.cvSize;
  return [NSString stringWithFormat:@"<CardIOIplImage %p: %ix%i>", self, s.width, s.height];
}

- (void)dealloc {
  cvReleaseImage(&image);
}

- (IplImage *)image {
  return image;
}

- (CvSize)cvSize {
  return cvGetSize(self.image);
}

- (CGSize)cgSize {
  CvSize s = self.cvSize;
  return CGSizeMake(s.width, s.height);
}

- (CvRect)cvRect {
  CvSize s = self.cvSize;
  return cvRect(0, 0, s.width - 1, s.height - 1);
}

- (void)setImage:(IplImage *)newImage {
  assert(image == NULL);
  image = newImage;
}

- (UIImage *)ico_ocr_image_threshold:(int)threshold {
  IplImage* rgb_img = cvCreateImage(cvGetSize(self.image),IPL_DEPTH_8U,3);
  cvCvtColor(self.image, rgb_img, CV_GRAY2RGB);
  IplImage* rgb_32f_img = cvCreateImage(cvGetSize(rgb_img),IPL_DEPTH_32F,rgb_img->nChannels);
  cvConvertScale(rgb_img, rgb_32f_img, 1.0/255.0, 0);
  IplImage* lab_img = cvCreateImage(cvGetSize(rgb_32f_img),IPL_DEPTH_32F,3);
  cvCvtColor(rgb_32f_img, lab_img, CV_RGB2Lab);
  [self remainBlackColor:lab_img];
  cvCvtColor(lab_img, rgb_32f_img, CV_Lab2RGB);
  cvReleaseImage(&lab_img);
  cvConvertScale(rgb_32f_img, rgb_img, 255, 0);
  
  IplImage* dst_img = cvCreateImage(cvGetSize(self.image),IPL_DEPTH_8U,1);
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

- (UIImage *)UIImage {
  return [self UIImageFromIplImage:self.image];
}

- (CardIOIplImage *)copyCropped:(CvRect)roi {
  return [self copyCropped:roi destSize:cvGetSize(self.image)];
}

- (CardIOIplImage *)copyCropped:(CvRect)roi destSize:(CvSize)destSize {
  CvRect currentROI = cvGetImageROI(self.image);
  cvSetImageROI(self.image, roi);
  IplImage *copied = cvCreateImage(destSize, self.image->depth, self.image->nChannels);
  
  if (roi.width == destSize.width && roi.height == destSize.height) {
    cvCopy(self.image, copied, NULL);
  }
  else {
    cvResize(self.image, copied, CV_INTER_LINEAR);
  }
  
  cvSetImageROI(self.image, currentROI);
  return [CardIOIplImage imageWithIplImage:copied];
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

#endif
