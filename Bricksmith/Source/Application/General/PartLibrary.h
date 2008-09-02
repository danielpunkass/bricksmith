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

@interface PartLibrary : NSObject {

	NSDictionary		*partCatalog;
	NSMutableDictionary	*loadedFiles; //list of LDrawFiles which have been read off disk.
}

//Initialization
- (BOOL) loadPartCatalog;

//Accessors
- (NSDictionary *) partCatalog;
- (void) setPartCatalog:(NSDictionary *)newCatalog;

//Actions
- (void)reloadParts:(id)sender;

//Utilites
- (void) addPartsInFolder:(NSString *)folderPath
				toCatalog:(NSMutableDictionary *)catalog
			underCategory:(NSString *)category
			   namePrefix:(NSString *)namePrefix
			progressPanel:(AMSProgressPanel	*)progressPanel;
- (NSString *)categoryForDescription:(NSString *)modelDescription;
- (NSString *)descriptionForPart:(LDrawPart *)part;
- (NSString *)descriptionForPartName:(NSString *)name;
- (LDrawModel *) modelForName:(NSString *) partName;
- (LDrawModel *) modelForPart:(LDrawPart *) part;
- (NSString *) partDescriptionForFile:(NSString *)filepath;
- (NSString *) pathForFileName:(NSString *)partName;
- (BOOL) validateLDrawFolder:(NSString *) folderPath;
- (BOOL) validateLDrawFolderWithMessage:(NSString *) folderPath;

@end
