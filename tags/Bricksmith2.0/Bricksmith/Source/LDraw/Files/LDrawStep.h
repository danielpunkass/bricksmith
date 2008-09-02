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
- (void) setModel:(LDrawModel *)enclosingModel;
- (void) setStepFlavor:(LDrawStepFlavorT)newFlavor;

//Utilities
- (void) optimize;

@end
