//
//  CardIOViewContinuation.h
//  See the file "LICENSE.md" for the full license governing this code.
//

#import <AVFoundation/AVFoundation.h>

@class CardIOCardScanner;
@class CardIOTransitionView;
@protocol CardIOIdCardScannerDelegate;

@interface CardIOView (continued)

@property(nonatomic, strong, readonly) CardIOCardScanner *scanner;
@property(nonatomic, weak, readonly) id<CardIOIdCardScannerDelegate> idScanner;
@property(nonatomic, strong, readonly) CardIOTransitionView *transitionView;

@end
