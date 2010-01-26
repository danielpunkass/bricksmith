//==============================================================================
//
// File:		PartLibrary.m
//
// Purpose:		This is the centralized repository for obtaining information 
//				about the contents of the LDraw folder. The part library is 
//				first created by scanning the LDraw folder and collecting all 
//				the part names, categories, and drawing instructions for each 
//				part. This information is then saved into an XML file and 
//				retrieved each time the program is relaunched. During runtime, 
//				other objects query the part library to draw and display 
//				information about parts.
//
//  Created by Allen Smith on 3/12/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "PartLibrary.h"

#import "LDrawApplication.h"
#import "LDrawFile.h"
#import "LDrawModel.h"
#import "LDrawPart.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"

@implementation PartLibrary

//========== init ==============================================================
//
// Purpose:		Creates a part library with no parts loaded.
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	loadedFiles			= [[NSMutableDictionary dictionaryWithCapacity:400] retain];
	fileDisplayLists	= [[NSMutableDictionary dictionaryWithCapacity:400] retain];
	
	favorites			= [[[NSUserDefaults standardUserDefaults] objectForKey:FAVORITE_PARTS_KEY] mutableCopy];
	
	[self setPartCatalog:[NSDictionary dictionary]];
	
	return self;
	
}//end init


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== allPartNames ======================================================
//
// Purpose:		Returns all the part numbers in the library.
//
//==============================================================================
- (NSArray *) allPartNames
{
	// all the reference numbers for parts.
	return [[self->partCatalog objectForKey:PARTS_LIST_KEY] allKeys];
	
}//end allPartNames


//========== categories ========================================================
//
// Purpose:		Returns all the categories in the library, sorted in no 
//				particular order. 
//
//==============================================================================
- (NSArray *) categories
{
	return [[self->partCatalog objectForKey:PARTS_CATALOG_KEY] allKeys];
	
}//end categories


//========== favoritePartNames =================================================
//
// Purpose:		Returns all the part names the user has bookmarked as his 
//				favorites. 
//
//==============================================================================
- (NSArray *) favoritePartNames
{
	return self->favorites;
	
}//end favoritePartNames


//========== partNamesInCategory: ==============================================
//
// Purpose:		Returns all the parts in the given category. Returns nil if the 
//				category doesn't exist. 
//
//==============================================================================
- (NSArray *) partNamesInCategory:(NSString *)categoryName
{
	NSArray *category   = [[partCatalog objectForKey:PARTS_CATALOG_KEY] objectForKey:categoryName];
	NSArray *parts      = nil;
	
	if(category != nil)
	{
		parts = [category valueForKey:PART_NUMBER_KEY];
	}
	
	return parts;

}//end partNamesInCategory:


//========== setPartCatalog ====================================================
//
// Purpose:		Saves the local instance of the part catalog, which should be 
//				the only copy of it in the program. Use +setSharedPartCatalog to 
//				update it outside this class.
//
// Notes:		The Part Catalog is structured as follows:
//
//				partCatalog
//				|
//				|--> PARTS_CATALOG_KEY <NSDictionary>
//				|		|
//				|		Keys  are category names, e.g., "Brick"
//				|		<NSArray>
//				|			|
//				|			<NSDictionary>
//				|				|--> PART_NUMBER_KEY <NSString> (e.g., "3001.dat")
//				|				|--> PART_NAME_KEY <NSString> (e.g., "Brick 2 x 4")
//				|
//				|--> PARTS_LIST_KEY <NSDictionary>
//						|
//						Keys are part reference numbers, e.g., "3001.dat"
//						<NSDictionary>
//							|--> PART_NUMBER_KEY
//							|--> PART_NAME_KEY
//
//				This data structure is PRIVATE. There is no get accessor. Query 
//				this object for its part lists and build your own records.
//
//==============================================================================
- (void) setPartCatalog:(NSDictionary *)newCatalog
{
	[newCatalog retain];
	[partCatalog release];
	
	partCatalog = newCatalog;
	
	//Inform any open parts browsers of the change.
	[[NSNotificationCenter defaultCenter] 
			postNotificationName: LDrawPartLibraryDidChangeNotification
						  object: self ];
	
}//end setPartCatalog


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== load ==============================================================
//
// Purpose:		Loads the catalog from the part list stashed in the LDraw 
//				folder. 
//
// Returns:		NO if no part list exists. (You need to call -reloadParts: in 
//				PartLibraryController then.) 
//
//==============================================================================
- (BOOL) load
{
	NSUserDefaults  *userDefaults   = [NSUserDefaults standardUserDefaults];
	NSFileManager   *fileManager    = [NSFileManager defaultManager];
	
	NSString        *ldrawPath      = [userDefaults stringForKey:LDRAW_PATH_KEY];
	NSString        *pathToPartList = nil;
	BOOL            partsListExists = NO;
	NSDictionary	*newCatalog		= nil;
	
	// Do we have an LDraw folder?
	if(ldrawPath != nil)
	{
		pathToPartList = [ldrawPath stringByAppendingPathComponent:PART_CATALOG_NAME];
		
		if([fileManager fileExistsAtPath:pathToPartList])
			partsListExists = YES;
	}
	
	// Do we have a part list already? 
	if(partsListExists == YES)
	{
		newCatalog = [NSDictionary dictionaryWithContentsOfFile:pathToPartList];
		
		[self setPartCatalog:newCatalog];
	}
	
	return partsListExists;

}//end load


