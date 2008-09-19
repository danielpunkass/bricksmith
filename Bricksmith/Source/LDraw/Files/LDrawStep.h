//==============================================================================
//
// File:		LDrawStep.h
//
// Purpose:		Represents a collection of Lego bricks which compose a single 
//				step when constructing a model.
//
//  Created by Allen Smith on 2/20/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "ColorLibrary.h"
#import "LDrawContainer.h"

@class LDrawModel;

////////////////////////////////////////////////////////////////////////////////
//
// Types & Constants
//
////////////////////////////////////////////////////////////////////////////////

typedef enum
{
	LDrawStepRotationNone		= 0,	// inherit previous step rotation (or default view)
	LDrawStepRotationRelative	= 1,	// rotate relative to default 3D viewing angle
	LDrawStepRotationAbsolute	= 2,	// rotate relative to (0, 0, 0)
	LDrawStepRotationAdditive	= 3,	// rotate relative to the previous step's rotation
	LDrawStepRotationEnd		= 4		// cancel the effect of the previous rotation

} LDrawStepRotationT;


//Describes the contents of this step.
typedef enum
{
	LDrawStepAnyDirectives,		//step can hold any type of subdirectives.
	LDrawStepLines,				//step can hold *only* LDrawLines.
	LDrawStepTriangles,			// etc.
	LDrawStepQuadrilaterals,	// etc.
	LDrawStepConditionalLines	// etc.
	
} LDrawStepFlavorT;


////////////////////////////////////////////////////////////////////////////////
//
// class LDrawStep
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawStep : LDrawContainer
{
	LDrawStepRotationT	stepRotationType;
	Tuple3				rotationAngle;		// in degrees

	//Optimization variables
	LDrawStepFlavorT	stepFlavor; //defaults to LDrawStepAnyDirectives
	LDrawColorT			colorOfAllDirectives;
	
	BOOL				hasDisplayList;
	GLuint				displayListTag;	//list ID for normals in non-inverted matrix

	//Inherited from the superclasses:
	//NSMutableArray	*containedObjects; //the commands that make up the step.
	//LDrawContainer	*enclosingDirective; //weak link to enclosing model.
}

//Initialization
+ (id) emptyStep;
+ (id) emptyStepWithFlavor:(LDrawStepFlavorT) flavorType;
+ (LDrawStep *) stepWithLines:(NSArray *)lines;

//Directives
- (NSString *) writeWithStepCommand:(BOOL) flag;

//Accessors
- (void) addDirective:(LDrawDirective *)newDirective;
- (LDrawModel *) enclosingModel;
- (Tuple3) rotationAngle;
- (LDrawStepRotationT) stepRotationType;

- (void) setModel:(LDrawModel *)enclosingModel;
- (void) setRotationAngle:(Tuple3)newAngle;
- (void) setStepFlavor:(LDrawStepFlavorT)newFlavor;
- (void) setStepRotationType:(LDrawStepRotationT)newValue;

//Utilities
- (void) optimize;

@end
