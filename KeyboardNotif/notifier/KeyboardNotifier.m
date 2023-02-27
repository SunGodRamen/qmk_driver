//
//  KeyboardNotifier.m
//  KeyboardNotif
//
//  Created by von Stuelpnagel, Alexander Thomas (A.) on 2/26/23.
//

#import "KeyboardNotifier.h"
#import "KeyboardNotifierConfig.h"
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDLib.h>


@interface KeyboardNotifier () <NSApplicationDelegate>

@property (nonatomic, weak) KeyboardNotifier *instance;
@property (nonatomic) IOHIDManagerRef hidManager;
@property (nonatomic) IOHIDDeviceRef hidDevice; // <-- Add this property for the HID device
@property (nonatomic) NSTimer *timer;
@property (nonatomic, strong) NSString *currentApp;
@property (nonatomic, assign) int vendorID;
@property (nonatomic, assign) int productID;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *appBitCodes;

@end

@implementation KeyboardNotifier

- (void)start {
    CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
    IOHIDManagerScheduleWithRunLoop(self.hidManager, runLoopRef, kCFRunLoopDefaultMode);
    NSLog(@"Started listening for keyboard events");
    CFRunLoopRun();
}

- (void)stop {
    IOHIDManagerUnscheduleFromRunLoop(self.hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    NSLog(@"Stopped listening for keyboard events");
}

- (instancetype)initWithConfig:(KeyboardNotifierConfig *)config {
    self = [super init];
    if (self) {
        self.appBitCodes = config.appBitCodes;
        self.vendorID = config.vendorID;
        self.productID = config.productID;
        NSLog(@"configured with vendor ID: 0x%04x, product ID: 0x%04x", self.vendorID, self.productID);

        // Create an IOHIDManagerRef object
        IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);

        // Set the device matching criteria
        NSDictionary *matching = @{@(kIOHIDVendorIDKey): @(0x1234),
                                   @(kIOHIDProductIDKey): @(0x5678)};
        CFDictionaryRef matchingRef = (__bridge CFDictionaryRef)matching;
        IOHIDManagerSetDeviceMatching(manager, matchingRef);

        // Get all devices that match the criteria
        CFSetRef deviceSet = IOHIDManagerCopyDevices(manager);
        CFIndex deviceCount = CFSetGetCount(deviceSet);

        if (deviceCount == 0) {
            // No matching devices found
        } else {
            // Loop through each device and get its ID
            const void **deviceArray = calloc(deviceCount, sizeof(void *));
            CFSetGetValues(deviceSet, deviceArray);
            
            for (int i = 0; i < deviceCount; i++) {
                IOHIDDeviceRef device = (IOHIDDeviceRef)deviceArray[i];
                int deviceID = IOHIDDeviceGetDeviceID(device);
                
                // Use deviceID for your purpose
            }
            
            free(deviceArray);
        }

        CFRelease(deviceSet);
        CFRelease(manager);

        // Open the device to get the IOHIDDeviceRef object
        IOHIDDeviceRef device = IOHIDDeviceCreate(kCFAllocatorDefault, deviceID);
        if (device) {
            // Set the usage page and usage properties
            int usageValue = kHIDUsage_GD_Keyboard;
            CFNumberRef usage = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usageValue);

            int usagePageValue = kHIDPage_GenericDesktop;
            CFNumberRef usagePage = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usagePageValue);
            if (usagePage && usage) {
                IOHIDDeviceSetProperty(device, CFSTR(kIOHIDDeviceUsagePageKey), usagePage);
                IOHIDDeviceSetProperty(device, CFSTR(kIOHIDDeviceUsageKey), usage);
            }
            if (usagePage) CFRelease(usagePage);
            if (usage) CFRelease(usage);

            // Start listening for events
            IOHIDDeviceRegisterInputValueCallback(device, inputCallback, (__bridge void *)self);
            IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
            IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);

            // Release the IOHIDDeviceRef object
            CFRelease(device);
        }

        // Set up timer to check for the currently focused application
        _timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(checkCurrentApp) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
        NSLog(@"Timer set up to check for the current app");
        
        // Set this class as the application delegate to listen for app activation events
        [NSApplication sharedApplication].delegate = self;
        NSLog(@"This class set as the application delegate");
    }
    return self;
}

static void deviceMatchedCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    KeyboardNotifier *notifier = (__bridge KeyboardNotifier *)context;
    if (result == kIOReturnSuccess) {
        uint32_t vendorID = 0;
        uint32_t productID = 0;
        CFTypeRef cfVendorID = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
        if (cfVendorID) {
            CFNumberGetValue((CFNumberRef)cfVendorID, kCFNumberSInt32Type, &vendorID);
        }
        CFTypeRef cfProductID = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
        if (cfProductID) {
            CFNumberGetValue((CFNumberRef)cfProductID, kCFNumberSInt32Type, &productID);
        }
        if (vendorID == notifier.vendorID && productID == notifier.productID) {
            NSLog(@"QMK keyboard connected: %@", device);
            notifier.hidDevice = device;
            IOHIDDeviceRegisterInputValueCallback(device, inputCallback, (__bridge void *)notifier);
        } else {
            NSLog(@"Unexpected device connected: vendor ID = %d, product ID = %d", vendorID, productID);
        }
    } else {
        NSLog(@"Device matching callback returned error: %d", result);
    }
}


- (NSDictionary<NSString *, NSString *> *)parseBitCodeFile:(NSString *)filePath {
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error reading .app2bit file: %@", error.localizedDescription);
        return @{};
    }
    NSMutableDictionary<NSString *, NSString *> *appBitCodes = [NSMutableDictionary dictionary];
    NSArray<NSString *> *lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        if (line.length == 0) {
            continue;
        }
        NSArray<NSString *> *lineComponents = [line componentsSeparatedByString:@","];
        if (lineComponents.count == 2) {
            appBitCodes[lineComponents[0]] = lineComponents[1];
        }
    }
    NSLog(@"Parsed .app2bit file: %@", appBitCodes);
    return appBitCodes;
}

static void inputCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
    KeyboardNotifier *notifier = (__bridge KeyboardNotifier *)context;
    if (result == kIOReturnSuccess) {
        [notifier checkCurrentApp];
    }
}

- (void)checkCurrentApp {
    NSString *appName = [[NSWorkspace sharedWorkspace] frontmostApplication].localizedName;
    if (![appName isEqualToString:self.currentApp]) {
        NSLog(@"Current app: %@", appName);
        self.currentApp = appName;
        NSData *bitCodeData = [self bitCodeForCurrentApp];
        if (bitCodeData) {
            const uint8_t *bitCodeBytes = [bitCodeData bytes];
            uint8_t bitCode[bitCodeData.length];
            memcpy(bitCode, bitCodeBytes, bitCodeData.length);
            IOHIDDeviceSetReport(self.hidDevice, kIOHIDReportTypeOutput, 0, bitCode, bitCodeData.length);
            NSLog(@"Sent bitcode to keyboard: %@", bitCodeData);
        } else {
            NSLog(@"No bitcode found for app: %@", appName);
        }
    }
}

- (NSData *)bitCodeForCurrentApp {
    NSString *appName = [[NSWorkspace sharedWorkspace] frontmostApplication].localizedName;
    NSNumber *bitCodeNumber = self.appBitCodes[appName];
    if (bitCodeNumber) {
        uint16_t bitCode = [bitCodeNumber unsignedShortValue];
        uint8_t bitCodeBytes[2] = {bitCode >> 8, bitCode & 0xff};
        return [NSData dataWithBytes:bitCodeBytes length:2];
    } else {
        return nil;
    }
}


@end
