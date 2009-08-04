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

#import "DonationDialogController.h"
#import "Inspector.h"
#import "LDrawColorPanel.h"
#import "LDrawDocument.h"
#import "MacLDraw.h"
#import "PartBrowserPanel.h"
#import "PartLibrary.h"
#import "PartLibraryController.h"
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


//========== awakeFromNib ======================================================
//
// Purpose:		Do first-load clean-up.
//
//==============================================================================
- (void) awakeFromNib
{
	SInt32 systemVersion	= 0;
	
	Gestalt(gestaltSystemVersion, &systemVersion);
	
	// We don't support hiding the file contents via a menu item on Tiger. The 
	// reason it is now nested inside a split view, and the API for 
	// programmatically collapsing a Split View did not appear until Leopard. I 
	// seriously do not feel like coming up with a Tiger solution to that mess. 
	if(systemVersion < 0x1050)
	{
		NSMenu			*mainMenu			= [NSApp mainMenu];
		NSMenu			*toolsMenu			= [[mainMenu itemWithTag:toolsMenuTag] submenu];
		int				 fileContentsIndex	= [toolsMenu indexOfItemWithTag:fileContentsMenuTag];
		
		[toolsMenu removeItemAtIndex:fileContentsIndex];
	}
	
}//end awakeFromNib


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//---------- openGLPixelFormat ---------------------------------------[static]--
//
// Purpose:		Returns the pixel format used in Bricksmith OpenGL views.
//
//------------------------------------------------------------------------------
+ (NSOpenGLPixelFormat *) openGLPixelFormat
{
	NSOpenGLPixelFormat				*pixelFormat		= nil;
	NSOpenGLPixelFormatAttribute	pixelAttributes[]	= { NSOpenGLPFADoubleBuffer,
															NSOpenGLPFADepthSize,		32,
															NSOpenGLPFASampleBuffers,	1, // enable line antialiasing
															NSOpenGLPFASamples,			3, // antialiasing beauty
															0};

	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: pixelAttributes];
	return [pixelFormat autorelease];
}


//---------- sharedInspector -----------------------------------------[static]--
//
// Purpose:		Returns the inspector object, which is created when the 
//				application launches.
//
// Note:		This method is static, so we don't have to keep passing pointers 
//				to this class around.
//
//------------------------------------------------------------------------------
+ (Inspector *) sharedInspector
{
	return [[NSApp delegate] inspector];
	
}//end sharedInspector


//---------- sharedOpenGLContext -------------------------------------[static]--
//
// Purpose:		Returns the OpenGLContext which unifies our display-list tags.
//				Every LDrawGLView should share this context.
//
//------------------------------------------------------------------------------
+ (NSOpenGLContext *) sharedOpenGLContext
{
	return [[NSApp delegate] openGLContext];
	
}//end sharedOpenGLContext


//---------- sharedPartLibrary ---------------------------------------[static]--
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
//------------------------------------------------------------------------------
+ (PartLibrary *) sharedPartLibrary
{
	PartLibraryController   *libraryController  = [self sharedPartLibraryController];
	PartLibrary             *library            = [libraryController partLibrary];

	return library;
	
}//end sharedPartLibrary


//---------- sharedPartLibraryController -----------------------------[static]--
//
// Purpose:		Returns the object which manages the part libary.
//
// Note:		This method is static, so we don't have to keep passing pointers 
//				to this class around.
//
//------------------------------------------------------------------------------
+ (PartLibraryController *) sharedPartLibraryController
{
	//Rather than making the part library a global variable, I decided to make 
	// it an instance variable of the Application Controller class, of which 
	// there is only one instance. This class is the application delegate too.
	PartLibraryController *libraryController = [[NSApp delegate] partLibraryController];
	
	return libraryController;
	
}//end sharedPartLibrary


//========== inspector =========================================================
//
// Purpose:		Returns the local instance of the inspector, which should be 
//				the only copy of it in the program.
//
//==============================================================================
- (Inspector *) inspector
{
	return inspector;
	
}//end inspector


