//==============================================================================
//
// File:		LDrawFile.h
//
// Purpose:		Represents an LDraw file, composed of one or more models.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawDirective.h"
#import "LDrawContainer.h"

// forward declarations
@class LDrawMPDModel;


////////////////////////////////////////////////////////////////////////////////
//
// class LDrawFile
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawFile : LDrawContainer
{
	LDrawMPDModel		*activeModel;
	NSString			*filePath;			//where this file came from on disk.
	unsigned			 drawCount;			//number of threads currently drawing us
	NSConditionLock		*editLock;
}

//Initialization
+ (LDrawFile *) newFile;
+ (LDrawFile *) fileFromContentsAtPath:(NSString *)path;
+ (LDrawFile *) parseFromFileContents:(NSString *) fileContents;
+ (NSArray *) parseModelsFromLines:(NSArray *) linesFromFile;
- (id) initNew;

//Directives
- (void) lockForEditing;
- (void) unlockEditor;

//Accessors
- (LDrawMPDModel *) activeModel;
- (void) addSubmodel:(LDrawMPDModel *)newSubmodel;
- (NSArray *) draggingDirectives;
- (NSArray *) modelNames;
- (LDrawMPDModel *) modelWithName:(NSString *)soughtName;
- (NSString *)path;
- (NSArray *) submodels;

- (void) setActiveModel:(LDrawMPDModel *)newModel;
- (void) setDraggingDirectives:(NSArray *)directives;
- (void) setPath:(NSString *)newPath;

//Utilities
- (void) optimize;
- (void) setNeedsDisplay;

@end
