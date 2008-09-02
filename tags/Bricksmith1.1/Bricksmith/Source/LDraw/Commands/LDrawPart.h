//==============================================================================
//
// File:		LDrawPart.h
//
// Purpose:		Part command.
//				Inserts a part defined in another LDraw file.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawDirective.h"
#import "LDrawDrawableElement.h"
#import "LDrawColor.h"
#import <OpenGL/gl.h>
#import "MatrixMath.h"

@class LDrawModel;
@class LDrawStep;
@class PartReport;

@interface LDrawPart : LDrawDrawableElement <NSCoding> {
	
	NSString		*displayName;
	NSString		*referenceName; //lower-case version of display name
	
	GLfloat			glTransformation[16];
	BOOL			matrixIsReversed;
}

//Initialization
+ (LDrawPart *) partWithDirectiveText:(NSString *)directive;

//Directives
- (void) drawBounds;
- (NSString *) write;

//Accessors
- (LDrawStep *) enclosingStep;
- (NSString *) displayName;
- (NSString *) referenceName;
- (LDrawModel *) referencedMPDSubmodel;
- (TransformationComponents) transformationComponents;
- (Matrix4) transformationMatrix;
- (void) setDisplayName:(NSString *)newPartName;
- (void) setTransformationComponents:(TransformationComponents)newComponents;
- (void) setTransformationMatrix:(Matrix4 *)newMatrix;

//Actions
- (void) collectPartReport:(PartReport *)report;
- (TransformationComponents) componentsSnappedToGrid:(float) gridSpacing
										minimumAngle:(float)degrees;
- (void) rotateByDegrees:(Tuple3)degreesToRotate;

@end
