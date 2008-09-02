//==============================================================================
//
// File:		PartLibrary.m
//
// Purpose:		This is the centralized repository for obtaining information 
//				about the contents of the LDraw folder.
//
//  Created by Allen Smith on 3/12/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>
@class AMSProgressPanel;
@class LDrawModel;
@class LDrawPart;

#import "LDrawColor.h"

@interface PartLibrary : NSObject {

	NSDictionary		*partCatalog;
	NSMutableDictionary	*loadedFiles; //list of LDrawFiles which have been read off disk.
	NSMutableDictionary	*fileDisplayLists; //access stored display lists by part name, then color.
}

//Initialization
- (BOOL) loadPartCatalog;

//Accessors
- (NSDictionary *) partCatalog;
- (void) setPartCatalog:(NSDictionary *)newCatalog;

//Actions
- (void)reloadParts:(id)sender;

//Finding Parts
- (LDrawModel *) modelForName:(NSString *) partName;
- (LDrawModel *) modelForPart:(LDrawPart *) part;
- (NSString *) pathForPartName:(NSString *)partName;
- (LDrawModel *) modelFromNeighboringFileForPart:(LDrawPart *)part;
- (int) retainDisplayListForPart:(LDrawPart *)part color:(LDrawColorT)color;

//Utilites
- (void) addPartsInFolder:(NSString *)folderPath
				toCatalog:(NSMutableDictionary *)catalog
			underCategory:(NSString *)category
			   namePrefix:(NSString *)namePrefix
			progressPanel:(AMSProgressPanel	*)progressPanel;
- (NSString *)categoryForDescription:(NSString *)modelDescription;
- (NSString *)categoryForPart:(LDrawPart *)part;
- (NSString *)descriptionForPart:(LDrawPart *)part;
- (NSString *)descriptionForPartName:(NSString *)name;
- (NSString *) descriptionForFilePath:(NSString *)filepath;
- (LDrawModel *) readModelAtPath:(NSString *)partPath partName:(NSString *)partName;
- (BOOL) validateLDrawFolder:(NSString *) folderPath;
- (BOOL) validateLDrawFolderWithMessage:(NSString *) folderPath;

@end
