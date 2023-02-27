//
//  KeyboardNotifier.h
//  KeyboardNotif
//
//  Created by von Stuelpnagel, Alexander Thomas (A.) on 2/26/23.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/hid/IOHIDLib.h>

@class KeyboardNotifierConfig;

@interface KeyboardNotifier : NSObject

- (instancetype)initWithConfig:(KeyboardNotifierConfig *)config;
- (void)start;
- (void)stop;

@end
