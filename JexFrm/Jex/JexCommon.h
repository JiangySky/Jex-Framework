//
//  JexCommon.h
//  JexFrm
//
//  Created by Jiangy on 13-11-20.
//  Copyright (c) 2013年 Jiangy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JexMacro.h"

#define RANDOM_CO(_from, _to)       [JexCommon randomBetween:_from And:_to]
#define RANDOM_CC(_from, _to)       [JexCommon randomBetween:_from And:(_to + 1)]
#define NSLogFile(_log)

@interface JexCommon : NSObject

+ (NSInteger)randomBetween:(NSInteger)from And:(NSInteger)to;
+ (CGFloat)distanceBetweenPoint:(CGPoint)pFrom andPoint:(CGPoint)pTo;
+ (CGFloat)angleBetweenPoint:(CGPoint)pFrom andPoint:(CGPoint)pTo;
+ (CGFloat)angleFromLineWithFromPoint:(CGPoint)lFromPFrom andToPoint:(CGPoint)lFromPTo
				  toLineWithFromPoint:(CGPoint)lToPFrom andToPoint:(CGPoint)lToPTo;
+ (CGPoint)rectCenter:(CGRect)rect;
+ (CGFloat)quadrantOfAngle:(CGFloat)angle;
+ (NSString *)addressComponent:(NSString *)component inAddressArray:(NSArray *)array ofType:(NSString *)type;
+ (BOOL)isMobileNumber:(NSString *)mobileNum;
+ (BOOL)validateEmail:(NSString *)email;
+ (void)logToFile:(NSString *)log;

@end