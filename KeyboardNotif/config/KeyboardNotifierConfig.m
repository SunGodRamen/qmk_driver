//
//  UserConfiguration.m
//  KeyboardNotif
//
//  Created by von Stuelpnagel, Alexander Thomas (A.) on 2/26/23.
//

#import "KeyboardNotifierConfig.h"

@implementation KeyboardNotifierConfig

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        NSError *error = nil;
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"Error reading .app2bit file: %@", error.localizedDescription);
            return nil;
        }
        NSMutableDictionary<NSString *, NSNumber *> *appBitCodes = [NSMutableDictionary dictionary];
        NSArray<NSString *> *lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *line in lines) {
            if (line.length == 0) {
                continue;
            }
            NSArray<NSString *> *lineComponents = [line componentsSeparatedByString:@","];
            if (lineComponents.count == 2) {
                appBitCodes[lineComponents[0]] = @(lineComponents[1].intValue);
            }
        }
        self.appBitCodes = [NSDictionary dictionaryWithDictionary:appBitCodes];
        NSString *firstLine = [lines firstObject];
        NSLog(@"First line: %@", firstLine);
        NSArray<NSString *> *ids = [firstLine componentsSeparatedByString:@","];
        if (ids.count == 2) {
            self.vendorID = ids[0].intValue;
            self.productID = ids[1].intValue;
            NSLog(@"Vendor ID: %d, Product ID: %d", self.vendorID, self.productID);
        } else {
            NSLog(@"Failed to parse vendor and product IDs from first line.");
        }
    }
    return self;
}



@end

