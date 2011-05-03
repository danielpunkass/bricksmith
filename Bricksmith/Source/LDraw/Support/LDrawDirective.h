//==============================================================================
//
// File:		LDrawDirective.h
//
// Purpose:		This is an abstract base class for all elements of an LDraw 
//				document.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Foundation/Foundation.h>
#import OPEN_GL_HEADER

#import "MatrixMath.h"

@class LDrawColor;
@class LDrawContainer;
@class LDrawFile;
@class LDrawModel;
@class LDrawStep;


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Drawing Mask bits and Constants
//
////////////////////////////////////////////////////////////////////////////////
#define DRAW_NO_OPTIONS							0
#define DRAW_HIT_TEST_MODE						1 << 1
#define DRAW_BOUNDS_ONLY						1 << 3


////////////////////////////////////////////////////////////////////////////////
//
// LDrawDirective
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawDirective : NSObject <NSCoding, NSCopying>
{

	LDrawContainer *enclosingDirective; //LDraw files are a hierarchy.
	BOOL			isSelected;
	
}

// Initialization
- (id) initWithLines:(NSArray *)lines inRange:(NSRange)range;
- (id) initWithLines:(NSArray *)lines inRange:(NSRange)range parentGroup:(dispatch_group_t)parentGroup;
+ (NSRange) rangeOfDirectiveBeginningAtIndex:(NSUInteger)index inLines:(NSArray *)lines maxIndex:(NSUInteger)maxIndex;

// Directives
- (void) draw:(NSUInteger) optionsMask parentColor:(LDrawColor *)parentColor;
- (NSString *) write;

// Display
- (NSString *) browsingDescription;
- (NSString *) iconName;
- (NSString *) inspectorClassName;

// Accessors
- (NSArray *)ancestors;
- (LDrawContainer *) enclosingDirective;
- (LDrawFile *) enclosingFile;
- (LDrawModel *) enclosingModel;
- (BOOL) isSelected;

- (void) setEnclosingDirective:(LDrawContainer *)newParent;
- (void) setSelected:(BOOL)flag;

// protocol Inspectable
- (void) lockForEditing;
- (void) unlockEditor;

// Utilities
- (void) flattenIntoLines:(NSMutableArray *)lines
				triangles:(NSMutableArray *)triangles
		   quadrilaterals:(NSMutableArray *)quadrilaterals
					other:(NSMutableArray *)everythingElse
			 currentColor:(LDrawColor *)parentColor
		 currentTransform:(Matrix4)transform
		  normalTransform:(Matrix3)normalTransform
				recursive:(BOOL)recursive;
- (BOOL) isAncestorInList:(NSArray *)containers;
- (void) optimizeOpenGL;
- (void) registerUndoActions:(NSUndoManager *)undoManager;

@end
