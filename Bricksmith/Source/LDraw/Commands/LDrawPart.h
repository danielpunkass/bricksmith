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
#import <OpenGL/gl.h>

#import "ColorLibrary.h"
#import "LDrawDirective.h"
#import "LDrawDrawableElement.h"
#import "MatrixMath.h"

@class LDrawFile;
@class LDrawModel;
@class LDrawStep;
@class PartReport;


////////////////////////////////////////////////////////////////////////////////
//
// Class:		LDrawPart
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawPart : LDrawDrawableElement <NSCoding>
{
	NSString		*displayName;
	NSString		*referenceName; //lower-case version of display name
	
	GLfloat			glTransformation[16];

	BOOL			hasDisplayList;
	GLuint			displayListTag;	//list ID for normals in non-inverted matrix
	NSLock			*drawLock;
}

//Directives
- (void) drawBounds;
- (NSString *) write;

//Accessors
- (NSString *) displayName;
- (LDrawFile *) enclosingFile;
- (LDrawStep *) enclosingStep;
- (Point3) position;
- (NSString *) referenceName;
- (LDrawModel *) referencedMPDSubmodel;
- (TransformComponents) transformComponents;
- (Matrix4) transformationMatrix;
- (void) setDisplayName:(NSString *)newPartName;
- (void) setTransformComponents:(TransformComponents)newComponents;
- (void) setTransformationMatrix:(Matrix4 *)newMatrix;

//Actions
- (void) collectPartReport:(PartReport *)report;
- (TransformComponents) componentsSnappedToGrid:(float) gridSpacing minimumAngle:(float)degrees;
- (TransformComponents) components:(TransformComponents)components snappedToGrid:(float)gridSpacing minimumAngle:(float)degrees;
- (void) rotateByDegrees:(Tuple3)degreesToRotate;
- (void) rotateByDegrees:(Tuple3)degreesToRotate centerPoint:(Point3)center;

//Utilities
- (void) optimizeOpenGL;
- (void) removeDisplayList;

@end