//========== partLibraryController =============================================
//
// Purpose:		Returns the local instance of the part library controller, which 
//				should be the only copy of it in the program. You can access the 
//				part library itself through this object. 
//
//==============================================================================
- (PartLibraryController *) partLibraryController
{
	return partLibraryController;
	
}//end partLibraryController


//========== sharedOpenGLContext ===============================================
//
// Purpose:		Returns the OpenGLContext which unifies our display-list tags.
//				Every LDrawGLView should share this context.
//
//==============================================================================
- (NSOpenGLContext *) openGLContext
{
	return self->sharedGLContext;
	
}//end openGLContext


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
- (IBAction) doPreferences:(id)sender
{
	[PreferencesDialogController doPreferences];
	
}//end doPreferences:


//========== doDonate: =========================================================
//
// Purpose:		Takes the user to a webpage where they can give me money!
//				(Here's hoping.)
//
//==============================================================================
- (IBAction) doDonate:(id)sender
{
	NSURL *donationURL = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6985549"];

	[[NSWorkspace sharedWorkspace] openURL:donationURL];
	
}//end doDonate:


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
	
}//end showInspector:


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
	
}//end showMouseTools:


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
	
	// It seems some DOS old-timers want to enter colors WITHOUT EVER CLICKING 
	// THE MOUSE. So, we assume that if the color panel was summoned by its key 
	// equivalent, we are probably dealing with one of these rabid anti-mouse 
	// people. We automatically make the color search field key, so they can 
	// enter color codes to their heart's content. 
	if([[NSApp currentEvent] type] == NSKeyDown)
		[colorPanel focusSearchField:sender];
	
}//end showColors:


#pragma mark -
#pragma mark Help Menu

//========== doHelp: ===========================================================
//
// Purpose:		Display the Bricksmith tutorial.
//
//==============================================================================
- (IBAction) doHelp:(id)sender
{
	[self openHelpAnchor:@"index"];
	
}//end doHelp:


//========== doKeyboardShortcutHelp: ===========================================
//
// Purpose:		Display a help page about keyboard shortcuts.
//
// Notes:		Don't use Help Viewer. See addendum  in -doHelp:.
//
//==============================================================================
- (IBAction) doKeyboardShortcutHelp:(id)sender
{
	[self openHelpAnchor:@"KeyboardShortcuts"];
	
}//end doKeyboardShortcutHelp:


//========== doGettingNewPartsHelp: ============================================
//
// Purpose:		Display a help page about installing unofficial LDraw parts.
//
// Notes:		Don't use Help Viewer. See addendum  in -doHelp:.
//
//==============================================================================
- (IBAction) doGettingNewPartsHelp:(id)sender
{
	[self openHelpAnchor:@"AboutLDraw"];
	
}//end doKeyboardShortcutHelp:


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
- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSOpenGLPixelFormat	*pixelFormat	= [LDrawApplication openGLPixelFormat];
	
	//Make sure the standard preferences exist so they will be available 
	// throughout the application.
	[PreferencesDialogController ensureDefaults];
	
	//Create shared objects.
	self->inspector					= [Inspector new];
	self->partLibraryController		= [[PartLibraryController alloc] init];
	self->sharedGLContext			= [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
	[ToolPalette sharedToolPalette];
	
	[sharedGLContext makeCurrentContext];
	
	//Try to define an LDraw path before the application even finishes starting.
	[self findLDrawPath];

	//Load the parts into the library; see if they loaded properly.
	if([partLibraryController loadPartCatalog] == NO)
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
											 selector:@selector(partBrowserStyleDidChange:)
												 name:LDrawPartBrowserStyleDidChangeNotification
											   object:nil ];
	
}//end applicationWillFinishLaunching:


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
	
	if(		showPartBrowser == YES
	   &&	[userDefaults integerForKey:PART_BROWSER_STYLE_KEY] == PartBrowserShowAsPanel)
	{
		[[PartBrowserPanel sharedPartBrowserPanel] makeKeyAndOrderFront:self];
	}
	
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


