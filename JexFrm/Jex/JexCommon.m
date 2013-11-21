//
//  JexCommon.m
//  JexFrm
//
//  Created by Jiangy on 13-11-20.
//  Copyright (c) 2013年 Jiangy. All rights reserved.
//

#import "JexCommon.h"
#import "Jex.h"

@implementation JexCommon

+ (NSInteger)randomBetween:(NSInteger)from And:(NSInteger)to {
	static BOOL haveSeeds;
	if (!haveSeeds) {
		srand((unsigned) time(NULL));
		haveSeeds = YES;
	}
	NSInteger randonNum = from + rand() % (to - from);
	return randonNum;
}

+ (CGFloat)distanceBetweenPoint:(CGPoint)pFrom andPoint:(CGPoint)pTo {
	CGFloat dx = pTo.x - pFrom.x;
	CGFloat dy = pTo.y - pFrom.y;
	return sqrt(dx * dx + dy * dy);
}

+ (CGFloat)angleBetweenPoint:(CGPoint)pFrom andPoint:(CGPoint)pTo {
	CGFloat dw = pTo.x - pFrom.x;
	CGFloat dh = pTo.y - pFrom.y;
	CGFloat angle;
	if (dw == 0) {
		if (dh > 0) {
			angle = 90;
		} else if (dh < 0) {
			angle = 270;
		} else {
			angle = 0;
		}
	} else {
		float randians = atan(dh / dw);
		angle = RADIANS_TO_DEGREES(randians);
		angle += (dw < 0 ? 180 : 0);
		angle += (dh < 0 ? 360 : 0);
	}
	
	return (int)angle % 360;
}

+ (CGFloat)angleFromLineWithFromPoint:(CGPoint)lFromPFrom andToPoint:(CGPoint)lFromPTo
				  toLineWithFromPoint:(CGPoint)lToPFrom andToPoint:(CGPoint)lToPTo {
	CGFloat angleFrom = [self angleBetweenPoint:lFromPFrom andPoint:lFromPTo];
	CGFloat angleTo = [self angleBetweenPoint:lToPFrom andPoint:lToPTo];
	return (int)(180 + (angleTo - angleFrom) + 360) % 360;
}

+ (CGPoint)rectCenter:(CGRect)rect {
	CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	return center;
}

+ (CGFloat)quadrantOfAngle:(CGFloat)angle {
	return angle / 90;
}

/*!
 @abstract  Finds an address component of a specific type inside the given address components array
 */
+ (NSString *)addressComponent:(NSString *)component inAddressArray:(NSArray *)array ofType:(NSString *)type {
	NSUInteger index = [array indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        return [(NSString *)([[obj objectForKey:@"types"] objectAtIndex:0]) isEqualToString:component];
	}];
	if (index == NSNotFound) {
        return nil;
    }
	return [[[array objectAtIndex:index] valueForKey:type] copy];
}

+ (BOOL)isMobileNumber:(NSString *)mobileNum {
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,147,150,151,157,158,159,182,183,187,188
     * 联通：130,131,132,145,152,155,156,185,186
     * 电信：133,1349,153,180,181,189
     */
    NSString * MOBILE = @"^1(3[0-9]|4[57]|5[0-35-9]|8[01235-9])\\d{8}$";
    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,147,150,151,157,158,159,182,182,187,188
     12         */
    NSString * CM = @"^1(34[0-8]|(3[5-9]|47|5[017-9]|8[2378])\\d)\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,145,152,155,156,185,186
     17         */
    NSString * CU = @"^1(3[0-2]|45|5[256]|8[56])\\d{8}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,181,189
     22         */
    NSString * CT = @"^1((33|53|8[019])[0-9]|349)\\d{7}$";
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    // NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    
    if (([regextestmobile evaluateWithObject:mobileNum] == YES)
        || ([regextestcm evaluateWithObject:mobileNum] == YES)
        || ([regextestct evaluateWithObject:mobileNum] == YES)
        || ([regextestcu evaluateWithObject:mobileNum] == YES)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)validateEmail:(NSString *)email {
    if((0 != [email rangeOfString:@"@"].length) && (0 != [email rangeOfString:@"."].length)) {
        NSCharacterSet * tmpInvalidCharSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSMutableCharacterSet * tmpInvalidMutableCharSet = [[tmpInvalidCharSet mutableCopy] autorelease];
        [tmpInvalidMutableCharSet removeCharactersInString:@"_-"];
        
        //使用compare option 来设定比较规则，如
        //NSCaseInsensitiveSearch是不区分大小写
        //NSLiteralSearch 进行完全比较,区分大小写
        //NSNumericSearch 只比较定符串的个数，而不比较字符串的字面值
        NSRange range1 = [email rangeOfString:@"@" options:NSCaseInsensitiveSearch];
        
        //取得用户名部分
        NSString * userNameString = [email substringToIndex:range1.location];
        NSArray * userNameArray   = [userNameString componentsSeparatedByString:@"."];
        
        for(NSString * string in userNameArray) {
            NSRange rangeOfInavlidChars = [string rangeOfCharacterFromSet:tmpInvalidMutableCharSet];
            if(rangeOfInavlidChars.length != 0 || [string isEqualToString:@""]) {
                return NO;
            }
        }
        
        NSString * domainString = [email substringFromIndex:range1.location + 1];
        NSArray * domainArray   = [domainString componentsSeparatedByString:@"."];
        
        for(NSString * string in domainArray) {
            NSRange rangeOfInavlidChars=[string rangeOfCharacterFromSet:tmpInvalidMutableCharSet];
            if(rangeOfInavlidChars.length !=0 || [string isEqualToString:@""])
                return NO;
        }
        
        return YES;
        
    } else {
        return NO;
    }
}

+ (void)logToFile:(NSString *)log {
    NSString * content = [NSString stringWithFormat:@"%@>> %@", [NSDate localeDate], log];
    [NSFileManager appendContent:content toFile:[APP resourceInDocument:@"log.txt"]];
}

@end
