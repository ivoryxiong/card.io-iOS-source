//
//  CardIOIdCardCameraViewController.h
//  icc
//
//  Created by Hua Xiong on 16/3/14.
//
//

#if USE_CAMERA || SIMULATE_CAMERA

#import <UIKit/UIKit.h>

#import <AudioToolbox/AudioServices.h>

@class CardIOContext;

@interface CardIOIdCardCameraViewController : UIViewController

- (id)init;

@property(nonatomic, strong, readwrite) CardIOContext *context;

@end

#endif //USE_CAMERA || SIMULATE_CAMERA
