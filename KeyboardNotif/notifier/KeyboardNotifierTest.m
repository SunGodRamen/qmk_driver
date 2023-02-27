//
//  KeyboardNotifierTest.m
//  KeyboardNotif
//
//  Created by von Stuelpnagel, Alexander Thomas (A.) on 2/26/23.
//

#import <XCTest/XCTest.h>
#import "KeyboardNotifier.h"
#import "KeyboardNotifierConfig.h"

@interface KeyboardNotifierTests : XCTestCase

@property (nonatomic) KeyboardNotifierConfig *config;

@end

@implementation KeyboardNotifierTests

- (void)setUp {
    [super setUp];
    self.config = [[KeyboardNotifierConfig alloc] initWithFilePath:@"path/to/config/file"];
}

- (void)tearDown {
    self.config = nil;
    [super tearDown];
}
- (void)setCurrentApplication:(NSString *)appName {
    NSRunningApplication *app = [NSRunningApplication runningApplicationsWithBundleIdentifier:[NSString stringWithFormat:@"com.apple.%@", appName]].firstObject;
    [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
}

- (void)testBitCodeForCurrentApp {
    KeyboardNotifier *notifier = [[KeyboardNotifier alloc] initWithConfig:self.config];
    NSData *bitCodeData = [notifier bitCodeForCurrentApp];
    XCTAssertEqualObjects(bitCodeData, [NSData dataWithBytes:(uint8_t[]){0x00, 0x01} length:2]);
}

@end
