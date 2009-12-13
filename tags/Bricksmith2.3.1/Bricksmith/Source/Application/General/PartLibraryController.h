//==============================================================================
//
// File:		PartLibraryController.h
//
// Purpose:		UI layerings on top of PartLibrary.
//
// Modified:	01/28/2009 Allen Smith. Creation Date.
//
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "PartLibrary.h"

// Forward declarations
@class AMSProgressPanel;


////////////////////////////////////////////////////////////////////////////////
//
// class PartLibraryController
//
////////////////////////////////////////////////////////////////////////////////
@interface PartLibraryController : NSObject <PartLibraryReloadPartsDelegate>
{
	AMSProgressPanel    *progressPanel;
	PartLibrary			*partLibrary;

}

// Accessors
- (PartLibrary *) partLibrary;

// Actions
- (BOOL) loadPartCatalog;
- (BOOL) reloadPartCatalog;
- (BOOL) validateLDrawFolderWithMessage:(NSString *) folderPath;

@end
