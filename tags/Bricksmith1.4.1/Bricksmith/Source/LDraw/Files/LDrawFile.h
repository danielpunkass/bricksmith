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
@class LDrawMPDModel;


@interface LDrawFile : LDrawContainer {
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
- (void) addSubmodel:(LDrawMPDModel *)newSubmodel;
- (NSArray *) modelNames;
- (LDrawMPDModel *) modelWithName:(NSString *)soughtName;
- (NSString *)path;
- (NSArray *) submodels;
- (LDrawMPDModel *) activeModel;
- (void) setActiveModel:(LDrawMPDModel *)newModel;
- (void) setPath:(NSString *)newPath;

//Utilities
- (void) optimize;
- (void) setNeedsDisplay;
+ (NSString *) stringFromFile:(NSString *)path;

@end
