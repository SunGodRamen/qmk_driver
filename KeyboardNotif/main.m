//
//  main.m
//  KeyboardNotif
//
//  Created by von Stuelpnagel, Alexander Thomas (A.) on 2/26/23.
//
#import <Cocoa/Cocoa.h>
#import "KeyboardNotifier.h"
#import "KeyboardNotifierConfig.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *filePath = [@"~/.app2bit" stringByExpandingTildeInPath];
        KeyboardNotifierConfig *config = [[KeyboardNotifierConfig alloc] initWithFilePath:filePath];

        KeyboardNotifier *notifier = [[KeyboardNotifier alloc] initWithConfig:config];

        // Start listening for keyboard events
        [notifier start];

        // Wait for user input to stop listening
        NSLog(@"Press any key to stop listening");
        getchar();

        // Stop listening for keyboard events
        [notifier stop];

    }
    return 0;
}