//========== reloadParts: ======================================================
//
// Purpose:		Scans the contents of the LDraw/ folder and produces a 
//				Mac-friendly index of parts.
//
//				Is it fast? No. Is it easy to code? Yes.
//
//				Someday in the rosy future, this method should be recoded to 
//				simply traverse the directory tree and deal with subfolders on 
//				the fly. But that's not how it is now. Instead, I'm doing it 
//				all manually. Folders searched are:
//
//				LDraw/p/
//				LDraw/p/48/
//
//				LDraw/parts/
//				LDraw/parts/s/
//
//				LDraw/Unofficial/p/
//				LDraw/Unofficial/p/48/
//				LDraw/Unofficial/parts/
//				LDraw/Unofficial/parts/s/
//
//				It is important that the part name added to the library bear 
//				the correct reference style. For LDraw/p/ and LDraw/parts/, it 
//				is simply the filename (in lowercase). But for subdirectories, 
//				the filename must be prefixed with the subdirectory in DOS 
//				format, i.e., "s\file.dat" or "48\file.dat".
//
//==============================================================================
- (BOOL) reloadPartsWithDelegate:(id <PartLibraryReloadPartsDelegate>)delegate
{
	NSFileManager		*fileManager		= [NSFileManager defaultManager];
	NSUserDefaults		*userDefaults		= [NSUserDefaults standardUserDefaults];
	
	NSString			*ldrawPath			= [userDefaults stringForKey:LDRAW_PATH_KEY];
	NSString			*unofficialPath		= [ldrawPath stringByAppendingPathComponent:UNOFFICIAL_DIRECTORY_NAME]; //base for unofficial directories
	
	//make sure the LDraw folder is still valid; otherwise, why bother doing anything?
	if([self validateLDrawFolder:ldrawPath] == NO)
		return NO;
	
	//assemble all the pathnames to be searched.
	NSString            *primitivesPath             = [ldrawPath				stringByAppendingPathComponent:PRIMITIVES_DIRECTORY_NAME];
	NSString            *primitives48Path           = [primitivesPath			stringByAppendingPathComponent:PRIMITIVES_48_DIRECTORY_NAME];
	NSString            *partsPath                  = [ldrawPath				stringByAppendingPathComponent:PARTS_DIRECTORY_NAME];
	NSString            *subpartsPath               = [partsPath				stringByAppendingPathComponent:SUBPARTS_DIRECTORY_NAME];
	
	//search unofficial directories as well.
	NSString            *unofficialPrimitivesPath   = [unofficialPath			stringByAppendingPathComponent:PRIMITIVES_DIRECTORY_NAME];
	NSString            *unofficialPrimitives48Path = [unofficialPrimitivesPath	stringByAppendingPathComponent:PRIMITIVES_48_DIRECTORY_NAME];
	NSString            *unofficialPartsPath        = [unofficialPath			stringByAppendingPathComponent:PARTS_DIRECTORY_NAME];
	NSString            *unofficialSubpartsPath     = [unofficialPartsPath		stringByAppendingPathComponent:SUBPARTS_DIRECTORY_NAME];
	
	NSString            *partCatalogPath            = [ldrawPath				stringByAppendingPathComponent:PART_CATALOG_NAME];
	NSMutableDictionary *newPartCatalog             = [NSMutableDictionary dictionary];
	
	// Start the progress bar so that we know what's happening.
	NSUInteger			partCount					=		[[fileManager directoryContentsAtPath:primitivesPath] count]
														+	[[fileManager directoryContentsAtPath:primitives48Path] count]
														+	[[fileManager directoryContentsAtPath:partsPath] count]
														+	[[fileManager directoryContentsAtPath:subpartsPath] count]
														+	[[fileManager directoryContentsAtPath:unofficialPrimitivesPath] count]
														+	[[fileManager directoryContentsAtPath:unofficialPrimitives48Path] count]
														+	[[fileManager directoryContentsAtPath:unofficialPartsPath] count]
														+	[[fileManager directoryContentsAtPath:unofficialSubpartsPath] count];
	[delegate partLibrary:self maximumPartCountToLoad:partCount];
	
	
	//Create the new part catalog. We will then fill it with folder contents.
	[newPartCatalog setObject:[NSMutableDictionary dictionary] forKey:PARTS_CATALOG_KEY];
	[newPartCatalog setObject:[NSMutableDictionary dictionary] forKey:PARTS_LIST_KEY];
	
	
	//Scan for each part folder.
	[self addPartsInFolder:primitivesPath
				 toCatalog:newPartCatalog
			 underCategory:NSLocalizedString(@"Primitives", nil) //override all internal categories
				namePrefix:nil
				  delegate:delegate ];
	
	[self addPartsInFolder:primitives48Path
				 toCatalog:newPartCatalog
			 underCategory:NSLocalizedString(@"Primitives", nil) //override all internal categories
				namePrefix:[NSString stringWithFormat:@"%@\\", PRIMITIVES_48_DIRECTORY_NAME]
				  delegate:delegate ];
	
	[self addPartsInFolder:partsPath
				 toCatalog:newPartCatalog
			 underCategory:nil //pick up category names defined by parts
				namePrefix:nil
				  delegate:delegate ];
	
	[self addPartsInFolder:subpartsPath
				 toCatalog:newPartCatalog
			 underCategory:NSLocalizedString(@"Subparts", nil)
				namePrefix:[NSString stringWithFormat:@"%@\\", SUBPARTS_DIRECTORY_NAME] //prefix subpart numbers with the DOS path "s\"; that's just how it is. Yuck!
				  delegate:delegate ];
	
	
	//Scan unofficial part folders.
	[self addPartsInFolder:unofficialPrimitivesPath
				 toCatalog:newPartCatalog
			 underCategory:NSLocalizedString(@"Primitives", nil) //groups unofficial primitives with official primitives
			    namePrefix:nil //a directory deeper, but no DOS path separators to manage
				  delegate:delegate ];
	
	[self addPartsInFolder:unofficialPrimitives48Path
				 toCatalog:newPartCatalog
			 underCategory:NSLocalizedString(@"Primitives", nil)
				namePrefix:[NSString stringWithFormat:@"%@\\", PRIMITIVES_48_DIRECTORY_NAME]
				  delegate:delegate ];
	
	[self addPartsInFolder:unofficialPartsPath
				 toCatalog:newPartCatalog
			 underCategory:nil
				namePrefix:nil
				  delegate:delegate ];
	
	[self addPartsInFolder:unofficialSubpartsPath
				 toCatalog:newPartCatalog
			 underCategory:NSLocalizedString(@"Subparts", nil) //groups unofficial subparts with official subparts
				namePrefix:[NSString stringWithFormat:@"%@\\", SUBPARTS_DIRECTORY_NAME]
				  delegate:delegate ];
	
	//Save the part catalog out for future reference.
	[newPartCatalog writeToFile:partCatalogPath atomically:YES];
	[self setPartCatalog:newPartCatalog];
	
	// We succeeded in loading the parts!
	return YES;
	
}//end reloadParts:


#pragma mark -
#pragma mark FAVORITES
#pragma mark -

//========== addPartNameToFavorites: ===========================================
//
// Purpose:		Adds the given part name to the "Favorites" category.
//
//==============================================================================
- (void) addPartNameToFavorites:(NSString *)partName
{
	[self->favorites addObject:partName];
	[self saveFavoritesToUserDefaults];
	
	//Inform any open parts browsers of the change.
	[[NSNotificationCenter defaultCenter] 
			postNotificationName: LDrawPartLibraryDidChangeNotification
						  object: self ];
	
}//end addPartNameToFavorites:


//========== removePartNameFromFavorites: ======================================
//
// Purpose:		Removes the given part name to the "Favorites" category.
//
//==============================================================================
- (void) removePartNameFromFavorites:(NSString *)partName
{
	[self->favorites removeObject:partName];
	[self saveFavoritesToUserDefaults];
	
	//Inform any open parts browsers of the change.
	[[NSNotificationCenter defaultCenter] 
			postNotificationName: LDrawPartLibraryDidChangeNotification
						  object: self ];
	
}//end removePartNameFromFavorites:


//========== saveFavoritesToUserDefaults =======================================
//
// Purpose:		Writes the favorite parts list to preferences.
//
//==============================================================================
- (void) saveFavoritesToUserDefaults
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[userDefaults setObject:(self->favorites) forKey:FAVORITE_PARTS_KEY];
	
}//end saveFavoritesToUserDefaults


