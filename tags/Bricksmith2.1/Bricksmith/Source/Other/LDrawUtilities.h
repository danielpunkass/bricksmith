//==============================================================================
//
// File:		LDrawUtilities.h
//
// Purpose:		Convenience routines for managing LDraw directives.
//
//  Created by Allen Smith on 2/28/06.
//  Copyright 2006. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "MatrixMath.h"
#import "LDrawGLView.h"

@class LDrawPart;

@interface LDrawUtilities : NSObject
{

}

+ (Tuple3) angleForViewOrientation:(ViewOrientationT)orientation;
+ (Box3) boundingBox3ForDirectives:(NSArray *)directives;
+ (Class) classForLineType:(int)lineType;
+ (NSImage *) dragImageWithOffset:(NSPointPointer)dragImageOffset;
+ (BOOL) isLDrawFilenameValid:(NSString *)fileName;
+ (NSString *) readNextField:(NSString *) partialDirective
				   remainder:(NSString **) remainder;
+ (NSString *) stringFromFile:(NSString *)path;
+ (void) updateNameForMovedPart:(LDrawPart *)movedPart;
+ (ViewOrientationT) viewOrientationForAngle:(Tuple3)rotationAngle;

@end
