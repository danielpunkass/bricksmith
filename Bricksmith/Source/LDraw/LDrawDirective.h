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
#import <Cocoa/Cocoa.h>

#import "LDrawColor.h"
#import "MatrixMath.h"

@class LDrawContainer;

@interface LDrawDirective : NSObject <NSCoding, NSCopying> {

	LDrawContainer *enclosingDirective; //LDraw files are a hierarchy.
	BOOL			isSelected;
	
}

//Initialization
+ (id) directiveWithString:(NSString *)lineFromFile;

//Directives
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor;
- (NSString *) write;

//Display
- (NSString *)browsingDescription;
- (NSString *) iconName;
- (NSString *) inspectorClassName;

//Accessors
- (NSArray *)ancestors;
- (LDrawContainer *) enclosingDirective;
- (void) setEnclosingDirective:(LDrawContainer *)newParent;
- (void) setSelected:(BOOL)flag;

//Utilities
- (void) registerUndoActions:(NSUndoManager *)undoManager;
- (void) snapshot;
- (BOOL)isAncestorInList:(NSArray *)containers;
+ (Box3) boundingBox3ForDirectives:(NSArray *)directives;
+ (Class) classForLineType:(int)lineType;
+ (NSString *) readNextField:(NSString *) partialDirective
				   remainder:(NSString **) remainder;

@end
