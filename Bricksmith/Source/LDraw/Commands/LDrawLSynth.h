//
//  LDrawLSynth.h
//  Bricksmith
//
//  Created by Robin Macharg on 16/11/2012.
//
//

#import "LDrawContainer.h"
#import "LDrawDrawableElement.h"
#import "ColorLibrary.h"

// Lsynth block parser states
typedef enum
{
    PARSER_READY             = 1,
    PARSER_CONSTRAINTS       = 2,
    PARSER_SYNTHESIZED_PARTS = 3,
    PARSER_STATE_COUNT
} LSynthParserStateT;

@interface LDrawLSynth : LDrawContainer <LDrawColorable>
{
    NSMutableArray  *synthesizedParts;
    NSString        *synthType;
    int              lsynthClass;
    LDrawColor      *color;
    GLfloat			 glTransformation[16];
    BOOL             hidden;
    BOOL             subdirectiveSelected;
}

// Accessors
- (void) setLsynthClass:(int)lsynthClass;
- (int) lsynthClass;
- (void) setLsynthType:(NSString *)lsynthType;
- (NSString *) lsynthType;
- (void) setHidden:(BOOL)flag;
- (BOOL) isHidden;

- (TransformComponents) transformComponents;

// Utilities
- (void) synthesize;
- (void) colorSynthesizedPartsTranslucent:(BOOL)yesNo;
- (void) dragDropDonateCleanup;
+ (BOOL) lineIsLSynthBeginning:(NSString*)line;
@end
