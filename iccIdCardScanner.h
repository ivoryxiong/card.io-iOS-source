//
//  iccIdCardScanner.h
//  icc
//
//  Created by Hua Xiong on 16/3/15.
//
//

#import <Foundation/Foundation.h>

#import "CardIOIdCardScannerDelegate.h"

@interface iccIdCardScanner : NSObject <CardIOIdCardScannerDelegate>
@property(strong, nonatomic, readwrite) NSMutableDictionary *cardInfo;

@end
