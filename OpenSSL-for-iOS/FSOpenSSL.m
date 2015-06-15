//
//  FSOpenSSL.m
//  OpenSSL-for-iOS
//
//  Created by Felix Schulze on 16.03.2013.
//  Copyright 2013 Felix Schulze. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "FSOpenSSL.h"
#include <openssl/md5.h>
#include <openssl/sha.h>
#import <openssl/evp.h>

@implementation FSOpenSSL

+ (NSString *)md5FromString:(NSString *)string {
    unsigned char *inStrg = (unsigned char *) [[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    unsigned long lngth = [string length];
    unsigned char result[MD5_DIGEST_LENGTH];
    NSMutableString *outStrg = [NSMutableString string];

    MD5(inStrg, lngth, result);

    unsigned int i;
    for (i = 0; i < MD5_DIGEST_LENGTH; i++) {
        [outStrg appendFormat:@"%02x", result[i]];
    }
    return [outStrg copy];
}

+ (NSString *)sha256FromString:(NSString *)string {
    unsigned char *inStrg = (unsigned char *) [[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    unsigned long lngth = [string length];
    unsigned char result[SHA256_DIGEST_LENGTH];
    NSMutableString *outStrg = [NSMutableString string];

    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, inStrg, lngth);
    SHA256_Final(result, &sha256);

    unsigned int i;
    for (i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        [outStrg appendFormat:@"%02x", result[i]];
    }
    return [outStrg copy];
}

+ (NSString *)base64FromString:(NSString *)string encodeWithNewlines:(BOOL)encodeWithNewlines {
    BIO *mem = BIO_new(BIO_s_mem());
    BIO *b64 = BIO_new(BIO_f_base64());

    if (!encodeWithNewlines) {
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    }
    mem = BIO_push(b64, mem);

    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger length = stringData.length;
    void *buffer = (void *) [stringData bytes];
    int bufferSize = (int)MIN(length, INT_MAX);

    NSUInteger count = 0;

    BOOL error = NO;

    // Encode the data
    while (!error && count < length) {
        int result = BIO_write(mem, buffer, bufferSize);
        if (result <= 0) {
            error = YES;
        }
        else {
            count += result;
            buffer = (void *) [stringData bytes] + count;
            bufferSize = (int)MIN((length - count), INT_MAX);
        }
    }

    int flush_result = BIO_flush(mem);
    if (flush_result != 1) {
        return nil;
    }

    char *base64Pointer;
    NSUInteger base64Length = (NSUInteger) BIO_get_mem_data(mem, &base64Pointer);

    NSData *base64data = [NSData dataWithBytesNoCopy:base64Pointer length:base64Length freeWhenDone:NO];
    NSString *base64String = [[NSString alloc] initWithData:base64data encoding:NSUTF8StringEncoding];

    BIO_free_all(mem);
    return base64String;
}

@end