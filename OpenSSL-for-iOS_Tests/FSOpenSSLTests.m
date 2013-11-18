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

@end
