//==============================================================================
//
// File:		LDrawApplication.h
//
// Purpose:		This is the "application controller." Here we find application-
//				wide instance variables and actions, as well as application 
//				delegate code for startup and shutdown.
//
// Note:		Do not confuse this class with BricksmithApplication, which is 
//				an NSApplication subclass.
//
//  Created by Allen Smith on 2/14/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawApplication.h"

#import "Inspector.h"
#import "LDrawColorPanel.h"
#import "LDrawDocument.h"
#import "MacLDraw.h"
#import "PartBrowserPanel.h"
#import "PartLibrary.h"
#import "PreferencesDialogController.h"
#import "ToolPalette.h"
#import "TransformerIntMinus1.h"

@implementation LDrawApplication

//---------- initialize ----------------------------------------------[static]--
//
// Purpose:		Load things that need to be loaded *extremely* early in startup.
//
//------------------------------------------------------------------------------
+ (void) initialize
{
	TransformerIntMinus1 *minus1Transformer = [[[TransformerIntMinus1 alloc] init] autorelease];
	
	[NSValueTransformer setValueTransformer:minus1Transformer
									forName:@"TransformerIntMinus1" ];
}//end initialize

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== sharedInspector ===================================================
//
// Purpose:		Returns the inspector object, which is created when the 
//				application launches.
//
// Note:		This method is static, so we don't have to keep passing pointers 
//				to this class around.
//
//==============================================================================
+ (Inspector *) sharedInspector{
	return [[NSApp delegate] inspector];	
}


//========== sharedOpenGLContext ===============================================
//
// Purpose:		Returns the OpenGLContext which unifies our display-list tags.
//				Every LDrawGLView should share this context.
//
//==============================================================================
+ (NSOpenGLContext *) sharedOpenGLContext {
	return [[NSApp delegate] openGLContext];
}


//========== sharedPartLibrary =================================================
//
// Purpose:		Returns the part libary, which contains the part catalog, which 
//				is read in from the file LDRAW_PATH_KEY/PART_CATALOG_NAME when 
//				the application launches.
//				This is a rather big XML file, so it behooves us to read it 
//				once then save it in memory.
//
// Note:		This method is static, so we don't have to keep passing pointers 
//				to this class around.
//
//==============================================================================
+ (PartLibrary *) sharedPartLibrary
{
	//Rather than making the part library a global variable, I decided to make 
	// it an instance variable of the Application Controller class, of which 
	// there is only one instance. This class is the application delegate too.
	return [[NSApp delegate] partLibrary];
}//end sharedPartLibrary


//========== inspector =========================================================
//
// Purpose:		Returns the local instance of the inspector, which should be 
//				the only copy of it in the program.
//
//==============================================================================
- (Inspector *) inspector{
	return inspector;	
}


//========== partLibrary =======================================================
//
// Purpose:		Returns the local instance of the part library, which should be 
//				the only copy of it in the program.
//
//==============================================================================
- (PartLibrary *) partLibrary
{
	return partLibrary;
}//end partLibrary


//========== sharedOpenGLContext ===============================================
//
// Purpose:		Returns the OpenGLContext which unifies our display-list tags.
//				Every LDrawGLView should share this context.
//
//==============================================================================
- (NSOpenGLContext *) openGLContext
{
	return self->sharedGLContext;
}


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//#pragma mark -
#pragma mark Application Menu

//========== doPreferences =====================================================
//
// Purpose:		Show the preferences window.
//
//==============================================================================
- (IBAction)doPreferences:(id)sender
{
	[PreferencesDialogController doPreferences];
}


#pragma mark -
#pragma mark Tools Menu

//========== showInspector: ====================================================
//
// Purpose:		Opens the inspector window. It may have something in it; it may 
//				not. That's up to the document.
//
//==============================================================================
- (IBAction) showInspector:(id)sender
{
	[inspector show:sender];
}


//========== doPartBrowser: ====================================================
//
// Purpose:		Show or toggle the Part Browser, depending on the user's style 
//			    preference. 
//
//==============================================================================
- (IBAction) doPartBrowser:(id)sender 
{
	NSUserDefaults			*userDefaults		= [NSUserDefaults standardUserDefaults];
	PartBrowserStyleT		 newStyle			= [userDefaults integerForKey:PART_BROWSER_STYLE_KEY];
	NSDocumentController	*documentController	= [NSDocumentController sharedDocumentController];
	PartBrowserPanel		*partBrowser		= nil;

	switch(newStyle)
	{
		case PartBrowserShowAsDrawer:
			
			//toggle the part browser on the foremost document
			[[[documentController currentDocument] partBrowserDrawer] toggle:sender];
			
			break;
			
		case PartBrowserShowAsPanel:
			
			//open the shared part browser.
			partBrowser = [PartBrowserPanel sharedPartBrowserPanel];
			[partBrowser makeKeyAndOrderFront:sender];
			
			break;
	} 
	
}//end doPartBrowser:


//========== showMouseTools: ===================================================
//
// Purpose:		Opens the mouse tools palette, used to control the mouse cursor 
//				mode (e.g., selection, zooming, etc.).
//
//==============================================================================
- (IBAction) showMouseTools:(id)sender
{
	[[ToolPalette sharedToolPalette] showToolPalette:sender];
}


#pragma mark -
#pragma mark Part Menu

//========== showColors: =======================================================
//
// Purpose:		Opens the colors panel.
//
//==============================================================================
- (IBAction) showColors:(id)sender
{
	LDrawColorPanel *colorPanel = [LDrawColorPanel sharedColorPanel];
	
	[colorPanel makeKeyAndOrderFront:sender];
	
}//end showColors:


#pragma mark -
#pragma mark Help Menu

//========== doHelp: ===========================================================
//
// Purpose:		Apple's automatic help registration is worthless. I've tried the 
//				program on numerous Macs; it refuses to load until the OS 
//				finally realizes a new program is there, which takes either 
//				a) 2 million years or b) voodoo/ritualistic sacrifice. So 
//				I'm bypassing what it does for something much less magical.
//
// Note:		I did manage to do *something* on two computers that got it 
//				working automatically (touching, copying, I don't know). But 
//				it never just happened when the application was first installed.
//
//==============================================================================
- (IBAction) doHelp:(id)sender
{
	NSBundle *applicationBundle = [NSBundle mainBundle];
	NSString *helpRoot = [applicationBundle pathForResource:@"index"
													 ofType:@"html"
												inDirectory:@"Help"];
	[[NSWorkspace sharedWorkspace] openFile:helpRoot withApplication:@"Help Viewer.app"];

}//end doHelp:


#pragma mark -
#pragma mark APPLICATION DELEGATE
#pragma mark -

//**** NSApplication ****
//========== applicationWillFinishLaunching: ===================================
//
// Purpose:		The application has opened; this comes before anything else 
//				(i.e., opening files) but after the application is set up.
//
//==============================================================================
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSOpenGLPixelFormatAttribute	pixelAttributes[]	= { NSOpenGLPFADoubleBuffer,
															NSOpenGLPFADepthSize, 32,
															nil};
	NSOpenGLPixelFormat				*pixelFormat		= nil;
	
	
	//Make sure the standard preferences exist so they will be available 
	// throughout the application.
	[PreferencesDialogController ensureDefaults];
	
	//Create shared objects.
	inspector = [Inspector new];
	partLibrary = [PartLibrary new]; // creates a new part library which hasn't loaded the parts.
	[ToolPalette sharedToolPalette];
	
	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: pixelAttributes];
	sharedGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
	[sharedGLContext makeCurrentContext];
	
	//Try to define an LDraw path before the application even finishes starting.
	[self findLDrawPath];

	//Load the parts into the library; see if they loaded properly.
	if([partLibrary loadPartCatalog] == NO)
	{
		//No path has been chosen yet.
		// We must choose one now.
		[self doPreferences:self];
		//When the preferences dialog opens, it will automatically search for 
		// the prefs path. Failing to find it, it will force the user to choose 
		// a new one.
	}
	
	// Register for Notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(partBrawserStyleDidChange:)
												 name:LDrawPartBrowserStyleDidChangeNotification
											   object:nil ];
	
	[pixelFormat release];
}


//**** NSApplication ****
//========== applicationDidFinishLaunching: ====================================
//
// Purpose:		The application has finished launching.
//
//==============================================================================
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	NSUserDefaults		*userDefaults		= [NSUserDefaults standardUserDefaults];
	BOOL				 showPartBrowser	= [userDefaults boolForKey:PART_BROWSER_PANEL_SHOW_AT_LAUNCH];
	
	if(showPartBrowser == YES)
		[[PartBrowserPanel sharedPartBrowserPanel] makeKeyAndOrderFront:self];
	
}//end applicationDidFinishLaunching:


//**** NSApplication ****
//========== applicationWillTerminate: =========================================
//
// Purpose:		Bricksmith is quitting. Do any necessary pre-quit work, such as 
//				saving out preferences.
//
//==============================================================================
- (void)applicationWillTerminate:(NSNotification *)notification
{
	NSUserDefaults		*userDefaults		= [NSUserDefaults standardUserDefaults];
	PartBrowserPanel	*partBrowserPanel	= [PartBrowserPanel sharedPartBrowserPanel];
	
	[userDefaults setBool:[partBrowserPanel isVisible]
				   forKey:PART_BROWSER_PANEL_SHOW_AT_LAUNCH ];
				   
	[userDefaults synchronize];
	
}//end applicationWillTerminate:

