//==============================================================================
//
// File:		PartBrowserDataSource.m
//
// Purpose:		Provides a standarized data source for part browser interface.
//
//				A part browser consists of a table which displays part numbers 
//				and descriptions, and a combo box to choose part categories.
//
// Usage:		An instance of this class should exist in each Nib file which 
//				contains a part browser, and the browser widgets and actions 
//				should be connected to it. This class will then take care of 
//				managing those widgets.
//
//				Clients wishing to know about part insertions should implement 
//				the action -insertLDrawPart:.
//
//  Created by Allen Smith on 2/17/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "PartBrowserDataSource.h"

#import "LDrawApplication.h"
#import "LDrawColorPanel.h"
#import "LDrawPart.h"
#import "MacLDraw.h"
#import "PartLibrary.h"
#import "StringCategory.h"


@implementation PartBrowserDataSource


//========== awakeFromNib ======================================================
//
// Purpose:		This class is just about always initialized in a Nib file.
//				So when awaking, we grab the actual data source for the class.
//
//==============================================================================
- (void) awakeFromNib
{
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSString		*startingCategory	= [userDefaults stringForKey:PART_BROWSER_PREVIOUS_CATEGORY];
	int				 startingRow		= [userDefaults integerForKey:PART_BROWSER_PREVIOUS_SELECTED_ROW];
	NSMenu			*searchMenuTemplate	= [[NSMenu alloc] initWithTitle:@"Search template"];
	NSMenuItem		*recentsItem		= nil;
	NSMenuItem		*noRecentsItem		= nil;
	
	
	//---------- Widget Setup --------------------------------------------------
	
	[self->partsTable setTarget:self];
	[self->partsTable setDoubleAction:@selector(doubleClickedInPartTable:)];
	
	[self->partPreview setAcceptsFirstResponder:NO];
	[self->partPreview setDelegate:self];
	
	//Configure the search field's menu
	noRecentsItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"NoRecentSearches", nil)
											   action:NULL
										keyEquivalent:@"" ];
	[noRecentsItem setTag:NSSearchFieldNoRecentsMenuItemTag];
	[searchMenuTemplate insertItem:noRecentsItem atIndex:0];
	
	recentsItem = [[NSMenuItem alloc] initWithTitle:@"recent items placeholder"
											 action:NULL
									  keyEquivalent:@"" ];
	[recentsItem setTag:NSSearchFieldRecentsMenuItemTag];
	[searchMenuTemplate insertItem:recentsItem atIndex:1];
	
	[[self->searchField cell] setSearchMenuTemplate:searchMenuTemplate];
	
	// If there is no sort order yet, define one.
	if([[self->partsTable sortDescriptors] count] == 0)
	{
		NSTableColumn		*descriptionColumn	= [self->partsTable tableColumnWithIdentifier:PART_NAME_KEY];
		NSSortDescriptor	*sortDescriptor		= [descriptionColumn sortDescriptorPrototype];
		
		if(sortDescriptor != nil)
			[self->partsTable setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	}
	
	
	//---------- Set Data ------------------------------------------------------
	
	[self setPartCatalog:[[LDrawApplication sharedPartLibrary] partCatalog]];
	[self setCategory:startingCategory];
	
	[partsTable scrollRowToVisible:startingRow];
	[partsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:startingRow]
			byExtendingSelection:NO];
	[self syncSelectionAndPartDisplayed];
	
	
	//---------- Notifications -------------------------------------------------
	
	//We also want to know if the part catalog changes while the program is running.
	[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(sharedPartCatalogDidChange:)
				   name: LDrawPartCatalogDidChangeNotification
				 object: nil ];
	
	
	//---------- Free Memory ---------------------------------------------------
	[searchMenuTemplate	release];
	[recentsItem		release];
	[noRecentsItem		release];

}//end awakeFromNib


//========== init ==============================================================
//
// Purpose:		This is very basic; it's not where the action is.
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	//Not displaying anything yet.
	categoryList	= [[NSArray array] retain];
	tableDataSource	= [[NSMutableArray array] retain];
	
	return self;
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== selectedPartName ==================================================
//
// Purpose:		Returns the name of the selected part file.
//				i.e., "3001.dat"
//
//==============================================================================
- (NSString *) selectedPartName
{
	int				 rowIndex	= [partsTable selectedRow];
	NSDictionary	*partRecord	= nil;
	NSString		*partName	= nil;
	
	if(rowIndex >= 0)
	{
		partRecord	= [tableDataSource objectAtIndex:rowIndex];
		partName	= [partRecord objectForKey:PART_NUMBER_KEY];
	}
	
	return partName;
	
}//end selectedPartName


