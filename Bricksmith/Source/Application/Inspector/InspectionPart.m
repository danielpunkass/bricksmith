//==============================================================================
//
// File:		InspectionPart.m
//
// Purpose:		Inspector Controller for an LDrawPart.
//
//				This inspector panel is loaded by the main Inspector class.
//
//  Created by Allen Smith on 3/26/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "InspectionPart.h"

#import "LDrawApplication.h"
#import "LDrawPart.h"
#import "FormCategory.h"

@implementation InspectionPart

//========== init ==============================================================
//
// Purpose:		Load the interface for this inspector.
//
//==============================================================================
- (id) init {
	
    self = [super init];
    if ([NSBundle loadNibNamed:@"InspectorPart" owner:self] == NO) {
        NSLog(@"Couldn't load InspectorPart.nib");
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

	LDrawPart					*representedObject = [self object];
	TransformationComponents	 oldComponents = [representedObject transformationComponents];
	TransformationComponents	 components = {0};
	
	[representedObject snapshot];
	
	[representedObject setDisplayName:[partNameField stringValue]];
	
	Point3	position	= [locationForm coordinateValue];
	Vector3	scaling		= [scalingForm coordinateValue];
	Vector3	shear		= [shearForm coordinateValue]; //not the right structure logically, but it works.
	
	//Fill the components structure.
 	components.scale_X		= scaling.x / 100.0; //convert from percentage
 	components.scale_Y		= scaling.y / 100.0;
 	components.scale_Z		= scaling.z / 100.0;
 	components.shear_XY		= shear.x;
 	components.shear_XZ		= shear.y;
 	components.shear_YZ		= shear.z;
 	components.rotate_X		= oldComponents.rotate_X; //rotation is handled elsewhere.
 	components.rotate_Y		= oldComponents.rotate_Y;
 	components.rotate_Z		= oldComponents.rotate_Z;
 	components.translate_X	= position.x;
 	components.translate_Y	= position.y;
 	components.translate_Z	= position.z;	
	
	[representedObject setTransformationComponents:components];
	
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

	LDrawPart					*representedObject = [self object];
	TransformationComponents	 components = [representedObject transformationComponents];
	
	NSString *description = [[LDrawApplication sharedPartLibrary] descriptionForPart:representedObject];
	[partDescriptionField setStringValue:description];
	[partDescriptionField setToolTip:description]; //in case it overflows the field.
	[partNameField setStringValue:[representedObject displayName]];
	
	[colorWell setColorCode:[representedObject LDrawColor]];

	Point3 position = [locationForm coordinateValue];
	Vector3 scaling = [scalingForm coordinateValue];
	Vector3 shear = [shearForm coordinateValue]; //not the right structure logically, but it works.
	
	position.x = components.translate_X;
	position.y = components.translate_Y;
	position.z = components.translate_Z;
	
	scaling.x = components.scale_X * 100.0; //convert to percentage.
	scaling.y = components.scale_Y * 100.0; //convert to percentage.
	scaling.z = components.scale_Z * 100.0; //convert to percentage.
	
	//stuff the shear into the structure, despite the bad name mismatches.
	shear.x = components.shear_XY;
	shear.y = components.shear_XZ;
	shear.z = components.shear_YZ;
	
	[locationForm setCoordinateValue:position];
	[scalingForm setCoordinateValue:scaling];
	[shearForm setCoordinateValue:shear];
	
	//Rotation is a bit trickier since we have two different modes for the data 
	// entered. An absolute rotation means that the actual rotation angles for 
	// the part are displayed and edited. A relative rotation means that what-
	// ever we enter in is added to the current angles.
 	[self setRotationAngles];
	

	[super revert:sender];
}

//========== setRotationAngles =================================================
//
// Purpose:		Fills in the rotation angles based on the data-entry mode:
//				absolute or relative.
//
//				An absolute rotation means that the actual rotation angles for 
//				the part are displayed and edited. A relative rotation means 
//				that whatever we enter in is *added to* the current angles.
//
//
//==============================================================================
- (void) setRotationAngles {
	
	LDrawPart					*representedObject = [self object];
	TransformationComponents	 components = [representedObject transformationComponents];
	
	rotationT					 rotationType = [[rotationTypePopUp selectedItem] tag];
	
	if(rotationType == rotationRelative){
		//Rotations entered will be additive.
		[rotationXField setFloatValue:0.0];
		[rotationYField setFloatValue:0.0];
		[rotationZField setFloatValue:0.0];
	}
	else{
		//Absolute rotation; fill in the real rotation angles.
		[rotationXField setFloatValue:degrees(components.rotate_X)];
		[rotationYField setFloatValue:degrees(components.rotate_Y)];
		[rotationZField setFloatValue:degrees(components.rotate_Z)];
		
	}
}

#pragma mark -

//========== applyRotationClicked: =============================================
//
// Purpose:		The user has entered new rotation values and now wants them to 
//				take effect. I set up this apply mechanism because it seemed 
//				like it would be odd for the rotations to take effect instantly.
//
//				This method is something like an alternate form of 
//				-finishedEditing: which modifies a different set of values.
//
//==============================================================================
- (IBAction) applyRotationClicked:(id)sender {

	LDrawPart					*representedObject = [self object];
	rotationT					rotationType = [[rotationTypePopUp selectedItem] tag];
	
	//Save out the current state.
	[representedObject snapshot];

	if(rotationType == rotationRelative){
		Tuple3 additiveRotation;
		
		additiveRotation.x = [rotationXField floatValue];
		additiveRotation.y = [rotationYField floatValue];
		additiveRotation.z = [rotationZField floatValue];
		
		[representedObject rotateByDegrees:additiveRotation];
	}
	//An absolute rotation.
	else{
		TransformationComponents components = [[self object] transformationComponents];
		
		components.rotate_X = radians([rotationXField floatValue]); //convert from degrees
		components.rotate_Y = radians([rotationYField floatValue]);
		components.rotate_Z = radians([rotationZField floatValue]);
		
		[representedObject setTransformationComponents:components];
	}
	
	//Note that the part has changed.
	[super finishedEditing:sender];
	
	//For a relative rotation, prepare for the next additive rotation by 
	// resetting the rotations values to zero
	if(rotationType == rotationRelative){
		[rotationXField setFloatValue:0.0];
		[rotationYField setFloatValue:0.0];
		[rotationZField setFloatValue:0.0];
	}
}

//========== locationEndedEditing: =============================================
//
// Purpose:		The user had been editing the coordinate; now he has stopped. 
//				We need to find out if he actually changed something. If so, 
//				update the object.
//
//==============================================================================
- (IBAction) locationEndedEditing:(id)sender{
	
	Point3					formContents	= [locationForm coordinateValue];
	TransformationComponents	components		= [[self object] transformationComponents];
	
	//If the values really did change, then update.
	if(		formContents.x != components.translate_X
		||	formContents.y != components.translate_Y
		||	formContents.z != components.translate_Z
	  )
		[self finishedEditing:sender];
}


//========== partNameEndedEditing: =============================================
//
// Purpose:		The user had been editing the part name; now he has stopped. 
//				We need to find out if he actually changed something. If so, 
//				update the object.
//
//==============================================================================
- (IBAction) partNameEndedEditing:(id)sender {
	NSString *newName = [partNameField stringValue];
	NSString *oldName = [[self object] displayName];
	
	if([oldName isEqualToString:newName] == NO){
		[self finishedEditing:sender];
		[self revert:sender];
	}
}


//========== rotationTypeChanged: ==============================================
//
// Purpose:		The pop-up menu specifying the rotation type has changed.
//
//==============================================================================
- (IBAction) rotationTypeChanged:(id)sender {
	
	[self setRotationAngles];
		
}


//========== scalingEndedEditing: ==============================================
//
// Purpose:		The user had been editing the scaling percentages; now he has 
//				stopped. 
//				We need to find out if he actually changed something. If so, 
//				update the object.
//
//==============================================================================
- (IBAction) scalingEndedEditing:(id)sender{

	Vector3					formContents	= [scalingForm coordinateValue];
	TransformationComponents	components		= [[self object] transformationComponents];

	//If the values really did change, then update.
	if(		formContents.x != components.scale_X * 100.0
	   ||	formContents.y != components.scale_Y * 100.0
	   ||	formContents.z != components.scale_Z * 100.0
	   )
		[self finishedEditing:sender];
}

//========== shearEndedEditing: ================================================
//
// Purpose:		The user had been editing the scaling percentages; now he has 
//				stopped. 
//				We need to find out if he actually changed something. If so, 
//				update the object.
//
//==============================================================================
- (IBAction) shearEndedEditing:(id)sender{
	
	Vector3					formContents	= [shearForm coordinateValue];
	TransformationComponents	components		= [[self object] transformationComponents];
	
	//If the values really did change, then update.
	// (please disregard the meaningless x, y, and z tags in the formContents.)
	if(		formContents.x != components.shear_XY
		||	formContents.y != components.shear_XZ
		||	formContents.z != components.shear_YZ
	  )
		[self finishedEditing:sender];
}

#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Abandon all hope ye who enter here.
//
//==============================================================================
- (void) dealloc {
	
	//Top level nib objects:
	[formatterBasic release];
	[formatterAngle release];
	[formatterScale release];
	
	[super dealloc];
}

@end
