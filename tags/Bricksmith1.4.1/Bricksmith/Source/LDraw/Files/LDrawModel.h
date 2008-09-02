//==============================================================================
//
// File:		LDrawModel.h
//
// Purpose:		Represents a collection of Lego bricks that form a single model.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawContainer.h"
@class LDrawFile;
@class LDrawStep;

typedef enum {
	LDrawOfficialModel = 1,
	LDrawUnofficialModel = 2
} LDrawDotOrgModelStatusT;

@interface LDrawModel : LDrawContainer <NSCoding> {
	
	NSString				*modelDescription;
	NSString				*fileName;
	NSString				*author;
	LDrawDotOrgModelStatusT	 ldrawDotOrgStatus;
	
	Box3					*cachedBounds; //used only for optimized parts
	BOOL					 stepDisplayActive; //YES if we are only display steps 1-currentStepDisplayed
	int						 currentStepDisplayed; //display up to and including this step index
	
	//steps are stored in the superclass.
}

//Initialization
+ (id) newModel;
+ (id) modelWithLines:(NSArray *)lines;
- (id) initNew;
- (id) initWithLines:(NSArray *)lines;

//Accessors
- (NSString *) category;
- (LDrawFile *)enclosingFile;
- (NSString *)modelDescription;
- (NSString *)fileName;
- (NSString *)author;
- (LDrawDotOrgModelStatusT) ldrawRepositoryStatus;
- (int) maximumStepDisplayed;
- (BOOL) stepDisplay;
- (NSArray *) steps;
- (LDrawStep *) visibleStep;

- (void) setModelDescription:(NSString *)newDescription;
- (void) setFileName:(NSString *)newName;
- (void) setAuthor:(NSString *)newAuthor;
- (void) setLDrawRepositoryStatus:(LDrawDotOrgModelStatusT) newStatus;
- (void) setStepDisplay:(BOOL)flag;
- (void) setMaximumStepDisplayed:(int)stepIndex;

//Actions
- (LDrawStep *) addStep;
- (void) addStep:(LDrawStep *)newStep;
- (void) makeStepVisible:(LDrawStep *)step;

//Utilities
- (int) maxStepIndexToOutput;
- (int) numberElements;
- (void) optimize;
- (NSArray *) parseHeaderFromLines:(NSArray *) lines;
- (BOOL) line:(NSString *)line isValidForHeader:(NSString *)headerKey;

@end