//========== setPartCatalog: ===================================================
//
// Purpose:		A new part catalog has been read out of the LDraw folder. Now we 
//				set up the data sources to reflect it.
//
//==============================================================================
- (void) setPartCatalog:(NSDictionary *)newCatalog
{
	partCatalog = newCatalog;
	
	//Get all the categories.
	// We use the dictionary keys found in the part catalog.
	NSArray *categories = [[newCatalog objectForKey:PARTS_CATALOG_KEY] allKeys];
	//Sort the categories; they are just plain strings.
	categories = [categories sortedArrayUsingSelector:@selector(compare:)];
	
	NSString *allCategoriesItem = NSLocalizedString(@"All Categories", nil);
	
	//Assemble the complete category list, which also includes an item for 
	// displaying every category.
	NSMutableArray *fullCategoryList = [NSMutableArray array];
	[fullCategoryList addObject:allCategoriesItem];
	[fullCategoryList addObjectsFromArray:categories]; //add all the actual categories
	
	//and now we have a complete list.
	[self setCategoryList:fullCategoryList];
	
	//And set the current category to show everything
	[self setCategory:allCategoriesItem];
	
}

//========== setCategory: ======================================================
//
// Purpose:		The parts browser should now display newCategory. This method 
//				should be called in response to choosing a new category in the 
//				category combo box.
//
//==============================================================================
- (BOOL) setCategory:(NSString *)newCategory
{
	NSString		*allCategoriesString = NSLocalizedString(@"All Categories", nil);
	NSMutableArray	*partsInCategory	= nil;
	BOOL			 success			= NO;
	
	//Get the appropriate category list.
	if([newCategory isEqualToString:allCategoriesString]){
		//Retrieve all parts. We can do this by getting the entire (unsorted) 
		// contents of PARTS_LIST_KEY in the partCatalog, which is actually 
		// a dictionary of all parts.
		partsInCategory = [NSMutableArray arrayWithArray:
				[[partCatalog objectForKey:PARTS_LIST_KEY] allValues] ];
		success = YES;
		
	}
	else{
		//Retrieve the dictionary for the category:
		NSArray *category = [[partCatalog objectForKey:PARTS_CATALOG_KEY] objectForKey:newCategory];
		if(category != nil){
			partsInCategory = [NSMutableArray arrayWithArray:category];
			success = YES;
		}
		
	}
	
	//Apply the search.
	partsInCategory = [self filterParts:partsInCategory
						 bySearchString:[self->searchField stringValue]];
	
	if(success == YES){
		[self setTableDataSource:partsInCategory];
		[categoryComboBox setStringValue:newCategory];		
	}
	else //not a valid category typed; display no list.
		[self setTableDataSource:[NSMutableArray array]];
	
	return success;
}


//========== setCategoryList: ==================================================
//
// Purpose:		Sets the complete list of all the categories avaibaled; used as 
//				the category combo box's data source.
//
//==============================================================================
- (void) setCategoryList:(NSArray *)newCategoryList
{
	//swap the variable
	[newCategoryList retain];
	[categoryList release];
	
	categoryList = newCategoryList;
	
	//Update the category chooser
	[categoryComboBox reloadData];
	
}//end setCategoryList


//========== setTableDataSource: ===============================================
//
// Purpose:		The table displays a list of the parts in a category. The array
//				here is an array of part records containg names and 
//				descriptions.
//
//				The new parts are then displayed in the table.
//
//==============================================================================
- (void) setTableDataSource:(NSMutableArray *) partsInCategory
{
	//Sort the parts based on whatever the current sort order is for the table.
	[partsInCategory sortUsingDescriptors:[partsTable sortDescriptors]];
	
	//Swap out the variable
	[partsInCategory retain];
	[tableDataSource release];
	
	tableDataSource = partsInCategory;
	
	//Update the table
	[partsTable reloadData];
	
}//end setTableDataSource


#pragma mark -
#pragma mark ACTIONS
#pragma mark -


