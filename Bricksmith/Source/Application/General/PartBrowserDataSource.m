//==============================================================================
//
// File:		PartBrowserDataSource.m
//
// Purpose:		Provides a standarized data source for part browser interface.
//
//				A part browser consists of a table which displays part numbers 
//				and descriptions, and a combo box to choose part categories.
//
//				An instance of this class should exist in each Nib file which 
//				contains a part browser, and the browser widgets and actions 
//				should be connected to it. This class will then take care of 
//				managing those widgets.
//
//  Created by Allen Smith on 2/17/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "PartBrowserDataSource.h"

#import "LDrawApplication.h"
#import "MacLDraw.h"
#import "StringCategory.h"


@implementation PartBrowserDataSource


//========== awakeFromNib ======================================================
//
// Purpose:		This class is just about always initialized in a Nib file.
//				So when awaking, we grab the actual data source for the class.
//
//==============================================================================
- (void) awakeFromNib {

	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSString		*startingCategory	= [userDefaults stringForKey:PART_BROWSER_PREVIOUS_CATEGORY];
	NSMenu			*searchMenuTemplate	= [[NSMenu alloc] initWithTitle:@"Search template"];
	NSMenuItem		*recentsItem		= nil;
	NSMenuItem		*noRecentsItem		= nil;
	
	if(startingCategory == nil)
		startingCategory = NSLocalizedString(@"All Categories", nil);

	[partPreview setAcceptsFirstResponder:NO];
	[self setPartCatalog:[[LDrawApplication sharedPartLibrary] partCatalog]];
	[self setCategory:startingCategory];
	[partPreview setHasInfiniteDepth:YES]; //we don't want any clipping on our previews.
	[self syncSelectionAndPartDisplayed];
	
	
	//Configure the search field's menu
	recentsItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"NoRecentSearches", nil)
											 action:NULL
									  keyEquivalent:@"" ];
	[recentsItem setTag:NSSearchFieldNoRecentsMenuItemTag];
	[searchMenuTemplate insertItem:recentsItem atIndex:0];
	
	recentsItem = [[NSMenuItem alloc] initWithTitle:@"recent items placeholder"
											 action:NULL
									  keyEquivalent:@"" ];
	[recentsItem setTag:NSSearchFieldRecentsMenuItemTag];
	[searchMenuTemplate insertItem:recentsItem atIndex:1];
	
	[[self->searchField cell] setSearchMenuTemplate:searchMenuTemplate];
		
	//We also want to know if the part catalog changes while the program is running.
	[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(sharedPartCatalogDidChange:)
				   name: LDrawPartCatalogDidChangeNotification
				 object: nil ];
	
	//Free Memory.
	[searchMenuTemplate	release];
	[recentsItem		release];
	[noRecentsItem		release];
}


//========== init ==============================================================
//
// Purpose:		This is very basic; it's not where the action is.
//
//==============================================================================
- (id) init {
	[super init];
	
	//Not displaying anything yet.
	categoryList = [[NSArray array] retain];
	tableDataSource = [[NSMutableArray array] retain];
	
	return self;
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== selectedPart ======================================================
//
// Purpose:		Returns the name of the selected part file.
//				i.e., "3001.dat"
//
//==============================================================================
- (NSString *) selectedPart {

	int				 rowIndex	= [partsTable selectedRow];
	NSDictionary	*partRecord	= nil;
	NSString		*partName	= nil;
	
	if(rowIndex >= 0) {
		partRecord	= [tableDataSource objectAtIndex:rowIndex];
		partName	= [partRecord objectForKey:PART_NUMBER_KEY];
	}
	
	return partName;
}

//========== setPartCatalog: ===================================================
//
// Purpose:		A new part catalog has been read out of the LDraw folder. Now we 
//				set up the data sources to reflect it.
//
//==============================================================================
- (void) setPartCatalog:(NSDictionary *)newCatalog {
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
- (void) setCategoryList:(NSArray *)newCategoryList{
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
- (void) setTableDataSource:(NSMutableArray *) partsInCategory{
	
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

//========== categoryComboBoxChanged: ==========================================
//
// Purpose:		A new category has been selected.
//
//==============================================================================
- (IBAction) categoryComboBoxChanged:(id)sender{
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


//========== searchFieldChanged: ===============================================
//
// Purpose:		The search string has been changed. We do a search on the entire 
//				part library.
//
//==============================================================================
- (IBAction) searchFieldChanged:(id)sender;
{
	NSString *searchString = [searchField stringValue];
	
	[self setCategory:NSLocalizedString(@"All Categories", nil)];
	[self syncSelectionAndPartDisplayed];

}


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
	NSString			*currentCategory;
	BOOL				 foundMatch = NO;
	NSComparisonResult	 comparisonResult;
	NSString			*completedString;
	int					 counter = 0;
	
	//Search through all available categories, trying to find one with a 
	// case-insensitive prefix of uncompletedString
	while(counter < [categoryList count] && foundMatch == NO){
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
#pragma mark NOTIFICATIONS
#pragma mark -


//**** NSTableView ****
//========== tableViewSelectionDidChange: ======================================
//
// Purpose:		A new part has been selected.
//
//==============================================================================
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self syncSelectionAndPartDisplayed];
}


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
//==============================================================================
- (NSMutableArray *) filterParts:(NSArray *)partRecords
				  bySearchString:(NSString *)searchString
{
	NSDictionary	*record				= nil;
	int				 counter			= 0;
	NSString		*partNumber			= nil;
	NSString		*partDescription	= nil;
	NSMutableArray	*matchingParts		= [NSMutableArray array];
	
	if([searchString length] == 0){
		//Everybody's a winner here.
		matchingParts = [NSMutableArray arrayWithArray:partRecords];
	}
	else {
		matchingParts = [NSMutableArray array];
		
		//Search through all the given records and try to find matches on the search 
		// string.
		for(counter = 0; counter < [partRecords count]; counter++){
			record			= [partRecords objectAtIndex:counter];
			partNumber		= [record objectForKey:PART_NUMBER_KEY];
			partDescription	= [record objectForKey:PART_NAME_KEY];
			
			if(		[partNumber			containsString:searchString options:NSCaseInsensitiveSearch]
				||	[partDescription	containsString:searchString options:NSCaseInsensitiveSearch] )
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
- (void) syncSelectionAndPartDisplayed {
	NSString	*selectedPartName	= [self selectedPart];
	PartLibrary	*partLibrary		= [LDrawApplication sharedPartLibrary];
	id			 modelToView		= nil;
	
	if(selectedPartName != nil) {
		modelToView = [partLibrary modelForName:selectedPartName];
	}
	[partPreview setLDrawDirective:modelToView];	
}


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
