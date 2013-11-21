//
//  NSData+Jex.h
//  CrazyDice
//
//  Created by Jiangy on 12-8-30.
//  Copyright (c) 2012年 35VI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONExtensions.h"

@interface NSData (Jex) <JSONExtensions>

+ (NSData *)dataWithJSONData:(NSData *)jsonData;
- (NSData *)JSONData;
- (NSString *)JSONString;
- (NSString *)UTF8String;
- (NSString *)stringWithEncode:(NSStringEncoding)encoding;
- (NSString *)base64String;
- (NSData *)gzipInflate;
- (NSData *)gzipData;

@end

@interface NSMutableData (Jex)

- (void)clear;

@end