#pragma mark -
#pragma mark FINDING PARTS
#pragma mark -

//========== modelForName: =====================================================
//
// Purpose:		Attempts to find the part based only on the given name.
//				This method can only find parts in the LDraw folder; it returns 
//				nil if fed an MPD submodel name.
//
// Notes:		The part is looked up by the name specified in the part command. 
//				For regular parts and primitives, this is simply the filename 
//				as found in LDraw/parts or LDraw/p. But for subparts found in 
//				LDraw/parts/s, the filename is "s\partname.dat". (Same goes for 
//				LDraw/p/48.) This icky inconsistency is handled in 
//				-pathForFileName:.
//
//==============================================================================
- (LDrawModel *) modelForName:(NSString *) partName
{
	LDrawModel	*model		= nil;
	NSString	*partPath	= nil;
	
	//Try to get a live link if we have parsed this part off disk already.
	model = [self->loadedFiles objectForKey:partName];
	
	if(model == nil)
	{
		//Well, this means we have to try getting it off the disk!
		partPath	= [self pathForPartName:partName];
		model		= [self readModelAtPath:partPath partName:partName];
	}
	
	return model;
	
}//end modelForName


//========== modelForPart: =====================================================
//
// Purpose:		Returns the model to which this part refers. You can then ask
//				the model to draw itself.
//
// Notes:		The part is looked up by the name specified in the part command. 
//				For regular parts and primitives, this is simply the filename 
//				as found in LDraw/parts or LDraw/p. But for subparts found in 
//				LDraw/parts/s, the filename is "s\partname.dat". (Same goes for 
//				LDraw/p/48.) This icky inconsistency is handled in 
//				-pathForFileName:.
//
//==============================================================================
- (LDrawModel *) modelForPart:(LDrawPart *) part
{
	NSString	*partName	= [part referenceName];
	LDrawModel	*model		= nil;
	
	//Try to get a live link if we have parsed this part off disk already.
	model = [self modelForName:partName];
	
	if(model == nil) {
		//We didn't find it in the LDraw folder. Our last hope is for 
		// this to be a reference to another model in an MPD file.
		model = [part referencedMPDSubmodel];
	}
	
	if(model == nil) {
		//we're grasping at straws. See if this is a reference to an external 
		// file in the same folder.
		model = [self modelFromNeighboringFileForPart:part];
	}
	
	return model;
	
}//end modelForPart:


//========== pathForFileName: ==================================================
//
// Purpose:		Ferret out where this part is defined in the LDraw folder.
//				Parts can be defined in any of the following folders:
//				LDraw/p				(primitives)
//				LDraw/parts			(parts)
//				LDraw/parts/s		(subparts)
//				LDraw/unofficial	(unofficial parts root -- Allen's addition)
//
//				For regular parts and primitives, the partName is simply the 
//				filename as found in LDraw/parts or LDraw/p. But for subparts, 
//				partName is "s\partname.dat".
//
//				This method automatically converts any occurance of the DOS 
//				path-separator ('\') found in partName to the UNIX path separator 
//				('/'), then searches LDraw/parts/partName and LDraw/p/partName 
//				for the file. Thus, any subfolder can be specified this way, if 
//				the overlords of LDraw should choose to inflict another naming 
//				nightmare like this one.
//
// Returns:		The path of the part if it is found in one of the  folders, or 
//				nil if the part is not defined in the LDraw folder.
//
//==============================================================================
- (NSString *) pathForPartName:(NSString *)partName
{
	NSMutableString	*fixedPartName		= [NSMutableString stringWithString:partName];
	[fixedPartName replaceOccurrencesOfString:@"\\" //DOS path separator (doubled for escape-sequence)
								   withString:@"/"
									  options:0
										range:NSMakeRange(0, [fixedPartName length]) ];
	
	NSFileManager	*fileManager		= [NSFileManager defaultManager];
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
	
	NSString		*ldrawPath			= [userDefaults stringForKey:LDRAW_PATH_KEY];
	NSString		*unofficialPath		= [ldrawPath stringByAppendingPathComponent:UNOFFICIAL_DIRECTORY_NAME];
	
	NSString		*primitivesPath				= [NSString stringWithFormat:@"%@/%@/%@", ldrawPath,		PRIMITIVES_DIRECTORY_NAME,	fixedPartName];
	NSString		*partsPath					= [NSString stringWithFormat:@"%@/%@/%@", ldrawPath,		PARTS_DIRECTORY_NAME,		fixedPartName];
	NSString		*unofficialPrimitivesPath	= [NSString stringWithFormat:@"%@/%@/%@", unofficialPath,	PRIMITIVES_DIRECTORY_NAME,	fixedPartName];
	NSString		*unofficialPartsPath		= [NSString stringWithFormat:@"%@/%@/%@", unofficialPath,	PARTS_DIRECTORY_NAME,		fixedPartName];
	//searching in the subparts folder will be accomplished by fixedPartName --
	// remember, parts in subfolders of LDraw/parts and LDraw/p are referenced by 
	// their relative pathnames in DOS (e.g., "s\765s01.dat", which we converted 
	// to UNIX above.
	
	NSString		*partPath			= nil;
	
	//If we pass an empty string, we'll wind up test for directories' existences--
	// not what we want to do.
	if([partName length] == 0)
		partPath = nil;
	
	//We have a file path name; try each directory.
	else if([fileManager fileExistsAtPath:partsPath])
		partPath = partsPath;
	else if([fileManager fileExistsAtPath:primitivesPath])
		partPath = primitivesPath;
	else if([fileManager fileExistsAtPath:unofficialPartsPath])
		partPath = unofficialPartsPath;
	else if([fileManager fileExistsAtPath:unofficialPrimitivesPath])
		partPath = unofficialPrimitivesPath;
	
	return partPath;
	
}//end pathForPartName:


//========== modelFromNeighboringFileForPart: ==================================
//
// Purpose:		Attempts to resolve the part's name reference against a file 
//				located in the same parent folder as the file in which the part 
//				is contained.
//
//				This should be a method of last resort, after searching the part 
//				library and looking for an MPD reference.
//
// Note:		Once a model is found under this method, we READ AND CACHE IT.
//				You must RESTART Bricksmith to see any updates made to the 
//				referenced file. This feature is not intended to be convenient, 
//				bug-free, or industrial-strength. It is merely here to support 
//				the LDraw standard, and any files that may have been created 
//				under it.
//
//==============================================================================
- (LDrawModel *) modelFromNeighboringFileForPart:(LDrawPart *)part
{
	LDrawFile		*enclosingFile	= [part enclosingFile];
	NSString		*filePath		= [enclosingFile path];
	NSString		*partName		= nil;
	NSString		*testPath		= nil;
	LDrawModel		*model			= nil;
	NSFileManager	*fileManager	= nil;
	
	if(filePath != nil)
	{
		fileManager		= [NSFileManager defaultManager];
		
		//look at path = parentFolder/referenceName
		partName		= [part referenceName];
		testPath		= [filePath stringByDeletingLastPathComponent];
		testPath		= [testPath stringByAppendingPathComponent:partName];
		
		//see if it exists!
		if([fileManager fileExistsAtPath:testPath])
			model = [self readModelAtPath:testPath partName:partName];
	}
	
	return model;
	
}//end modelFromNeighboringFileForPart:


