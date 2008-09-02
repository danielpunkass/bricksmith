//==============================================================================
//
// File:		LDrawColorPanel.m
//
// Purpose:		Color-picker for Bricksmith. The color panel is used to browse, 
//				select, and apply LDraw colors. The colors are presented by 
//				both swatch and name.
//
//  Created by Allen Smith on 2/26/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawColorPanel.h"

#import "LDrawColor.h"
#import "LDrawColorBar.h"
#import "LDrawColorCell.h"
#import "MacLDraw.h"
#import "StringCategory.h"

@implementation LDrawColorPanel

//There is supposed to be only one of these.
LDrawColorPanel *sharedColorPanel = nil;


//========== awakeFromNib ======================================================
//
// Purpose:		Brings the LDraw color panel to life.
//
// Note:		Please note that this method is called BEFORE most class
//				initialization code. For instance, awake is called before the 
//				table's data is even loaded, so you can't sort the data here.
//
//==============================================================================
- (void) awakeFromNib {
	LDrawColorCell *colorCell = [[LDrawColorCell alloc] init];
	NSTableColumn *colorColumn = [colorTable tableColumnWithIdentifier:LDRAW_COLOR_CODE];
	[colorColumn setDataCell:colorCell];
	
	
	//Remember, this method is called twice for an LDrawColorPanel; the first time 
	// is for the File's Owner, which is promptly overwritten.
}

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== sharedColorPanel ==================================================
//
// Purpose:		Returns the global instance of the color panel.
//
//==============================================================================
+ (LDrawColorPanel *) sharedColorPanel{
	if(sharedColorPanel == nil)
		sharedColorPanel = [[LDrawColorPanel alloc] init];
	
	return sharedColorPanel;
}

//========== init ==============================================================
//
// Purpose:		Brings the LDraw color panel to life.
//
//==============================================================================
- (id) init {

	[NSBundle loadNibNamed:@"ColorPanel" owner:self];
	
	self = colorPanel; //this don't look good, but it works.
						//this takes the place of calling [super init]
						// Note that connections in the Nib file must be made 
						// to the colorPanel, not to the File's Owner!
	
	//While the data is being loaded in the table, a color will automatically 
	// be selected. We do not want this color-selection to generate a 
	// changeColor: message, so we turn on this flag.
	updatingToReflectFile = YES;
	
		//Obtain the list of colors to display.
		colorList = [LDrawColor LDrawColorNamePairs];
		[colorList retain];
		[self setViewingColors:colorList];
		
		[self setLDrawColor:LDrawRed];
	updatingToReflectFile = NO;
	
	[self setDelegate:self];
	
	return self;
	
}

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== setViewingColors: =================================================
//
// Purpose:		Sets the list of colors currently being displayed. Should be a 
//				subset of colorList.
//
//				This method would be called in response to a limiting search.
//
//==============================================================================
- (void) setViewingColors:(NSArray *)newList{
	
	//This array is mutable for the sake of sorting. Otherwise, sorting a list 
	// would require replacing the instance variable, so we'd have to call this 
	// method. But that in turn would call sort: again, leading to an infinite
	// loop.
	NSMutableArray *editableList = [NSMutableArray arrayWithArray:newList];

	[editableList retain];
	[viewingColors release];
	
	viewingColors = editableList;
	
	//Owing to the very messy way I set up this Nib, I must force a resort here.
	// see awakeFromNib for details.
	[self tableView:colorTable sortDescriptorsDidChange:[colorTable sortDescriptors]];
	[colorTable reloadData];
}

//========== LDrawColor ========================================================
//
// Purpose:		Returns the color code of the panel's currently-selected color.
//
//==============================================================================
- (LDrawColorT) LDrawColor{
	int			selectedRow = [colorTable selectedRow];
	LDrawColorT	selectedColor;
	
	//It is possible there are no rows selected, if a search has limited the 
	// color list out of existence.
	if(selectedRow >= 0){
		NSNumber *colorCode = [[viewingColors objectAtIndex:selectedRow]
									objectForKey:LDRAW_COLOR_CODE];
		selectedColor = [colorCode intValue];
	}
	//Just return whatever was last selected.
	else
		selectedColor = [colorBar LDrawColor];
	
	
	return selectedColor;
}


