//
//  UserConfiguration.h
//  KeyboardNotif
//
//  Created by von Stuelpnagel, Alexander Thomas (A.) on 2/26/23.
//

#import <Foundation/Foundation.h>

@interface KeyboardNotifierConfig : NSObject

@property (nonatomic, readwrite) int vendorID;
@property (nonatomic, readwrite) int productID;
@property (nonatomic, readwrite) NSDictionary<NSString *, NSNumber *> *appBitCodes;

- (instancetype)initWithFilePath:(NSString *)filePath;

@end
