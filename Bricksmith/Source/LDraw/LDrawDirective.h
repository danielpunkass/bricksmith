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
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#import "ObjectInspectionController.h"

@class LDrawContainer;
@class LDrawFile;


////////////////////////////////////////////////////////////////////////////////
//
// LDrawDirective
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawDirective : NSObject <NSCoding, NSCopying, Inspectable>
{

	LDrawContainer *enclosingDirective; //LDraw files are a hierarchy.
	BOOL			isSelected;
	
}

//Initialization
+ (id) directiveWithString:(NSString *)lineFromFile;

//Directives
- (void) draw:(NSUInteger) optionsMask parentColor:(GLfloat *)parentColor;
- (NSString *) write;

//Display
- (NSString *) browsingDescription;
- (NSString *) iconName;
- (NSString *) inspectorClassName;

//Accessors
- (NSArray *)ancestors;
- (LDrawContainer *) enclosingDirective;
- (LDrawFile *) enclosingFile;
- (BOOL) isSelected;

- (void) setEnclosingDirective:(LDrawContainer *)newParent;
- (void) setSelected:(BOOL)flag;

//protocol Inspectable
- (void) snapshot;
- (void) lockForEditing;
- (void) unlockEditor;

//Utilities
- (BOOL) isAncestorInList:(NSArray *)containers;
- (void) optimizeOpenGL;
- (void) registerUndoActions:(NSUndoManager *)undoManager;

@end
