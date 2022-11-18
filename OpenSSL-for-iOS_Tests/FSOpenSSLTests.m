//
//  OpenSSL_for_iOS_Tests.m
//  OpenSSL-for-iOS_Tests
//
//  Created by Felix Schulze on 18.11.2013.
//  Copyright (c) 2013 Felix Schulze . All rights reserved.
//  Web: http://www.felixschulze.de
//

#import <XCTest/XCTest.h>
#import "FSOpenSSL.h"

@interface FSOpenSSLTests : XCTestCase
@end

@implementation FSOpenSSLTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testMD5
{
    XCTAssertEqualObjects([FSOpenSSL md5FromString:@"test string"], @"6f8db599de986fab7a21625b7916589c");
}

- (void)testSHA256
{
    XCTAssertEqualObjects([FSOpenSSL sha256FromString:@"test string"], @"d5579c46dfcc7f18207013e65b44e4cb4e2c2298f4ac457ba8f82743f31e930b");
}

- (void)testSHA512
{
    XCTAssertEqualObjects([FSOpenSSL sha512FromString:@"test string"], @"10e6d647af44624442f388c2c14a787ff8b17e6165b83d767ec047768d8cbcb71a1a3226e7cc7816bc79c0427d94a9da688c41a3992c7bf5e4d7cc3e0be5dbac");
}

- (void)testBase64
{
    XCTAssertEqualObjects([FSOpenSSL base64FromString:@"test string" encodeWithNewlines:NO], @"dGVzdCBzdHJpbmc=");
}

- (void)testBase64WithNewLines
{
    XCTAssertEqualObjects([FSOpenSSL base64FromString:@"test string" encodeWithNewlines:YES], @"dGVzdCBzdHJpbmc=\n");
}



@end