//========== setLDrawColor =====================================================
//
// Purpose:		Chooses newColor in the color table. As long as newColor is a 
//				valid color, this method will select it, even if it has to 
//				change the found set.
//
//==============================================================================
- (void) setLDrawColor:(LDrawColorT)newColor;
{
	//Try to find the color we are after in the current list.
	int rowToSelect = [self indexOfColorCode:newColor]; //will be the row index for the color we want.
	
	if(rowToSelect == NSNotFound){
		//It wasn't in the currently-displayed list. Search the master list.
		[self setViewingColors:colorList];
		rowToSelect = [self indexOfColorCode:newColor];
	}
	
	//We'd better have found it by now!
	if(rowToSelect != NSNotFound){
		[colorTable selectRow:rowToSelect byExtendingSelection:NO];
		[colorBar setLDrawColor:newColor];
	}
	
}//end setLDrawColor

#pragma mark -
#pragma mark ACTIONS
#pragma mark -


//========== searchFieldChanged: ===============================================
//
// Purpose:		The user has changed the search string. We need to research 
//				the list of colors for those whose names match the new string.
//
// Notes:		For the sake of concise code, I do not bother to optimize this 
//				search. After all, we only have 64 colors; that's no time.
//
//==============================================================================
- (IBAction) searchFieldChanged:(id)sender{
	LDrawColorT		 currentColor			= [self LDrawColor];
	NSString		*searchString			= [sender stringValue];
	NSArray			*searchResults			= nil;
	
	//When a search is cancelled, the search field sends an empty string.
	if([searchString length] == 0)
		searchResults = colorList; //search cancelled; restore the full list.
	else
		searchResults = [self colorsMatchingString:searchString];
	
	//Update the table with our results.
	[self setViewingColors:searchResults];
	
	//Restore the selection
	int indexOfPreviousSelection = [self indexOfColorCode:currentColor];
	if(indexOfPreviousSelection != NSNotFound)
		[colorTable selectRowIndexes: [NSIndexSet indexSetWithIndex:indexOfPreviousSelection]
				byExtendingSelection: NO];
	//The previous color is no longer in the list. This is a major dilemma.
	// I have chosen to automatically select the first color, since I don't want 
	// to introduce the UI confusion of empty selection.
	else
		[colorTable selectRowIndexes: [NSIndexSet indexSetWithIndex:0]
				byExtendingSelection: NO];
		
}


//========== updateSelectionWithObjects: =======================================
//
// Purpose:		Updates the selected color based on the colors in 
//				selectedObjects, which should be a list of LDrawDirectives 
//				which have been selected in a document window.
//
//				If two or more directives have different colors, then the color 
//				of the last object selected is displayed.
//
//				If there are no colorable directives in selectedObjects, then 
//				the color selection remains unchanged.
//
//==============================================================================
- (void) updateSelectionWithObjects:(NSArray *)selectedObjects
{
	id currentObject = [selectedObjects lastObject];
	LDrawColorT objectColor = [self LDrawColor];
	int rowToSelect;
	int counter;
	
	//Find the color code of the last object selected. I suppose this is rather 
	// tacky to do such a simple search, but I would prefer not to write the 
	// interface required to denote multiple selection.
	if(currentObject != nil){
		if([currentObject conformsToProtocol:@protocol(LDrawColorable)])
			objectColor = [currentObject LDrawColor];
	}
	
	updatingToReflectFile = YES;
		[self setLDrawColor:objectColor];
	updatingToReflectFile = NO;
}

