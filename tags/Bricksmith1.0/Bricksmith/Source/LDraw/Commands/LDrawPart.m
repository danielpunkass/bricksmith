//==============================================================================
//
// File:		LDrawPart.m
//
// Purpose:		Part command.
//				Inserts a part defined in another LDraw file.
//
//				Line format:
//				1 colour x y z a b c d e f g h i part.dat 
//
//				where
//
//				* colour is a colour code: 0-15, 16, 24, 32-47, 256-511
//				* x, y, z is the position of the part
//				* a - i are orientation & scaling parameters
//				* part.dat is the filename of the included file 
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawPart.h"

#import <math.h>

#import "LDrawApplication.h"
#import "LDrawModel.h"
#import "LDrawStep.h"
#import "MacLDraw.h"

@implementation LDrawPart

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== partWithDirectiveText: ============================================
//
// Purpose:		Given a line from an LDraw file, parse a part object.
//
//				directive should have the format:
//
//				1 color x y z a b c d e f g h i part.dat 
//
//==============================================================================
+ (LDrawPart *) partWithDirectiveText:(NSString *)directive{
	return [LDrawPart directiveWithString:directive];
}


//========== directiveWithString: ==============================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//				Line format:
//				1 colour x y z a b c d e f g h i part.dat 
//
//				Matrix format:
//				+-       -+
//				| a d g 0 |
//				| b e h 0 |
//				| c f i 0 |
//				| x y z 1 |
//				+-       -+
//
//==============================================================================
+ (id) directiveWithString:(NSString *)lineFromFile{
	LDrawPart		*parsedPart = nil;
	NSString		*workingLine = lineFromFile;
	NSString		*parsedField;
	
	Matrix4			 transformation = {0};
	Point3		 workingPosition;
	Vector3		 transformationVector;
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	NS_DURING
		//Read in the line code and advance past it.
		parsedField = [LDrawDirective readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField intValue] == 1){
			parsedPart = [LDrawPart new];
	
			//Read in the color code.
			// (color)
			parsedField = [LDrawDirective readNextField:  workingLine
											  remainder: &workingLine ];
			[parsedPart setLDrawColor:[parsedField intValue]];
			
			//Read position.
			// (x)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[3][0] = [parsedField floatValue];
			// (y)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[3][1] = [parsedField floatValue];
			// (z)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[3][2] = [parsedField floatValue];
			
			
			//Read Transformation X.
			// (a)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[0][0] = [parsedField floatValue];
			// (b)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[1][0] = [parsedField floatValue];
			// (c)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[2][0] = [parsedField floatValue];
			
			
			//Read Transformation Y.
			// (d)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[0][1] = [parsedField floatValue];
			// (e)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[1][1] = [parsedField floatValue];
			// (f)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[2][1] = [parsedField floatValue];
			
			
			//Read Transformation Z.
			// (g)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[0][2] = [parsedField floatValue];
			// (h)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[1][2] = [parsedField floatValue];
			// (i)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			transformation.element[2][2] = [parsedField floatValue];
			
			//finish off the corner of the matrix.
			transformation.element[3][3] = 1;
			
			[parsedPart setTransformationMatrix:&transformation];
			
			//Read Part Name
			// (part.dat) -- It can have spaces (for MPD models), so we just use the whole 
			// rest of the line.
			[parsedPart setDisplayName:
				[workingLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
		}
		
	NS_HANDLER
		NSLog(@"the part %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [localException name]);
	NS_ENDHANDLER
	
	return parsedPart;
}//end directiveWithString


//========== init ==============================================================
//
// Purpose:		Creates an empty part.
//
//==============================================================================
- (id) init {
	self = [super init];
	
	[self setDisplayName:@""];
	//Come up with a blank transformation; all it does is show the part at 
	// the origin, rotation <0,0,0>.
	TransformationComponents identity = {0}; //zero out all components.
	identity.scale_X = 1;
	identity.scale_Y = 1;
	identity.scale_Z = 1;
	[self setTransformationComponents:identity];
	
	return self;
}


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id)initWithCoder:(NSCoder *)decoder
{
	const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
	
	self		= [super initWithCoder:decoder];
	
	[self setDisplayName:[decoder decodeObjectForKey:@"displayName"]];
	
	//Decoding structures is a bit messy.
	temporary	= [decoder decodeBytesForKey:@"glTransformation" returnedLength:NULL];
	memcpy(glTransformation, temporary, sizeof(GLfloat)*16 );
	
	return self;
}


//========== encodeWithCoder: ==================================================
//
// Purpose:		Writes a representation of this object to the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeObject:displayName	forKey:@"displayName"];
	[encoder encodeBytes:(void *)glTransformation
				  length:sizeof(GLfloat)*16
				  forKey:@"glTransformation"];
	
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawPart	*copied			= (LDrawPart *)[super copyWithZone:zone];
	Matrix4		 transformation	= [self transformationMatrix];
	
	[copied setDisplayName:[self displayName]];
	[copied setTransformationMatrix:&transformation];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== drawElement =======================================================
//
// Purpose:		Draws the graphic of the element represented. This call is a 
//				subroutine of -draw: in LDrawDrawableElement.
//
//==============================================================================
- (void) drawElement:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor {
	LDrawModel *modelToDraw = [[LDrawApplication sharedPartLibrary] modelForPart:self];
	
	//glMatrixMode(GL_MODELVIEW); //unnecessary, we set the matrix mode at the beginning of drawing.
	glPushMatrix();
		glMultMatrixf(glTransformation);
		[modelToDraw draw:optionsMask parentColor:parentColor];
	glPopMatrix();
	
}


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//
//				Line format:
//				1 colour x y z a b c d e f g h i part.dat 
//
//				Matrix format:
//				+-       -+
//				| a d g 0 |
//				| b e h 0 |
//				| c f i 0 |
//				| x y z 1 |
//				+-       -+
//
//==============================================================================
- (NSString *) write{

	Matrix4 transformation = [self transformationMatrix];

	return [NSString stringWithFormat:
				@"1 %3d %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f %@",
				color,
				
				transformation.element[3][0], //position.x,			(x)
				transformation.element[3][1], //position.y,			(y)
				transformation.element[3][2], //position.z,			(z)
				
				transformation.element[0][0], //transformationX.x,	(a)
				transformation.element[1][0], //transformationX.y,	(b)
				transformation.element[2][0], //transformationX.z,	(c)
				
				transformation.element[0][1], //transformationY.x,	(d)
				transformation.element[1][1], //transformationY.y,	(e)
				transformation.element[2][1], //transformationY.z,	(f)
				
				transformation.element[0][2], //transformationZ.x,	(g)
				transformation.element[1][2], //transformationZ.y,	(h)
				transformation.element[2][2], //transformationZ.z,	(i)
				
				displayName
			];
}//end write

#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//				Here we want the part name displayed.
//
//==============================================================================
- (NSString *)browsingDescription
{
	return [[LDrawApplication sharedPartLibrary] descriptionForPart:self];
}


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName{
	return @"Brick";
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"InspectionPart";
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object.
//
//==============================================================================
- (Box3) boundingBox3 {
	LDrawModel *modelToDraw = [[LDrawApplication sharedPartLibrary] modelForPart:self];

	Box3	bounds			= [modelToDraw boundingBox3];
	Box3	partBounds		= {0};
	Matrix4	transformation	= [self transformationMatrix];
	
	Point4	originalMin		= V4FromV3( &(bounds.min) );
	Point4	originalMax		= V4FromV3( &(bounds.max) );
	Point4	rotatedMin		= {0};
	Point4	rotatedMax		= {0};
	
	V4MulPointByMatrix(&originalMin, &transformation, &rotatedMin);
	V4MulPointByMatrix(&originalMax, &transformation, &rotatedMax);
	
	V3BoundsFromPoints(&rotatedMin, &rotatedMax, &bounds);
	
	return bounds;
}


//========== enclosingStep =====================================================
//
// Purpose:		Returns the step of which this step is a part.
//
//==============================================================================
- (LDrawStep *) enclosingStep
{
	return (LDrawStep *)[self enclosingDirective];
}//end setModel:


//========== displayName =======================================================
//
// Purpose:		Returns the name of the part as the user typed it. This 
//				maintains the user's upper- and lower-case usage.
//
//==============================================================================
- (NSString *) displayName {
	return displayName;
}

//========== referenceName =====================================================
//
// Purpose:		Returns the name of the part. This is the filename where the 
//				part is found. Since Macintosh computers are case-insensitive, 
//				I have adopted lower-case as the standard for names.
//
//==============================================================================
- (NSString *) referenceName{
	return referenceName;
}


//========== setTransformationComponents: ======================================
//
// Purpose:		Converts the given componets (rotation, scaling, etc.) into an 
//				internal transformation matrix represenation.
//
//==============================================================================
- (TransformationComponents) transformationComponents
{
	Matrix4						transformation = [self transformationMatrix];
	TransformationComponents	components = {0};
	
	//This is a pretty darn neat little function. I wish I could say I wrote it.
	// It will extract all the user-friendly components out of this nasty matrix.
	unmatrix( &transformation, &components );

	return components;
}


//========== transformationMatrix ==============================================
//
// Purpose:		Returns a two-dimensional (row matrix) representation of the 
//				part's transformation matrix.
//
//																+-       -+
//				+-                           -+        +-     -+| a d g 0 |
//				|a d g 0 b e h c f i 0 x y z 1|  -->   |x y z 1|| b e h 0 |
//				+-                           -+        +-     -+| c f i 0 |
//																| x y z 1 |
//																+-       -+
//					  OpenGL Matrix Format                 LDraw Matrix
//				(flat column-major of transpose)              Format
//
//==============================================================================
- (Matrix4) transformationMatrix {
	return matrix4FromGLMatrix4(glTransformation);
}


//========== setDisplayName: ===================================================
//
// Purpose:		Updates the name of the part. This is the filename where the 
//				part is found.
//
// Notes:		References to LDraw/parts and LDraw/p are simply encoded as the 
//				file name. However, references to LDraw/parts/s are encoded as 
//				"s\partname.dat". The part library, meanwhile, must properly 
//				handle the s\ prefix.
//
//==============================================================================
-(void) setDisplayName:(NSString *)newPartName{
	NSString *newReferenceName = [newPartName lowercaseString];

	[newPartName retain];
	[displayName release];
	
	displayName = newPartName;
	
	[newReferenceName retain];
	[referenceName release];
	referenceName = newReferenceName;
}//end setPartName


//========== setTransformationComponents: ======================================
//
// Purpose:		Converts the given componets (rotation, scaling, etc.) into an 
//				internal transformation matrix represenation.
//
//==============================================================================
- (void) setTransformationComponents:(TransformationComponents)newComponents
{
	Matrix4 transformation = createTransformationMatrix(&newComponents);
	[self setTransformationMatrix:&transformation];

	[[NSNotificationCenter defaultCenter]
			postNotificationName:LDrawDirectiveDidChangeNotification
						  object:self];
}


//========== setTransformationMatrix: ==========================================
//
// Purpose:		Converts the row-major row-vector matrix into a flat column-
//				major column-vector matrix understood by OpenGL.
//
//
//			 +-       -+     +-       -++- -+
//	+-     -+| a d g 0 |     | a b c x || x |
//	|x y z 1|| b e h 0 |     | d e f y || y |     +-                           -+
//	+-     -+| c f i 0 | --> | g h i z || z | --> |a d g 0 b e h c f i 0 x y z 1|
//			 | x y z 1 |     | 0 0 0 1 || 1 |     +-                           -+
//			 +-       -+     +-       -++- -+
//		LDraw Matrix            Transpose               OpenGL Matrix Format
//		   Format                                 (flat column-major of transpose)
//  (also Matrix4 format)
//
//==============================================================================
- (void) setTransformationMatrix:(Matrix4 *)newMatrix
{
	int row, column;
	
	for(row = 0; row < 4; row++)
		for(column = 0; column < 4; column++)
			glTransformation[row * 4 + column] = newMatrix->element[row][column];
}


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== nudge: ============================================================
//
// Purpose:		Moves the receiver in the specified direction.
//
//==============================================================================
- (void) nudge:(Vector3)nudgeVector{
	
	Matrix4 transformationMatrix	= {0};
	Matrix4 inverseMatrix			= {0};
	Vector4 worldNudge				= {0, 0, 0, 1};
	Vector4 brickNudge				= {0};
	
	//convert incoming 3D vector to 4D for our math:
	worldNudge.x = nudgeVector.x;
	worldNudge.y = nudgeVector.y;
	worldNudge.z = nudgeVector.z;
	
	//Figure out which direction we're asking to move the part itself.
	transformationMatrix = [self transformationMatrix];
	inverse( &transformationMatrix, &inverseMatrix );
	inverseMatrix.element[3][0] = 0; //zero out the translation part, leaving only rotation etc.
	inverseMatrix.element[3][1] = 0;
	inverseMatrix.element[3][2] = 0;
	
	//See if this is a nudge along the brick's "up" direction. 
	// If so, the nudge needs to be a different magnitude, to compensate 
	// for the fact that Lego bricks are not square!
	V4MulPointByMatrix(&worldNudge, &inverseMatrix, &brickNudge);
	if(fabs(brickNudge.y) > fabs(brickNudge.x) && 
	   fabs(brickNudge.y) > fabs(brickNudge.z) )
	{
		//The trouble is, we need to do different things for different 
		// scales. For instance, in medium mode, we probably want to 
		// move 1/2 stud horizontally but 1/3 stud vertically.
		//
		// But in coarse mode, we want to move 1 stud horizontally and 
		// vertically. These are different ratios! So I test for known 
		// numbers, and only apply modifications if they are recognized.
		
		if(fmod(nudgeVector.x, 20) == 0)
			nudgeVector.x *= 24.0 / 20.0;
		else if(fmod(nudgeVector.x, 10) == 0)
			nudgeVector.x *= 8.0 / 10.0;
		
		if(fmod(nudgeVector.y, 20) == 0)
			nudgeVector.y *= 24.0 / 20.0;
		else if(fmod(nudgeVector.y, 10) == 0)
			nudgeVector.y *= 8.0 / 10.0;
		
		if(fmod(nudgeVector.z, 20) == 0)
			nudgeVector.z *= 24.0 / 20.0;
		else if(fmod(nudgeVector.z, 10) == 0)
			nudgeVector.z *= 8.0 / 10.0;
	}

	
	//Needs to be more complicated! I could just modify the matrix itself, 
	// you know!

	TransformationComponents transformation = [self transformationComponents];
	
	transformation.translate_X += nudgeVector.x;
	transformation.translate_Y += nudgeVector.y;
	transformation.translate_Z += nudgeVector.z;
	
	//round-off errors here? Potential for trouble.
	[self setTransformationComponents:transformation];
}


//========== snapToGrid: =======================================================
//
// Purpose:		Aligns the receiver to an imaginary grid along lines separated 
//				by a distance of gridSpacing. This is done intelligently:
//				if gridSpacing == 20, that is assumed to mean "1 stud," so the 
//				y-axis (up) of the part will be aligned along a grid spacing of 
//				24 (1 stud vertically).
//
//				The part's rotation angles will be adjusted to multiples of the 
//				minimum angle specified.
//
//==============================================================================
- (TransformationComponents) componentsSnappedToGrid:(float) gridSpacing
										minimumAngle:(float)degrees
{
	
	TransformationComponents components = [self transformationComponents];
	float rotationRadians = radians(degrees);
	
	Matrix4 transformationMatrix	= {0};
	Matrix4 inverseMatrix			= {0};
	Vector4 brickNudge				= {0};
	
	Vector4 yAxisOfPart				= {0, 1, 0, 1};
	Vector4 worldY					= {0, 0, 0, 1}; //yAxisOfPart converted to world coordinates
	Vector3 worldY3					= {0, 0, 0};
	
	//Figure out which direction the y-axis is facing in world coordinates:
	transformationMatrix = [self transformationMatrix];
	V4MulPointByMatrix(&yAxisOfPart, &transformationMatrix, &brickNudge);
	
	worldY3 = V3FromV4(&worldY);
	V3IsolateGreatestComponent(&worldY3);
	V3Normalize(&worldY3);
	
	//Get the adjusted grid spacing along the y direction. Remember that Lego 
	// bricks are not cubical, so the grid along the brick's y-axis should be 
	// spaced differently from the grid along its other sides.
	float gridSpacingYAxis = gridSpacing;
	
	if(fmod(gridSpacing, 20) == 0)
		gridSpacingYAxis *= 24.0 / 20.0;
	else if(fmod(gridSpacing, 10) == 0)
		gridSpacingYAxis *= 8.0 / 10.0;
		
	//The actual grid spacing, in world coordinates. We will adjust the approrpiate 
	// x, y, or z based on which one the part's y-axis is aligned.
	float gridX = gridSpacing;
	float gridY = gridSpacing;
	float gridZ = gridSpacing;
	
	//Find the direction of the part's Y-axis, and change its grid.
	if(worldY3.x != 0)
		gridX = gridSpacingYAxis;
	
	if(worldY3.y != 0)
		gridY = gridSpacingYAxis;
	
	if(worldY3.z != 0)
		gridZ = gridSpacingYAxis;
	
	// Snap to the Grid!
	// Figure the closest grid line and bump the part to it.
	
	float devianceX = fmod(components.translate_X, gridSpacing);
	float devianceY = fmod(components.translate_Y, gridSpacing);
	float devianceZ = fmod(components.translate_Z, gridSpacing);
	
	// correct x-axis
	if(devianceX > gridX/2)
		components.translate_X += (gridX - devianceX);
	else	
		components.translate_X -= devianceX;
		
	// correct y-axis
	if(devianceY > gridY/2)
		components.translate_Y += (gridY - devianceY);
	else	
		components.translate_Y -= devianceY;
	
	// correct z-axis
	if(devianceZ > gridZ/2)
		components.translate_Z += (gridZ - devianceZ);
	else	
		components.translate_Z -= devianceZ;
	
	//
	// Snap angles.
	//
	devianceX = fmod(components.rotate_X, rotationRadians);
	devianceY = fmod(components.rotate_Y, rotationRadians);
	devianceZ = fmod(components.rotate_Z, rotationRadians);
	
	// correct x-rotation
	if(devianceX > rotationRadians/2)
		components.rotate_X += (rotationRadians - devianceX);
	else	
		components.rotate_X -= devianceX;
		
	// correct x-rotation
	if(devianceY > rotationRadians/2)
		components.rotate_Y += (rotationRadians - devianceY);
	else	
		components.rotate_Y -= devianceY;
	
	// correct x-rotation
	if(devianceZ > rotationRadians/2)
		components.rotate_Z += (rotationRadians - devianceZ);
	else	
		components.rotate_Z -= devianceZ;
	
	
	
	//round-off errors here? Potential for trouble.
	return components;
}


//========== rotateByDegrees: ==================================================
//
// Purpose:		Performs an additive rotation on the part, rotating by the 
//				specified number of degress around each axis.
//
// Notes:		This gets a little tricky because there is more than one way 
//				to represent a single rotation when using three rotation angles. 
//				Since we don't really know which one was intended, we can't just 
//				blithely manipulate the rotation components.
//
//				Instead, we must generate a new transformation matrix that 
//				rotates by degreesToRotate in the desired direction. Then we 
//				multiply that matrix by the part's current transformation. This 
//				way, we can rest assured that we rotated the part exactly the 
//				direction the user intended, no matter what goofy representation
//				the components came up with.
//
//				Caveat: We have to zero out the translation components of the 
//				part's transformation before we append our new rotation. Thus 
//				the part will be rotated in place.
//
//==============================================================================
- (void) rotateByDegrees:(Tuple3)degreesToRotate
{
	TransformationComponents	originalComponents	= [self transformationComponents];
	TransformationComponents	currentComponents	= originalComponents;
	TransformationComponents	rotateComponents	= {0};
	Matrix4						initialRotation		= {0}; //we'll remove the translation.
	Matrix4						addedRotation		= {0};
	Matrix4						newMatrix			= {0};
	TransformationComponents	newComponents		= {0};
	
	//Zero out the translation on the current matrix. This leaves us with 
	// only transformations at the origin, so we can rotate as we please.
	currentComponents.translate_X = 0;
	currentComponents.translate_Y = 0;
	currentComponents.translate_Z = 0;
	initialRotation = createTransformationMatrix(&currentComponents);
	
	//Create a new matrix that causes the rotation we want.
	rotateComponents.scale_X = 1; //
	rotateComponents.scale_Y = 1; // (start with identity matrix)
	rotateComponents.scale_Z = 1; //
	rotateComponents.rotate_X = radians(degreesToRotate.x);
	rotateComponents.rotate_Y = radians(degreesToRotate.y);
	rotateComponents.rotate_Z = radians(degreesToRotate.z);
	addedRotation = createTransformationMatrix(&rotateComponents);
	
	//Concatenate this new rotation onto the old one. (Our part is now rotated!)
	// Then restore the original translation. Our part thereby has been rotated 
	// in place.
	V3MatMul(&initialRotation, &addedRotation, &newMatrix);
	newMatrix.element[3][0] = originalComponents.translate_X; //applied directly to 
	newMatrix.element[3][1] = originalComponents.translate_Y; //the matrix because 
	newMatrix.element[3][2] = originalComponents.translate_Z; //that's easier here.
	
	
	[self setTransformationMatrix:&newMatrix];
}


#pragma mark -
#pragma mark UTILITIES
#pragma mark -


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager {
	
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setTransformationComponents:[self transformationComponents]];
	[[undoManager prepareWithInvocationTarget:self] setDisplayName:[self displayName]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesPart", nil)];
}


@end