#pragma mark -
#pragma mark NOTIFICATIONS
#pragma mark -

//========== partBrawserStyleDidChange: ========================================
//
// Purpose:		Reconfigure the part browser display based on new user 
//				preferences.
//
//==============================================================================
- (void) partBrawserStyleDidChange:(NSNotification *)notification
{
	NSUserDefaults			*userDefaults		= [NSUserDefaults standardUserDefaults];
	PartBrowserStyleT		 newStyle			= [userDefaults integerForKey:PART_BROWSER_STYLE_KEY];
	NSDocumentController	*documentController	= [NSDocumentController sharedDocumentController];
	NSArray					*documents			= [documentController documents];
	int						 documentCount		= [documents count];
	int						 counter			= 0;
	
	switch(newStyle)
	{
		case PartBrowserShowAsDrawer:
			
			//close the shared part browser
			[[PartBrowserPanel sharedPartBrowserPanel] close];
			
			// open the browser drawer on each document
			for(counter = 0; counter < documentCount; counter++)
			{
				[[[documents objectAtIndex:counter] partBrowserDrawer] open];
			}
			
			break;
			
		case PartBrowserShowAsPanel:
			
			//close the browser drawer on each document
			for(counter = 0; counter < documentCount; counter++)
			{
				[[[documents objectAtIndex:counter] partBrowserDrawer] close];
			}
			
			//open the shared part browser.
			[[PartBrowserPanel sharedPartBrowserPanel] makeKeyAndOrderFront:self];
			
			break;
	} 
	
}//end partBrawserStyleDidChange:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== findLDrawPath =====================================================
//
// Purpose:		Figure out whether we have an LDraw folder, whether we can use 
//				it, stuff like that. This ever-so-clever method will try to find 
//				a folder for us if the one we have defined doesn't pan out.
//
//==============================================================================
- (NSString *) findLDrawPath {
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSFileManager	*fileManager		= [NSFileManager defaultManager];
	int				 counter			= 0;
	BOOL			 foundAPath			= NO;
	
	NSString		*applicationPath	= [[NSBundle mainBundle] bundlePath];
	NSString		*applicationFolder	= [applicationPath stringByDeletingLastPathComponent];
	NSString		*siblingFolder		= [applicationFolder stringByDeletingLastPathComponent];
	NSString		*library			= [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES) objectAtIndex:0];
	NSString		*userLibrary		= [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,  YES) objectAtIndex:0];
	
	//Try User Defaults first; maybe we've already saved one.
	NSString		*preferencePath		= [userDefaults stringForKey:LDRAW_PATH_KEY];
	NSString		*ldrawPath			= preferencePath;
	BOOL			 prefsPathValid		= NO;
	
	if(preferencePath == nil)
		preferencePath = @""; //we're going to add this to an array. Can't have a nil object.
	
	applicationFolder	= [applicationFolder	stringByAppendingPathComponent:LDRAW_DIRECTORY_NAME];
	siblingFolder		= [siblingFolder		stringByAppendingPathComponent:LDRAW_DIRECTORY_NAME];
	library				= [library				stringByAppendingPathComponent:LDRAW_DIRECTORY_NAME];
	userLibrary			= [userLibrary			stringByAppendingPathComponent:LDRAW_DIRECTORY_NAME];
	
	//Tries user defaults first, then others
	NSArray *potentialPaths = [NSArray arrayWithObjects:preferencePath,
														applicationFolder,
														siblingFolder,
														library,
														userLibrary,
														nil ];
	for(counter = 0; counter < [potentialPaths count] && foundAPath == NO; counter++){
		ldrawPath = [potentialPaths objectAtIndex:counter];
		foundAPath = [partLibrary validateLDrawFolder:ldrawPath];
	}

	//We found one.
	if(foundAPath == YES){
		[userDefaults setObject:ldrawPath forKey:LDRAW_PATH_KEY];
	}
	else{ //never mind.
		//If they *thought* they had a selection then display a message 
		// telling them their selection is no good.
		if([preferencePath length] >= 0)
			[self->partLibrary validateLDrawFolderWithMessage:preferencePath];
		ldrawPath = nil;
	}
	
	return ldrawPath;
	
}//end findLDrawPath


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		The curtain falls.
//
//==============================================================================
- (void) dealloc{
	[partLibrary		release];
	[inspector			release];
	[sharedGLContext	release];

	[super dealloc];
}

@end
