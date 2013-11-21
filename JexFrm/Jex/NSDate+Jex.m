//
//  NSDate+Jex.m
//  CrazyDice
//
//  Created by Jiangy on 12-9-4.
//  Copyright (c) 2012年 35VI. All rights reserved.
//

#import "NSDate+Jex.h"

@implementation NSDate (Jex)

+ (NSString *)localeDate {
    char timeNow[20];
    time_t lt;
    struct tm * tp;
    lt = time(NULL);
    tp = localtime(&lt);
    strftime(timeNow, 20, "%Y-%m-%d %T", tp);
    return [NSString stringWithUTF8String:timeNow];
}

- (NSString *)localeDescription {
    return [self descriptionWithLocale:[NSLocale currentLocale]];
}

+ (NSString *)timeStringFromInterval:(NSTimeInterval)interval {
    int second = (int)interval % 60;
    int minute = ((int)interval / 60) % 60;
    int hour = ((int)interval / 3600) % 60;
    NSMutableString * time = [NSMutableString stringWithCapacity:0];
    if (hour > 0) {
        [time appendFormat:@"%i:", hour];
    }
    if (minute > 0) {
        if ([time length] > 0 && minute < 10) {
            [time appendString:@"0"];
        }
        [time appendFormat:@"%i:", minute];
    }
    
    if ([time length] > 0 && second < 10) {
        [time appendString:@"0"];
    }
    [time appendFormat:@"%i", second];
    
    return time;
}

+ (NSString *)minuteTimeFromInterval:(NSTimeInterval)interval  {
    int second = (int)interval % 60;
    int minute = ((int)interval / 60) % 60;
    int hour = ((int)interval / 3600) % 60;
    NSMutableString * time = [NSMutableString stringWithCapacity:0];
    if (hour > 0) {
        [time appendFormat:@"%i:", hour];
    }
    
    if (minute < 10) {
        [time appendString:@"0"];
    }
    [time appendFormat:@"%i:", minute];
    
    if ([time length] > 0 && second < 10) {
        [time appendString:@"0"];
    }
    [time appendFormat:@"%i", second];
    
    return time;
}

+ (NSString *)descriptionLeftTime:(NSInteger)interval {
    int second = interval % 60;
    int minute = (interval / 60) % 60;
    int hour = (interval / 3600) % 60;
    int day = hour / 24;
    hour %= 24;
    NSMutableString * time = [NSMutableString stringWithCapacity:0];
    if (day > 0) {
        [time appendFormat:@"%i 天 ", day];
    }
    [time appendFormat:@"%i 时 ", hour];
    [time appendFormat:@"%i 分 ", minute];
    if (second > 0) {
        [time appendFormat:@"%i 秒 ", second];
    }
    
    return time;
}

+ (NSString *)descriptionOverTime:(NSInteger)interval {
    return nil;
}

@end
