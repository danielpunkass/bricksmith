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

#import "LDrawDirective.h"
#import "MatrixMath.h"

@interface LDrawDrawableElement : LDrawDirective <LDrawColorable, NSCoding> {
	
	LDrawColorT		color;
	GLfloat			glColor[4]; //OpenGL equivalent of the LDrawColor.
}

//Directives
- (void) drawElement:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor;

//Accessors
- (Box3) boundingBox3;
-(LDrawColorT) LDrawColor;
-(void) setLDrawColor:(LDrawColorT)newColor;

//Actions
- (void) nudge:(Vector3)nudgeVector;

@end
