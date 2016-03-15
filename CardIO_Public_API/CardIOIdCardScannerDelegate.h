//
//  CardIOIdCardScannerDelegate.h
//  icc
//
//  Created by Hua Xiong on 16/3/14.
//
//

#import <Foundation/Foundation.h>

@protocol CardIOIdCardScannerDelegate <NSObject>
- (void)reset;
- (void)addFrame:(UIImage *)y;
- (BOOL)complete;

// these properties are intentionally (superstitiously, anyhow) atomic -- card scanners get passed around between threads

// will return garbage unless -complete returns YES
// the xOffsets and yOffset populated in cardInfo will be
// from the most recent frame added via addFrame!
@property(strong, nonatomic) NSMutableDictionary *cardInfo;
@end
