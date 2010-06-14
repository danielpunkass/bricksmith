//==============================================================================
//
// File:		LDrawDrawableElement.h
//
// Purpose:		Abstract superclass for all LDraw elements that can actually be 
//				drawn (polygons and parts).
//
//  Created by Allen Smith on 4/20/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "ColorLibrary.h"
#import "LDrawDirective.h"
#import "MatrixMath.h"

////////////////////////////////////////////////////////////////////////////////
//
// class LDrawDrawableElement
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawDrawableElement : LDrawDirective <LDrawColorable, NSCoding>
{
	LDrawColorT		color;
	GLfloat			glColor[4]; //OpenGL equivalent of the LDrawColor.
	BOOL			hidden;		//YES if we don't draw this.
}

// Directives
- (void) drawElement:(NSUInteger) optionsMask withColor:(GLfloat *)drawingColor;

// Accessors
- (Box3) boundingBox3;
- (Box3) projectedBoundingBoxWithModelView:(const GLdouble *)modelViewGLMatrix
								projection:(const GLdouble *)projectionGLMatrix
									  view:(const GLint *)viewport;
- (BOOL) isHidden;
- (LDrawColorT) LDrawColor;
- (Point3) position;

- (void) setHidden:(BOOL)flag;
- (void) setLDrawColor:(LDrawColorT)newColor;
- (void) setRGBColor:(GLfloat *)glColorIn;

// Actions
- (Vector3) displacementForNudge:(Vector3)nudgeVector;
- (void) moveBy:(Vector3)moveVector;
- (Point3) position:(Point3)position snappedToGrid:(float)gridSpacing;

@end