//========== addPartClicked: ===================================================
//
// Purpose:		Need to add the selected part to whoever is interested in that. 
//				This is dispatched as a nil-targeted action, and will most 
//				likely be picked up by the foremost document.
//
//==============================================================================
- (IBAction) addPartClicked:(id)sender
{
	//anyone who implements this message will know what to do.
	[NSApp sendAction:@selector(insertLDrawPart:) to:nil from:self];

}//end addPartClicked:


//========== categoryComboBoxChanged: ==========================================
//
// Purpose:		A new category has been selected.
//
//==============================================================================
- (IBAction) categoryComboBoxChanged:(id)sender
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSString		*newCategory	= [sender stringValue];
	BOOL			 success		= NO;
	
	//Clear the search field
	[self->searchField setStringValue:@""];
	
	//Proceed to set our category
	success = [self setCategory:newCategory];
	[self syncSelectionAndPartDisplayed];
	
	if(success == YES)
		[userDefaults setObject:newCategory forKey:PART_BROWSER_PREVIOUS_CATEGORY];
}


//========== doubleClickedInPartTable: =========================================
//
// Purpose:		We mean this to insert a part.
//
//==============================================================================
- (void) doubleClickedInPartTable:(id)sender
{
	[self addPartClicked:sender];
}

//========== searchFieldChanged: ===============================================
//
// Purpose:		The search string has been changed. We do a search on the entire 
//				part library.
//
//==============================================================================
- (IBAction) searchFieldChanged:(id)sender
{
	// Setting the category will filter the results.
	[self setCategory:NSLocalizedString(@"All Categories", nil)];
	[self syncSelectionAndPartDisplayed];

}//end searchFieldChanged:


#pragma mark -
#pragma mark DATA SOURCES
#pragma mark -

#pragma mark Combo Box

//**** NSComboBoxDataSource ****
//========== numberOfItemsInComboBox: ==========================================
//
// Purpose:		Returns the number of browsable categories.
//
//==============================================================================
- (int)numberOfItemsInComboBox:(NSComboBox *)comboBox
{
	return [categoryList count];
	
}//end numberOfItemsInComboBox:


//**** NSComboBoxDataSource ****
//========== comboBox:objectValueForItemAtIndex: ===============================
//
// Purpose:		Brings the window on screen.
//
//==============================================================================
- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(int)index
{
	return [categoryList objectAtIndex:index];
	
}//end comboBox:objectValueForItemAtIndex:


//**** NSComboBoxDataSource ****
//========== comboBox:completedString: =========================================
//
// Purpose:		Do a lazy string completion; no capital letters required.
//
//==============================================================================
- (NSString *)comboBox:(NSComboBox *)comboBox completedString:(NSString *)uncompletedString
{
	NSString			*currentCategory	= nil;
	BOOL				 foundMatch			= NO;
	NSComparisonResult	 comparisonResult	= NSOrderedSame;
	NSString			*completedString	= nil;
	int					 counter			= 0;
	
	//Search through all available categories, trying to find one with a 
	// case-insensitive prefix of uncompletedString
	while(counter < [categoryList count] && foundMatch == NO)
	{
		currentCategory = [categoryList objectAtIndex:counter];
		
		//See if the current category starts with the string we are looking for.
		comparisonResult = 
			[currentCategory compare:uncompletedString
							 options:NSCaseInsensitiveSearch
							   range:NSMakeRange(0, [uncompletedString length]) 
							   //only compare on the relevant part of the string
				];
		if(comparisonResult == NSOrderedSame)
			foundMatch = YES;
			
		counter++;
	}//end while
	
	if(foundMatch == YES)
		completedString = currentCategory;
	else
		completedString = uncompletedString; //no completion possible
	
	return completedString;
	
}//end comboBox:completedString:


#pragma mark Table

//**** NSTableDataSource ****
//========== numberOfRowsInTableView: ==========================================
//
// Purpose:		Should return the number of parts in the category currently 
//				being browsed.
//
//==============================================================================
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [tableDataSource count];
}//end numberOfRowsInTableView


