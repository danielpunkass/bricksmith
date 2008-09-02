//==============================================================================
//
// File:		InspectionMPDModel.m
//
// Purpose:		Inspector Controller for an LDrawMPDModel.
//
//				This inspector panel is loaded by the main Inspector class.
//
//  Created by Allen Smith on 3/13/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "InspectionMPDModel.h"

#import "LDrawMPDModel.h"

@implementation InspectionMPDModel

//========== init ==============================================================
//
// Purpose:		Load the interface for this inspector.
//
//==============================================================================
- (id) init {
	
    self = [super init];
    if ([NSBundle loadNibNamed:@"InspectorMPDModel" owner:self] == NO) {
        NSLog(@"Couldn't load InspectorMPDModel.nib");
    }
    return self;
}

#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== finishedEditing: ==================================================
//
// Purpose:		Called in response to the conclusion of editing in the palette.
//
//==============================================================================
- (IBAction)finishedEditing:(id)sender{

	LDrawMPDModel *representedObject = [self object];
	[representedObject snapshot];
	
	NSString				*newName		= [modelNameField	stringValue];
	NSString				*newDescription	= [descriptionField	stringValue];
	NSString				*newAuthor		= [authorField		stringValue];
	LDrawDotOrgModelStatusT	newModelStatus	= [[ldrawDotOrgPopUp selectedItem] tag];
	
	//For the sake of simplicity, we group these similar fields of the MPD and 
	// regular model together.
	[representedObject setModelName:newName];
	[representedObject setFileName:newName];
	
	[representedObject setModelDescription:newDescription];
	[representedObject setAuthor:newAuthor];
	[representedObject setLDrawRepositoryStatus:newModelStatus];
	
	
	[super finishedEditing:sender];
}

//========== revert ============================================================
//
// Purpose:		Restores the palette to reflect the state of the object.
//				This method is called automatically when the object to inspect 
//				is set. Subclasses should override this method to populate 
//				the data in their inspector palettes.
//
//==============================================================================
- (IBAction) revert:(id)sender{

	LDrawMPDModel *representedObject = [self object];

	[modelNameField			setStringValue:[representedObject modelName]		];
	[descriptionField		setStringValue:[representedObject modelDescription]	];
	[authorField			setStringValue:[representedObject author]			];
	
	int tagIndex = [ldrawDotOrgPopUp indexOfItemWithTag:[representedObject ldrawRepositoryStatus]];
	[ldrawDotOrgPopUp		selectItemAtIndex:tagIndex];
	
	[numberElementsField	setIntValue:[representedObject numberElements]		];
	[numberStepsField		setIntValue:[[representedObject steps] count]		];
	
	[super revert:sender];
}

#pragma mark -

//========== modelNameFieldChanged: ============================================
//
// Purpose:		The user has changed the model name.
//
//==============================================================================
- (IBAction) modelNameFieldChanged:(id)sender
{
	NSString *newValue	= [sender stringValue];
	NSString *oldValue	= [[self object] modelName];
	
	//If the values really did change, then update.
	if([newValue isEqualToString:oldValue] == NO)
		[self finishedEditing:sender];
}

//========== descriptionFieldChanged: ==========================================
//
// Purpose:		The user has changed the model description.
//
//==============================================================================
- (IBAction) descriptionFieldChanged:(id)sender
{
	NSString *newValue	= [sender stringValue];
	NSString *oldValue	= [[self object] modelDescription];
	
	//If the values really did change, then update.
	if([newValue isEqualToString:oldValue] == NO)
		[self finishedEditing:sender];
}

//========== authorFieldChanged: ===============================================
//
// Purpose:		The user has changed the author name.
//
//==============================================================================
- (IBAction) authorFieldChanged:(id)sender
{
	NSString *newValue	= [sender stringValue];
	NSString *oldValue	= [[self object] author];
	
	//If the values really did change, then update.
	if([newValue isEqualToString:oldValue] == NO)
		[self finishedEditing:sender];
}

//========== ldrawDotOrgPopUpClicked: ==========================================
//
// Purpose:		The user has changed the LDraw.org repository status.
//
//==============================================================================
- (IBAction) ldrawDotOrgPopUpClicked:(id)sender
{
	LDrawDotOrgModelStatusT newStatus = [[sender selectedItem] tag];
	LDrawDotOrgModelStatusT oldStatus = [[self object] ldrawRepositoryStatus];
	
	//If the values really did change, then update.
	if(newStatus != oldStatus)
		[self finishedEditing:sender];
}

@end
