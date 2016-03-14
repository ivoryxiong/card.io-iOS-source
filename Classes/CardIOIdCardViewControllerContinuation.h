//
//  CardIOIdCardViewControllerContinuation.h
//  icc
//
//  Created by Hua Xiong on 16/3/14.
//
//

#import "CardIOIdCardViewController.h"

@class CardIOAnalytics;
@class CardIOContext;

@interface CardIOIdCardViewController ()

+ (CardIOIdCardViewController *)cardIOIdCardViewControllerForResponder:(UIResponder *)responder;
- (UIInterfaceOrientationMask)supportedOverlayOrientationsMask;

@property(nonatomic, assign, readwrite) BOOL currentViewControllerIsDataEntry;
@property(nonatomic, assign, readwrite) UIInterfaceOrientation initialInterfaceOrientationForViewcontroller;

@property(nonatomic, strong, readwrite) UIAlertView *unauthorizedForScanAlert;
@property(nonatomic, assign, readwrite) BOOL shouldStoreStatusBarStyle;
@property(nonatomic, assign, readwrite) UIStatusBarStyle originalStatusBarStyle;
@property(nonatomic, assign, readwrite) BOOL statusBarWasOriginallyHidden;

@property(nonatomic, strong, readwrite) CardIOContext *context;

@property(nonatomic, strong, readwrite) UIImageView *obfuscatingView;

#if CARDIO_DEBUG
@property(nonatomic, assign, readwrite) BOOL doABTesting;
#endif

@end