//**** NSTableDataSource ****
//========== tableView:objectValueForTableColumn:row: ===============================
//
// Purpose:		Displays information for the part in the record.
//
//==============================================================================
- (id)				tableView:(NSTableView *)tableView
	objectValueForTableColumn:(NSTableColumn *)tableColumn
						  row:(int)rowIndex
{
	NSDictionary	*partRecord			= [tableDataSource objectAtIndex:rowIndex];
	NSString		*columnIdentifier	= [tableColumn identifier];
	
	NSString		*cellValue			= [partRecord objectForKey:columnIdentifier];
	
	//If it's a part, get rid of the file extension on its name.
	if([columnIdentifier isEqualToString:PART_NUMBER_KEY])
		cellValue = [cellValue stringByDeletingPathExtension];
	
	return cellValue;
	
}//end tableView:objectValueForTableColumn:row:


//**** NSTableDataSource ****
//========== tableView:sortDescriptorsDidChange: ===============================
//
// Purpose:		Resort the table elements.
//
//==============================================================================
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	NSArray *newDescriptors = [tableView sortDescriptors];
	[tableDataSource sortUsingDescriptors:newDescriptors];
	[tableView reloadData];
}


#pragma mark -

//**** NSTableDataSource ****
//========== tableView:writeRowsWithIndexes:toPasteboard: ======================
//
// Purpose:		It's time for drag-and-drop parts!
//
//				This method adds LDraw parts to the pasteboard.
//
// Notes:		We can have but one part selected in the browser, so the rows 
//				parameter is irrelevant. 
//
//==============================================================================
- (BOOL)     tableView:(NSTableView *)aTableView
  writeRowsWithIndexes:(NSIndexSet *)rowIndexes
		  toPasteboard:(NSPasteboard *)pasteboard
{
	BOOL	success = NO;
	
	// Select the dragged row (it may not have been selected), then write it to 
	// the pasteboard. 
	[self->partsTable selectRowIndexes:rowIndexes byExtendingSelection:NO];
	success = [self writeSelectedPartToPasteboard:pasteboard];
	
	return success;
		
}//end tableView:writeRowsWithIndexes:toPasteboard:

#pragma mark -
#pragma mark DELEGATES
#pragma mark -

#pragma mark LDrawGLView

//========== LDrawGLView:writeDirectivesToPasteboard:asCopy: ===================
//
// Purpose:		Begin a drag-and-drop part insertion initiated in the directive 
//				view. 
//
//==============================================================================
- (BOOL)         LDrawGLView:(LDrawGLView *)glView
 writeDirectivesToPasteboard:(NSPasteboard *)pasteboard
					  asCopy:(BOOL)copyFlag
{
	BOOL	success = [self writeSelectedPartToPasteboard:pasteboard];
	
	return success;
	
}//end LDrawGLView:writeDirectivesToPasteboard:asCopy:

#pragma mark -
#pragma mark NSTableView

//**** NSTableView ****
//========== tableViewSelectionDidChange: ======================================
//
// Purpose:		A new part has been selected.
//
//==============================================================================
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	int				 newRow			= [self->partsTable selectedRow];
	
	//Redisplay preview.
	[self syncSelectionAndPartDisplayed];
	
	//save for posterity.
	if(newRow != -1)
		[userDefaults setInteger:newRow forKey:PART_BROWSER_PREVIOUS_SELECTED_ROW];
}//end tableViewSelectionDidChange


#pragma mark -
#pragma mark NOTIFICATIONS
#pragma mark -