#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== colorsMatchingString: =============================================
//
// Purpose:		Returns the row index of colorCodeSought in the panel's table, or 
//				NSNotFound if colorCodeSought is not displayed.
//
// Notes:		We allow searching on both the integer LDraw color code or the 
//				color name. We distinguish color-code searches by looking for a 
//				search string consisting entirely of numerals.
//
//==============================================================================
- (NSArray *) colorsMatchingString:(NSString *)searchString{

	int				 numberColors			= [colorList count];
	NSDictionary	*currentColorRecord		= nil;
	NSMutableArray	*matchingColors			= [NSMutableArray array];
	int				 counter;
	
	BOOL			 searchByCode			= NO; //color name search by default.
	NSRange			 rangeOfDigits			= [searchString rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
	NSString		*colorName				= nil;
	NSNumber		*colorNumber			= nil;
	
	//Find out whether this search is intended to be based on the LDraw code.
	// If the search string is composed enterly of digits, then we can safely 
	// assume this is a color-code search. Otherwise, it will be a name search.
	if(NSEqualRanges(rangeOfDigits, NSMakeRange(0, [searchString length] ) )  ) //matches entire string.
		searchByCode = YES;
	
	//If it is an LDraw code search, try to find a color code that begins with 
	// the search number entered.
	if(searchByCode == YES){
		for(counter = 0; counter < numberColors; counter++){
			
			currentColorRecord	= [colorList objectAtIndex:counter];
			colorNumber			= [currentColorRecord objectForKey:LDRAW_COLOR_CODE];
			
			if([[colorNumber stringValue] hasPrefix:searchString] == YES )
				[matchingColors addObject:currentColorRecord];
		}
	}//end color-code search
	
	else{
		//This is a search based on color names. If we can find the search 
		// string in any component of the color string, we consider it a match.
		for(counter = 0; counter < numberColors; counter++){
			
			currentColorRecord	= [colorList objectAtIndex:counter];
			colorName			= [currentColorRecord objectForKey:COLOR_NAME];
			
			if([colorName containsString:searchString
								 options:NSCaseInsensitiveSearch] == YES )
			{	
				[matchingColors addObject:currentColorRecord];
			}
		}		
	}//end color name search
	
	
	//We have new search results.
	return matchingColors;
}


//========== indexOfColorCode: =================================================
//
// Purpose:		Returns the row index of colorCodeSought in the panel's table, or 
//				NSNotFound if colorCodeSought is not displayed.
//
//==============================================================================
- (int) indexOfColorCode:(LDrawColorT)colorCodeSought{

	//We shall use the table data source methods to find our color.
	int				 numberColors = [self numberOfRowsInTableView:colorTable];
	NSTableColumn	*colorColumn = [colorTable tableColumnWithIdentifier:LDRAW_COLOR_CODE];
	NSNumber		*currentCode;
	int				 rowToSelect = NSNotFound; //will be the row index for the color we want.
	int				 counter;
	
	//Search through all the colors in the current color set and see if the 
	// one we are after is in there. A brute force search.
	for(counter = 0; counter < numberColors && rowToSelect == NSNotFound; counter++)
	{
		//Ask the table for the color code at index of counter.
		currentCode = [self				tableView:colorTable
						objectValueForTableColumn:colorColumn
											  row:counter];
		if([currentCode intValue] == colorCodeSought)
			rowToSelect = counter;
	}
	
	return rowToSelect;
}

#pragma mark -
#pragma mark DATA SOURCES
#pragma mark -
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
	return [viewingColors count];
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
	if(rowIndex == -1 )
		NSLog(@"AAAAAA!");

	NSDictionary	*colorRecord		= [viewingColors objectAtIndex:rowIndex];
	NSString		*columnIdentifier	= [tableColumn identifier];
	
	id				 cellValue			= [colorRecord objectForKey:columnIdentifier];
	
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
	
	[viewingColors sortUsingDescriptors:newDescriptors];
	[tableView reloadData];
}

#pragma mark -
#pragma mark DELEGATES
#pragma mark -

//**** NSTableView ****
//========== tableViewSelectionDidChange: ======================================
//
// Purpose:		Need to update everything to indicate that a new color was 
//				selected.
//
//==============================================================================
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	//Update internal information.
	[colorBar setLDrawColor:[self LDrawColor]];
	
	
	//Well, our color has changed. Presumably, somebody wants to update a part 
	// color in response to this momentous event. But who knows who? So we just 
	// send this message toddling along, and let whoever want it get it.
	//
	//But--if this notification is coming in response to selecting a different 
	// part in the file, then our color did not *really* change; we 
	// are just displaying a new one. In that case, we don't want any parts 
	// changing colors.
	if(updatingToReflectFile == NO)
	{
		[NSApp sendAction:@selector(changeLDrawColor:)
					   to:nil //just send it somewhere!
					 from:self]; //it's from us (we'll be the sender)
					 
	}
	
	//Clients that are tracking the global color state always need to know 
	// about the current color, though!
	[[NSNotificationCenter defaultCenter]
						postNotificationName:LDrawColorDidChangeNotification
									  object:[NSNumber numberWithInt:[self LDrawColor]] ];

}//end tableViewSelectionDidChange:


//**** NSWindow ****
//========== windowWillReturnUndoManager: ======================================
//
// Purpose:		Allows Undo to keep working transparently through this window by 
//				allowing the undo request to forward on to the active document.
//
//==============================================================================
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	NSDocument *currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
	return [currentDocument undoManager];
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		The Roll has been called up Yonder, and we will be there.
//
//==============================================================================
- (void) dealloc {
	[colorList release];
	[viewingColors release];
	
	[super dealloc];
}

@end
