//==============================================================================
//
// File:		PartLibraryController.h
//
// Purpose:		UI layerings on top of PartLibrary.
//
// Modified:	01/28/2009 Allen Smith. Creation Date.
//
//==============================================================================
#import "PartLibraryController.h"

#import <AMSProgressBar/AMSProgressBar.h>
#import "MacLDraw.h"

@implementation PartLibraryController

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== init ==============================================================
//
// Purpose:		Initialize a controller for a part library (also initialize the 
//				library itself). 
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	self->partLibrary = [PartLibrary new];
	
	return self;

}//end initWithPartLibrary:


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== partLibrary =======================================================
//
// Purpose:		Returns the data-model object encapsulated by the receiver.
//
//==============================================================================
- (PartLibrary *) partLibrary
{
	return self->partLibrary;
	
}//end partLibrary


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== loadPartCatalog ===================================================
//
// Purpose:		Reads the part catalog out of the LDraw folder. Returns YES upon 
//				success.
//
//==============================================================================
- (BOOL) loadPartCatalog
{
	BOOL            success			= NO;
	
	// Try loading an existing library first.
	success = [self->partLibrary load];
	
	if(success == NO)
	{
		// loading failed; try reloading (generates a new part list)
		success = [self reloadPartCatalog];
	}
		
	return success;
	
}//end loadPartCatalog


//========== reloadPartCatalog =================================================
//
// Purpose:		Scans the contents of the LDraw/ folder and produces a 
//				Mac-friendly index of parts, displaying a progress bar.
//
//==============================================================================
- (BOOL) reloadPartCatalog
{
	BOOL success = NO;

	self->progressPanel	= [AMSProgressPanel progressPanel];
	
	[self->progressPanel setMessage:@"Loading Parts"];
	[self->progressPanel showProgressPanel];
	
	success = [self->partLibrary reloadPartsWithDelegate:self];
	
	[self->progressPanel close];
	
	return success;
	
}//end reloadPartCatalog


//========== validateLDrawFolderWithMessage: ===================================
//
// Purpose:		Checks to see that the folder at path is indeed a valid LDraw 
//				folder and contains the vital Parts and P directories.
//
//==============================================================================
- (BOOL) validateLDrawFolderWithMessage:(NSString *) folderPath
{
	BOOL folderIsValid = [self->partLibrary validateLDrawFolder:folderPath];
	
	if(folderIsValid == NO)
	{
		NSAlert *error = [[NSAlert alloc] init];
		[error setAlertStyle:NSCriticalAlertStyle];
		[error addButtonWithTitle:NSLocalizedString(@"OKButtonName", nil)];
		
		
		[error setMessageText:NSLocalizedString(@"LDrawFolderChooserErrorMessage", nil)];
		[error setInformativeText:NSLocalizedString(@"LDrawFolderChooserErrorInformative", nil)];
		
		[error runModal];
		
		[error release];
	}
	
	return folderIsValid;
	
}//end validateLDrawFolder


#pragma mark -
#pragma mark PART LIBRARY DELEGATE
#pragma mark -

//========== partLibrary:maximumPartCountToLoad: ===============================
//
// Purpose:		The reloader is telling us the maximum number of files to 
//				expect. 
//
//==============================================================================
- (void)		partLibrary:(PartLibrary *)partLibrary
	 maximumPartCountToLoad:(NSUInteger)maxPartCount
{
	[self->progressPanel setMaxValue:maxPartCount];
	
}//end partLibrary:maximumPartCountToLoad:


//========== partLibraryIncrementLoadProgressCount: ============================
//
// Purpose:		Tells us that the reloader has loaded one additional item.
//
//==============================================================================
- (void) partLibraryIncrementLoadProgressCount:(PartLibrary *)partLibrary
{
	[self->progressPanel increment];
	
}//end partLibraryIncrementLoadProgressCount:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We're, uh, checking out.
//
//==============================================================================
- (void) dealloc
{
	[partLibrary release];

	[super dealloc];
	
}//end dealloc


@end