//========== retainDisplayListForPart:color: ===================================
//
// Purpose:		Returns the display list tag used to draw the given part. 
//				Display lists are shared among multiple part instances of the 
//				same name and color in order to reduce memory space.	
//
// Parameters:	part	- part to get/create a display list for.
//				color	- RGBA color for the part. We can't just ask the part for 
//						  its color because it might be LDrawCurrentColor, in 
//						  which case it is supposed to draw with its parent 
//						  color. 
//
//==============================================================================
- (GLuint) retainDisplayListForPart:(LDrawPart *) part
							  color:(GLfloat *) glColor
{
	GLuint				 displayListTag	= 0;
	NSString			*referenceName	= [part referenceName];
	NSMutableDictionary	*partRecord		= nil;
	NSString			*key			= [NSString stringWithFormat:@"%f %f %f %f", glColor[0], glColor[1], glColor[2], glColor[3] ];
	NSNumber			*listTag		= nil;
	
	if([referenceName length] > 0)
	{
		partRecord	= [self->fileDisplayLists objectForKey:referenceName];
		
		if(partRecord == nil)
		{
			// create a new record for hold list tags.
			partRecord = [NSMutableDictionary dictionary];
			[self->fileDisplayLists setObject:partRecord forKey:referenceName];
		}
		else
		{
			// try to get a previously-cached list for this part/color
			listTag = [partRecord objectForKey:key];
		}
	
		if(listTag != nil)
		{
			displayListTag = [listTag integerValue];
//			NSLog(@"found %d for %@ %d", displayListTag, referenceName, color);
		}
		else
		{
			LDrawModel	*modelToDraw = [self modelForPart:part];
			
			if(modelToDraw != nil)
			{
				// Do not recursively optimize all the referenced subparts. It's 
				// slower! (And it's even slower if you add a color parameter 
				// and create display lists for every subpart in the glColor.) 
//				[modelToDraw optimizeOpenGL];
				
				// Optimize the part itself into a display list.
				displayListTag = glGenLists(1);
				
				//Don't ask the part to draw itself, either. Parts modify the 
				//transformation matrix, and we want our display list to be 
				//independent of the transformation. So we shortcut part drawing 
				//and do the model itself. 
//				glPushMatrix();
//					glLoadIdentity();
					glNewList(displayListTag, GL_COMPILE);
						[modelToDraw draw:DRAW_FOR_DISPLAY_LIST_COMPILE parentColor:glColor];
					glEndList();
//				glPopMatrix();
				
				[partRecord setObject:[NSNumber numberWithUnsignedInteger:displayListTag]
							   forKey:key ];
				
//				NSLog(@"generated %d for %@ %d", displayListTag, referenceName, color);
			}
		}
	}
	
	
	return displayListTag;
	
}//end retainDisplayListForPart:color:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== addPartsInFolder:toCatalog:underCategory: =========================
//
// Purpose:		Scans all the parts in folderPath and adds them to the given 
//				catalog, filing them under the given category. Pass nil for 
//				category if you wish to use the categories defined in the parts 
//				themselves.
//
// Parameters:	categoryOverride	- force all parts in the folder to be filed 
//									  under this category, rather than the one 
//									  defined inside the part. 
//				namePrefix			- appends this prefix to each part scanned. 
//									  Part references in LDraw/parts/s should be 
//									  prefixed with the DOS path "s\". Pass nil 
//									  to ignore the prefix. 
//				progressPanel		- a progress panel which is displaying the 
//									  progress of the creation of the part 
//									  catalog. 
//
//==============================================================================
- (void) addPartsInFolder:(NSString *)folderPath
				toCatalog:(NSMutableDictionary *)catalog
			underCategory:(NSString *)categoryOverride
			   namePrefix:(NSString *)namePrefix
				 delegate:(id <PartLibraryReloadPartsDelegate>)delegate
{
	NSFileManager       *fileManager        = [NSFileManager defaultManager];
// Not working for some reason. Why?
//	NSArray				*readableFileTypes = [NSDocument readableTypes];
//	NSLog(@"readable types: %@", readableFileTypes);
	NSArray             *readableFileTypes  = [NSArray arrayWithObjects:@"dat", @"ldr", nil];
	
	NSArray             *partNames          = [fileManager directoryContentsAtPath:folderPath];
	NSUInteger          numberOfParts       = [partNames count];
	NSUInteger          counter;
	
	NSString            *currentPath        = nil;
	NSString            *category           = nil;
	NSString            *partDescription    = nil;
	NSString            *partNumber         = nil;
	
	NSMutableDictionary *categoryRecord     = nil;
	
	//Get the subreference tables out of the main catalog (the should already exist!).
	NSMutableDictionary *partNumberList		= [catalog objectForKey:PARTS_LIST_KEY]; //lookup parts by number
	NSMutableDictionary	*categories			= [catalog objectForKey:PARTS_CATALOG_KEY]; //lookup parts by category
	NSMutableArray		*currentCategory	= nil;
	
	
	
	//Loop through the entire contents of the directory and extract the 
	// information for every part therein.	
	for(counter = 0; counter < numberOfParts; counter++) 
	{
		currentPath = [folderPath stringByAppendingPathComponent:[partNames objectAtIndex:counter]];
		
		if([readableFileTypes containsObject:[currentPath pathExtension]] == YES)
		{
			partDescription		= [self descriptionForFilePath:currentPath];
			
			// Make sure the part file was valid!
			if(partDescription != nil)
			{
				if(categoryOverride == nil)
					category	= [self categoryForDescription:partDescription];
				else
					category	= categoryOverride;
				
				//Get the name of the part.
				// Also, we need a standard way to reference it. So we convert the 
				// string to lower-case. Note that parts in subfolders of LDraw/parts 
				// must have a name prefix of their subpath, e.g., "s\partname.dat" 
				// for a part in the LDraw/parts/s folder.
				partNumber		= [[currentPath lastPathComponent] lowercaseString];
				if(namePrefix != nil)
					partNumber = [namePrefix stringByAppendingString:partNumber];
				
				
				categoryRecord = [NSDictionary dictionaryWithObjectsAndKeys:
					partNumber,			PART_NUMBER_KEY,
					partDescription,	PART_NAME_KEY,
					nil ];
				
				//File the part by category
				currentCategory = [categories objectForKey:category];
				if(currentCategory == nil)
				{
					//We haven't encountered this category yet. Initialize it now.
					currentCategory = [NSMutableArray array];
					[categories setObject:currentCategory
								   forKey:category ];
				}
				[currentCategory addObject:categoryRecord];
				
				
				//Also file this part under its number.
				[partNumberList setObject:categoryRecord
								   forKey:partNumber ];
				
//				NSLog(@"processed %@", [partNames objectAtIndex:counter]);
			}
		}
		[delegate partLibraryIncrementLoadProgressCount:self];
		
	}//end loop through files
	
}//end addPartsInFolder:toCatalog:underCategory:


//========== categoryForDescription: ===========================================
//
// Purpose:		Returns the category for the given modelDescription. This is 
//				the first line of the file for non-MPD documents. For instance:
//
//				0 Brick  2 x  4
//
//				This part would be in the category "Brick", and has the 
//				description "Brick  2 x  4".
//
//==============================================================================
- (NSString *)categoryForDescription:(NSString *)modelDescription
{
	NSString	*category	= nil;
	NSRange		 firstSpace;			//range of the category string in the first line.
	
	//The category name is the first word in the description.
	firstSpace = [modelDescription rangeOfString:@" "];
	if(firstSpace.location != NSNotFound)
		category = [modelDescription substringToIndex:firstSpace.location];
	else
		category = [NSString stringWithString:modelDescription];
	
	
	// Deal with any weird notational marks
	
	// Alias parts begin with an underscore. These things are so annoying I'm 
	// going to dump them in a pseudo category. This is kind of a hack, but at 
	// least it's a prettifying one. 
	if([category hasPrefix:@"_"])
	{
		category = NSLocalizedString(@"AliasCategory", nil);
	}
	// Moved parts always begin with ~Moved, which is ugly. We'll strip the '~'.
	else if([category hasPrefix:@"~"])
	{
		category = [category substringFromIndex:1];
	}
	
	return category;
	
}//end categoryForDescription:


//========== categoryForPart: ==================================================
//
// Purpose:		Shortcut for categoryForDescription:
//
//==============================================================================
- (NSString *)categoryForPart:(LDrawPart *)part
{
	NSString *description = [self descriptionForPart:part];
	return [self categoryForDescription:description];
	
}//end categoryForPart:


//========== descriptionForPart: ===============================================
//
// Purpose:		Returns the description of the given part based on its name.
//
//==============================================================================
- (NSString *) descriptionForPart:(LDrawPart *)part
{
	//Look up the verbose part description in the scanned part catalog.
	NSDictionary	*partList			= [self->partCatalog	objectForKey:PARTS_LIST_KEY];
	NSDictionary	*partRecord			= [partList				objectForKey:[part referenceName]];
	NSString		*partDescription	= [partRecord			objectForKey:PART_NAME_KEY];
	
	// Maybe it's an MPD reference?
	if(partDescription == nil)
	{
		partDescription = [[part referencedMPDSubmodel] browsingDescription];
	}
	
	// If the part STILL isn't known, all we can really do is just display the 
	// number. 
	if(partDescription == nil)
	{
		partDescription = [part displayName];
	}
	
	return partDescription;
	
}//end descriptionForPart:


//========== descriptionForPartName: ===========================================
//
// Purpose:		Returns the description associated with the given part name. 
//				For example, passing "3001.dat" returns "Brick 2 x 4".
//				If the name isn't known to the Part Library, we just return name.
//
// Note:		If you have a reference to the LDrawPart itself, you should pass 
//				it to -descriptionForPart instead.
//
//==============================================================================
- (NSString *) descriptionForPartName:(NSString *)name
{
	//Look up the verbose part description in the scanned part catalog.
	NSDictionary	*partList			= [self->partCatalog	objectForKey:PARTS_LIST_KEY];
	NSDictionary	*partRecord			= [partList				objectForKey:name];
	NSString		*partDescription	= [partRecord			objectForKey:PART_NAME_KEY];
	//If the part isn't known, all we can really do is just display the number.
	if(partDescription == nil)
		partDescription = name;
	
	return partDescription;
	
}//end descriptionForPartName:


//========== descriptionForFilePath: ===========================================
//
// Purpose:		Pulls out the first line of the given file. By convention, the 
//				first line of an non-MPD LDraw file is the description; e.g.,
//
//				0 Brick  2 x  4
//
//				This part is thus in the category "Brick", and has the  
//				description "Brick  2 x  4".
//
// Returns:		nil if the file is not valid.
//
//==============================================================================
- (NSString *) descriptionForFilePath:(NSString *)filepath
{
	NSString		*fileContents		= nil;
	NSString		*partDescription	= nil;
	NSCharacterSet	*whitespace			= [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	// Read the file. I believe all official library files are supposed to be 
	// ASCII, but whatever. 
	fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:NULL];
	
	if(fileContents == nil)
		fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSISOLatin1StringEncoding error:NULL];
	
	if(fileContents == nil) // just use an encoding which is guaranteed defined for all codepoints.
		fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSMacOSRomanStringEncoding error:NULL];
	
	// Read the first line of the file. Make sure the file is parsable.
	if(		fileContents != nil
	   &&	[fileContents length] > 0 )
	{
		NSUInteger		 newlineIndex	= 0; //index of the first newline character in the file.
		NSString		*firstLine		= nil;
		NSString		*lineCode		= nil;
		
		// LDraw uses DOS lineendings
		[fileContents getLineStart: NULL //I don't care
							   end: NULL //I don't want the terminator included.
					   contentsEnd: &newlineIndex
						  forRange: NSMakeRange(0,1) ];
						  
		firstLine	= [fileContents substringToIndex:newlineIndex];
		lineCode	= [LDrawUtilities readNextField:firstLine
									      remainder:&partDescription ];

		//Check to see if this is a valid LDraw header.
		if([lineCode isEqualToString:@"0"] == YES)
		{
			partDescription = [partDescription stringByTrimmingCharactersInSet:whitespace];
		}
	}
	else
	{
		NSLog(@"%@ is not a valid file", filepath);
	}
	
	return partDescription;
	
}//end partInfoForFile


//========== readModelAtPath: ==================================================
//
// Purpose:		Parses the model found at the given path, adds it to the list of 
//				loaded parts, and returns the model.
//
//==============================================================================
- (LDrawModel *) readModelAtPath:(NSString *)partPath
						partName:(NSString *)partName
{
	LDrawModel	*model		= nil;
	
	if(partPath != nil)
	{
		//We found it in the LDraw folder; now all we need to do is get 
		// the model for it.
		LDrawFile *parsedFile = [LDrawFile fileFromContentsAtPath:partPath];
		[parsedFile optimizeStructure];
		model = [[parsedFile submodels] objectAtIndex:0];
		
			//Now that we've parsed it once, save it for future reference.
		[self->loadedFiles setObject:model forKey:partName];
	}
	
	return model;
	
}//end readModelAtPath:


//========== validateLDrawFolder: ==============================================
//
// Purpose:		Checks to see that the folder at path is indeed a valid LDraw 
//				folder and contains the vital Parts and P directories.
//
//==============================================================================
- (BOOL) validateLDrawFolder:(NSString *) folderPath
{
	//Check and see if this folder is any good.
	NSString *partsFolderPath		= [folderPath stringByAppendingPathComponent:PARTS_DIRECTORY_NAME];
	NSString *primitivesFolderPath	= [folderPath stringByAppendingPathComponent:PRIMITIVES_DIRECTORY_NAME];
	
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	BOOL			folderIsValid = NO;
	
	if(		[fileManager fileExistsAtPath:folderPath]
		&&	[fileManager fileExistsAtPath:partsFolderPath]
		&&	[fileManager fileExistsAtPath:primitivesFolderPath]
	   )
	{
		folderIsValid = YES;
	}
	
	return folderIsValid;
	
}//end validateLDrawFolder:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We have turned a corner on the Circle of Life.
//
//==============================================================================
- (void) dealloc
{
	[partCatalog	release];
	[favorites		release];
	[loadedFiles	release];
	
	[super dealloc];
	
}//end dealloc


@end