//========== sharedPartCatalogDidChange: =======================================
//
// Purpose:		The application has loaded a new part catalog from the LDraw 
//				folder. Data sources must be updated accordingly.
//
//==============================================================================
- (void) sharedPartCatalogDidChange:(NSNotification *)notification
{
	NSDictionary *newCatalog = [notification object];
	[self setPartCatalog:newCatalog];
}//end sharedPartCatalogDidChange:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== filterParts:bySearchString: =======================================
//
// Purpose:		Searches partRecords for all records containing searchString; 
//				returns the matching records. The search will be conducted on 
//				both the part numbers and descriptions.
//
// Returns:		An array with all matching parts, or an empty array if no parts 
//				match.
//
// Notes:		The nasty problem is that LDraw names are formed so that they 
//				line up nicely in a monospaced font. Thus we have names like 
//				"Brick  2 x  4" (note extra spaces!). I sidestep the problem by 
//				stripping all the spaces from the search and find strings. It's 
//				still lame, but probably okay for most uses.
//
//				Tiger has fantabulous search predicates that would reduce a 
//				hefty hunk of this code to a 1-liner AND be whitespace neutral 
//				too. But I don't have Tiger, so instead I'm going for the 
//				cheeseball approach.  
//
//==============================================================================
- (NSMutableArray *) filterParts:(NSArray *)partRecords
				  bySearchString:(NSString *)searchString
{
	NSDictionary	*record					= nil;
	int				 counter				= 0;
	NSString		*partNumber				= nil;
	NSString		*partDescription		= nil;
	NSString		*partSansWhitespace		= nil;
	NSMutableArray	*matchingParts			= [NSMutableArray array];
	NSString		*searchSansWhitespace	= [searchString stringByRemovingWhitespace];
	
	if([searchString length] == 0)
	{
		//Everybody's a winner here.
		matchingParts = [NSMutableArray arrayWithArray:partRecords];
	}
	else
	{
		matchingParts = [NSMutableArray array];
		
		// Search through all the given records and try to find matches on the 
		// search string. But search part names whitespace-neutral so as not to 
		// be thrown off by goofy name spacing. 
		for(counter = 0; counter < [partRecords count]; counter++)
		{
			record				= [partRecords objectAtIndex:counter];
			partNumber			= [record objectForKey:PART_NUMBER_KEY];
			partDescription		= [record objectForKey:PART_NAME_KEY];
			partSansWhitespace	= [partDescription stringByRemovingWhitespace];
			
			if(		[partNumber			containsString:searchString options:NSCaseInsensitiveSearch]
				||	[partSansWhitespace	containsString:searchSansWhitespace options:NSCaseInsensitiveSearch] )
			{
				[matchingParts addObject:record];
			}
		}
	}//end else we have to search
	
	
	return matchingParts;
	
}//end filterParts:bySearchString:


//========== syncSelectionAndPartDisplayed =====================================
//
// Purpose:		Makes the current part displayed match the part selected in the 
//				table.
//
//==============================================================================
- (void) syncSelectionAndPartDisplayed
{
	NSString	*selectedPartName	= [self selectedPartName];
	PartLibrary	*partLibrary		= [LDrawApplication sharedPartLibrary];
	id			 modelToView		= nil;
	
	if(selectedPartName != nil) {
		modelToView = [partLibrary modelForName:selectedPartName];
	}
	[partPreview setLDrawDirective:modelToView];
	
}//end syncSelectionAndPartDisplayed


//========== writeSelectedPartToPasteboard: ====================================
//
// Purpose:		Writes the current part-browser selection onto the pasteboard.
//
//==============================================================================
- (BOOL) writeSelectedPartToPasteboard:(NSPasteboard *)pasteboard
{
	NSMutableArray	*archivedParts		= [NSMutableArray array];
	NSString		*partName			= [self selectedPartName];
	LDrawPart		*newPart			= [[[LDrawPart alloc] init] autorelease];
	NSData			*partData			= nil;
	LDrawColorT		 selectedColor		= [[LDrawColorPanel sharedColorPanel] LDrawColor];
	BOOL			 success			= NO;
	
	//We got a part; let's add it!
	if(partName != nil)
	{
		newPart		= [[[LDrawPart alloc] init] autorelease];
		
		//Set up the part attributes
		[newPart setLDrawColor:selectedColor];
		[newPart setDisplayName:partName];
		
		partData	= [NSKeyedArchiver archivedDataWithRootObject:newPart];
		
		[archivedParts addObject:partData];
		
		// Set up pasteboard
		[pasteboard declareTypes:[NSArray arrayWithObjects:LDrawDraggingPboardType, LDrawDraggingIsUninitializedPboardType, nil] owner:self];
		
		[pasteboard setPropertyList:archivedParts
							forType:LDrawDraggingPboardType];
		
		[pasteboard setPropertyList:[NSNumber numberWithBool:YES]
							forType:LDrawDraggingIsUninitializedPboardType];
		
		success = YES;
	}
	
	return success;
	
}//end writeSelectedPartToPasteboard:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		It's AppKit, in the Library, with the Lead Pipe!!!
//
//==============================================================================
- (void) dealloc {
	//Remove notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//Release data
	[categoryList release];
	[tableDataSource release];
	
	[super dealloc];
}

@end
