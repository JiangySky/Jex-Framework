//
//  NSData+Jex.m
//  CrazyDice
//
//  Created by Jiangy on 12-8-30.
//  Copyright (c) 2012年 35VI. All rights reserved.
//

#import "NSData+Jex.h"
#import "zlib.h"
#import "zconf.h"

@implementation NSData (Jex)

+ (NSData *)dataWithJSONData:(NSData *)jsonData {
    return (NSData *)[JSON_READ deserialize:jsonData error:nil];
}

- (NSData *)JSONData {
    return [JSON_WRITE serializeObject:self error:nil];
}

- (NSString *)JSONString {
    return [[JSON_WRITE serializeObject:self error:nil] UTF8String];
}

- (NSString *)UTF8String {
    return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)stringWithEncode:(NSStringEncoding)encoding {
    return [[[NSString alloc] initWithData:self encoding:encoding] autorelease];
}

- (NSString *)base64String {
    const uint8_t * input = (const uint8_t *)[self bytes];
    NSInteger length = [self length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData * data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t * output = (uint8_t*)data.mutableBytes;
    
    NSInteger i, i2;
    for (i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (i2 = 0; i2 < 3; i2++) {
            value <<= 8;
            if (i+i2 < length) {
                value |= (0xFF & input[i+i2]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] = table[(value >> 18) & 0x3F];
        output[theIndex + 1] = table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

- (NSData *)gzipInflate {
    if ([self length] == 0) {
        return self;
    }
	
    NSUInteger full_length = [self length];
	NSUInteger half_length = [self length] / 2;
	
    NSMutableData * decompressed = [NSMutableData dataWithLength:(full_length + half_length)];
    BOOL done = NO;
    int status;
	
    z_stream strm;
    strm.next_in = (Bytef *)[self bytes];
    strm.avail_in = (uInt)[self length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
	
    if (inflateInit2(&strm, (15+32)) != Z_OK) {
        return nil;
    }
	
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            [decompressed increaseLengthBy: half_length];
        }
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } else if (status != Z_OK) {
            break;
        }
    }
    if (inflateEnd (&strm) != Z_OK) {
        return nil;
    }
    // Set real length.
    if (done) {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } else {
        return nil;
    }
}

- (NSData *)gzipData {
    if (!self || [self length] == 0) {
		NSLog(@"%s: Error: Can't compress an empty or nil NSData object",__func__);
		return nil;
	}
	
	z_stream zlibStreamStruct;
	zlibStreamStruct.zalloc = Z_NULL;
	zlibStreamStruct.zfree = Z_NULL;
	zlibStreamStruct.opaque = Z_NULL;
	zlibStreamStruct.total_out = 0;
	zlibStreamStruct.next_in = (Bytef *)[self bytes];
	zlibStreamStruct.avail_in = (uInt)[self length];
	
	int initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
	if (initError != Z_OK) {
		NSString *errorMsg = nil;
		switch (initError) {
			case Z_STREAM_ERROR:
				errorMsg = @"Invalid parameter passed in to function.";
				break;
			case Z_MEM_ERROR:
				errorMsg = @"Insufficient memory.";
				break;
			case Z_VERSION_ERROR:
				errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
				break;
			default:
				errorMsg = @"Unknown error code.";
				break;
		}
		NSLog(@"%s:deflateInit2() Error: \"%@\" Message: \"%s\"",__func__,errorMsg,zlibStreamStruct.msg);
		return nil;
	}
	
	NSMutableData *compressedData = [NSMutableData dataWithLength:[self length] * 1.01 + 21];
	
	int deflateStatus;
	do {
		zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;
		zlibStreamStruct.avail_out = (uInt)([compressedData length] - zlibStreamStruct.total_out);
		deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);
        
	} while (deflateStatus == Z_OK);
	
	if (deflateStatus != Z_STREAM_END) {
        NSString *errorMsg = nil;
        switch (deflateStatus) {
            case Z_ERRNO:
                errorMsg = @"Error occured while reading file.";
                break;
            case Z_STREAM_ERROR:
                errorMsg = @"The stream state was inconsistent (e.g., next_in or next_out was NULL).";
                break;
            case Z_DATA_ERROR:
                errorMsg = @"The deflate data was invalid or incomplete.";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"Memory could not be allocated for processing.";
                break;
            case Z_BUF_ERROR:
                errorMsg = @"Ran out of output buffer for writing compressed bytes.";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                break;
            default:
                errorMsg = @"Unknown error code.";
                break;
        }
        NSLog(@"%s:zlib error while attempting compression: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
        deflateEnd(&zlibStreamStruct);
        return nil;
	}
	
	deflateEnd(&zlibStreamStruct);
	[compressedData setLength:zlibStreamStruct.total_out];
	NSLog(@"%s: Compressed file from %i B to %i B", __func__, (int)[self length], (int)[compressedData length]);
	return compressedData;
}

@end

@implementation NSMutableData (Jex)

- (void)clear {
    [self resetBytesInRange:NSMakeRange(0, self.length)];
    [self setLength:0];
}

@end
