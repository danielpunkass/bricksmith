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
#import <OpenGL/GL.h>

@class LDrawContainer;
@class LDrawFile;

@protocol Inspectable;

@interface LDrawDirective : NSObject <NSCoding, NSCopying, Inspectable> {

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
- (LDrawFile *) enclosingFile;
- (void) setEnclosingDirective:(LDrawContainer *)newParent;
- (void) setSelected:(BOOL)flag;

//protocol Inspectable
- (void) snapshot;
- (void) lockForEditing;
- (void) unlockEditor;

//Utilities
- (BOOL)isAncestorInList:(NSArray *)containers;
- (void) registerUndoActions:(NSUndoManager *)undoManager;

@end
