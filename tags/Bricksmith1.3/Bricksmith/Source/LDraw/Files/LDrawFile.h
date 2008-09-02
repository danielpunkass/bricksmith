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
}

//Initialization
+ (LDrawFile *) newFile;
+ (LDrawFile *) fileFromContentsOfFile:(NSString *)path;
+ (LDrawFile *) parseFromFileContents:(NSString *) fileContents;
+ (NSArray *) parseModelsFromLines:(NSArray *) linesFromFile;
- (id) initNew;

//Accessors
- (void) addSubmodel:(LDrawMPDModel *)newSubmodel;
- (NSArray *) modelNames;
- (LDrawMPDModel *) modelWithName:(NSString *)soughtName;
- (NSArray *) submodels;
- (LDrawMPDModel *) activeModel;
- (void) setActiveModel:(LDrawMPDModel *)newModel;

//Utilities
- (void) optimize;
- (void) setNeedsDisplay;

@end
