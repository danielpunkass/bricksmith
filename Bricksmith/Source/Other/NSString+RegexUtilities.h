//
//  NSString+RegexUtilities.h
//  Bricksmith
//
//  Created by Daniel Jalkut on 4/27/15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (RegexUtilities)

- (BOOL) brick_isMatchedByRegex:(NSString*)regexString;
- (NSArray*) brick_arrayOfCaptureComponentsMatchedByRegex:(NSString*)regexString;

@end
