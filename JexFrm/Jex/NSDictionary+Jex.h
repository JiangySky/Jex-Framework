//
//  NSDictionary+Jex.h
//  CrazyDice
//
//  Created by Jiangy on 12-8-30.
//  Copyright (c) 2012年 35VI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONExtensions.h"

@interface NSDictionary (Jex) <JSONExtensions>

+ (NSDictionary *)dictionaryWithJSONData:(NSData *)jsonData;
+ (id)dictionaryWithJSONString:(NSString *)jsonStr;
- (NSData *)JSONData;
- (NSString *)JSONString;
- (NSData *)data;

@end