//========== applicationShouldTerminate: =======================================
//
// Purpose:		We might have to gently remind the user that he ought to support 
//				this great project, um, monetarily. 
//
//==============================================================================
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	DonationDialogController	*donation = [[DonationDialogController alloc] init];
	
	if([donation shouldShowDialog] == YES)
	{
		[donation runModal];
	}
	
	return NSTerminateNow;
	
}//end applicationShouldTerminate:


#pragma mark -
#pragma mark NOTIFICATIONS
#pragma mark -

//========== partBrowserStyleDidChange: ========================================
//
// Purpose:		Reconfigure the part browser display based on new user 
//				preferences.
//
//==============================================================================
- (void) partBrowserStyleDidChange:(NSNotification *)notification
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
	
}//end partBrowserStyleDidChange:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== openHelpAnchor: ===================================================
//
// Purpose:		Provides much-needed API layering to open the specified help 
//				anchor token. DO NOT USE NSHelpManager DIRECTLY! 
//
// Rant:		Apple's automatic help registration is worthless. I've tried the 
//				program on numerous Macs; it refuses to load until the OS 
//				finally realizes a new program is there, which takes either 
//				a) 2 million years or b) voodoo/ritualistic sacrifice. So 
//				I'm bypassing what it does for something much less magical.
//
// Note:		I did manage to do *something* on two computers that got it 
//				working automatically (touching, copying, I don't know). But 
//				it never just happened when the application was first installed.
//
// Addendum:	I think the files need to be run through some help 
//				utility/indexer in the Developer Tools. But Help Viewer in 
//				Leopard is so abominable that I'm just going to launch a 
//				browser. On my  PowerBook G4, the Leopard Help Viewer takes 
//				2 minutes 42 seconds to launch and become responsive to events. 
//				That is shockingly unacceptible. 
//
//==============================================================================
- (void) openHelpAnchor:(NSString *)helpAnchor
{
	NSBundle	*applicationBundle	= [NSBundle mainBundle];
	NSString	*fileName			= helpAnchor; // help anchor is the filename by my convention
	NSString	*helpPath			= [applicationBundle pathForResource:fileName
																  ofType:@"html"
															 inDirectory:@"Help"];
	NSURL		*helpURL			= [NSURL fileURLWithPath:helpPath];
	
//	[[NSWorkspace sharedWorkspace] openFile:helpRoot withApplication:@"Help Viewer.app"];
	[[NSWorkspace sharedWorkspace] openURL:helpURL];
		
}//end openHelpAnchor:


//========== findLDrawPath =====================================================
//
// Purpose:		Figure out whether we have an LDraw folder, whether we can use 
//				it, stuff like that. This ever-so-clever method will try to find 
//				a folder for us if the one we have defined doesn't pan out.
//
//==============================================================================
- (NSString *) findLDrawPath
{
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
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
	for(counter = 0; counter < [potentialPaths count] && foundAPath == NO; counter++)
	{
		ldrawPath = [potentialPaths objectAtIndex:counter];
		foundAPath = [[self->partLibraryController partLibrary] validateLDrawFolder:ldrawPath];
	}

	//We found one.
	if(foundAPath == YES)
	{
		[userDefaults setObject:ldrawPath forKey:LDRAW_PATH_KEY];
	}
	else
	{	//never mind.
		//If they *thought* they had a selection then display a message 
		// telling them their selection is no good.
		if([preferencePath length] >= 0)
		{
			[self->partLibraryController validateLDrawFolderWithMessage:preferencePath];
		}
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
- (void) dealloc
{
	[partLibraryController	release];
	[inspector				release];
	[sharedGLContext		release];

	[super dealloc];
	
}//end dealloc

@end
