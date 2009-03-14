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

#import "ColorLibrary.h"

@class LDrawModel;
@class LDrawPart;
@protocol PartLibraryReloadPartsDelegate;

////////////////////////////////////////////////////////////////////////////////
//
// class PartLibrary
//
////////////////////////////////////////////////////////////////////////////////
@interface PartLibrary : NSObject
{
	NSDictionary		*partCatalog;
	NSMutableArray		*favorites;			// parts names in the "Favorites" pseduocategory
	NSMutableDictionary	*loadedFiles;		// list of LDrawFiles which have been read off disk.
	NSMutableDictionary	*fileDisplayLists;	// access stored display lists by part name, then color.
}

// Initialization

// Accessors
- (NSArray *) allPartNames;
- (NSArray *) categories;
- (NSArray *) favoritePartNames;
- (NSArray *) partNamesInCategory:(NSString *)category;
- (void) setPartCatalog:(NSDictionary *)newCatalog;

// Actions
- (BOOL) load;
- (BOOL) reloadPartsWithDelegate:(id <PartLibraryReloadPartsDelegate>)delegate;

// Favorites
- (void) addPartNameToFavorites:(NSString *)partName;
- (void) removePartNameFromFavorites:(NSString *)partName;
- (void) saveFavoritesToUserDefaults;

// Finding Parts
- (LDrawModel *) modelForName:(NSString *) partName;
- (LDrawModel *) modelForPart:(LDrawPart *) part;
- (NSString *) pathForPartName:(NSString *)partName;
- (LDrawModel *) modelFromNeighboringFileForPart:(LDrawPart *)part;
- (GLuint) retainDisplayListForPart:(LDrawPart *)part color:(GLfloat *)color;

// Utilites
- (void) addPartsInFolder:(NSString *)folderPath
				toCatalog:(NSMutableDictionary *)catalog
			underCategory:(NSString *)category
			   namePrefix:(NSString *)namePrefix
				 delegate:(id <PartLibraryReloadPartsDelegate>)delegate;
- (NSString *)categoryForDescription:(NSString *)modelDescription;
- (NSString *)categoryForPart:(LDrawPart *)part;
- (NSString *)descriptionForPart:(LDrawPart *)part;
- (NSString *)descriptionForPartName:(NSString *)name;
- (NSString *) descriptionForFilePath:(NSString *)filepath;
- (LDrawModel *) readModelAtPath:(NSString *)partPath partName:(NSString *)partName;
- (BOOL) validateLDrawFolder:(NSString *) folderPath;

@end


////////////////////////////////////////////////////////////////////////////////
//
// delegate PartLibraryReloadPartsDelegate
// (all methods are required)
//
////////////////////////////////////////////////////////////////////////////////
@protocol PartLibraryReloadPartsDelegate

- (void) partLibrary:(PartLibrary *)partLibrary maximumPartCountToLoad:(NSUInteger)maxPartCount;
- (void) partLibraryIncrementLoadProgressCount:(PartLibrary *)partLibrary;

@end