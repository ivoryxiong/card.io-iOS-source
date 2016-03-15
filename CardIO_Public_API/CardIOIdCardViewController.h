//
//  CardIOIdCardViewController.h
//  icc
//
//  Created by ios on 16/3/14.
//
//

#import <UIKit/UIKit.h>

@class CardIOIdCardViewController;
@protocol CardIOIdCardScannerDelegate;

@protocol CardIOIdCardViewControllerDelegate<NSObject>

@required

- (void)userDidCancelIdCardViewController:(CardIOIdCardViewController *)paymentViewController;

- (void)userDidProvideIdCardCardInfo:(NSDictionary *)cardInfo
              inIdCardViewController:(CardIOIdCardViewController *)idCardViewController;

@end

@interface CardIOIdCardViewController : UINavigationController
- (instancetype)initWithIdCardDelegate:(id<CardIOIdCardViewControllerDelegate>)aDelegate
                                     scanner:(id<CardIOIdCardScannerDelegate>)scanner;

- (instancetype)initWithIdCardDelegate:(id<CardIOIdCardViewControllerDelegate>)aDelegate
                               scanner:(id<CardIOIdCardScannerDelegate>)scanner
                       scanningEnabled:(BOOL)scanningEnabled;

@property(nonatomic, copy, readwrite) NSString *languageOrLocale;

@property(nonatomic, assign, readwrite) BOOL keepStatusBarStyle;

@property(nonatomic, assign, readwrite) UIBarStyle navigationBarStyle;

@property(nonatomic, retain, readwrite) UIColor *navigationBarTintColor;


@property(nonatomic, assign, readwrite) BOOL disableBlurWhenBackgrounding;


@property(nonatomic, retain, readwrite) UIColor *guideColor;

@property(nonatomic, assign, readwrite) BOOL suppressScanConfirmation;


@property(nonatomic, assign, readwrite) BOOL suppressScannedCardImage;

@property(nonatomic, assign, readwrite) CGFloat scannedImageDuration;

@property(nonatomic, assign, readwrite) BOOL maskManualEntryDigits;

@property(nonatomic, copy, readwrite) NSString *scanInstructions;


@property(nonatomic, assign, readwrite) BOOL hideCardIOLogo;

@property(nonatomic, retain, readwrite) UIView *scanOverlayView;

@property(nonatomic, assign, readwrite) BOOL disableManualEntryButtons;

/// Access to the delegate.
@property(nonatomic, weak, readwrite) id<CardIOIdCardViewControllerDelegate> idCardDelegate;

@property(nonatomic, weak, readwrite) id<CardIOIdCardScannerDelegate> idScanner;

@end
