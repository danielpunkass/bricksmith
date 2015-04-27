//
//  NSString+RegexUtilities.m
//  Bricksmith
//
//  Created by Daniel Jalkut on 4/27/15.
//
//

#import "NSString+RegexUtilities.h"

@implementation NSString (RegexUtilities)

- (BOOL) brick_isMatchedByRegex:(NSString*)regexString
{
	return ([self rangeOfString:regexString options:NSRegularExpressionSearch].location != NSNotFound);
}

// From https://gist.github.com/rsattar/1896546
- (NSArray*) brick_arrayOfCaptureComponentsMatchedByRegex:(NSString*)regexString
{
    NSError *error = NULL;
    NSRegularExpression *regExpression = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSMutableArray *test = [NSMutableArray array];
    
    NSArray *matches = [regExpression matchesInString:self options:NSRegularExpressionSearch range:NSMakeRange(0, self.length)];
    
    for(NSTextCheckingResult *match in matches) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
        for(NSInteger i=0; i<match.numberOfRanges; i++) {
            NSRange matchRange = [match rangeAtIndex:i];
            NSString *matchStr = nil;
            if(matchRange.location != NSNotFound) {
                matchStr = [self substringWithRange:matchRange];
            } else {
                matchStr = @"";
            }
            [result addObject:matchStr];
        }
        [test addObject:result];
    }
    return test;
}

@end
