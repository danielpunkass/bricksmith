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
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawPart.h"

#import <math.h>
#import <string.h>

#import "LDrawApplication.h"
#import "LDrawFile.h"
#import "LDrawModel.h"
#import "LDrawStep.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"
#import "PartLibrary.h"
#import "PartReport.h"

// Use the -[PartLibrary retainDisplayList:] to share optimized parts across all 
// instances. Otherwise, optimize each part individually. Contrary to 
// expectations, the latter yielded no speed benefit. However, it was necessary 
// to demonstrate Apple's bug in drawing nested display lists on separate 
// threads. 
#define SHARE_DISPLAY_LISTS_FOR_PART_COLOR_PAIRS 1

@implementation LDrawPart

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- partWithDirectiveText: ----------------------------------[static]--
//
// Purpose:		Given a line from an LDraw file, parse a part object.
//
//				directive should have the format:
//
//				1 color x y z a b c d e f g h i part.dat 
//
//------------------------------------------------------------------------------
+ (LDrawPart *) partWithDirectiveText:(NSString *)directive
{
	return [LDrawPart directiveWithString:directive];
	
}//end partWithDirectiveText:


//---------- directiveWithString: ------------------------------------[static]--
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
//------------------------------------------------------------------------------
+ (id) directiveWithString:(NSString *)lineFromFile
{
	LDrawPart   *parsedPart     = nil;
	NSString    *workingLine    = lineFromFile;
	NSString    *parsedField    = nil;
	
	Matrix4     transformation  = IdentityMatrix4;
	LDrawColorT colorCode       = LDrawColorBogus;
	GLfloat     customRGB[4]    = {0};
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	@try
	{
		//Read in the line code and advance past it.
		parsedField = [LDrawUtilities readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField integerValue] == 1){
			parsedPart = [LDrawPart new];
	
			//Read in the color code.
			// (color)
			parsedField = [LDrawUtilities readNextField:  workingLine
											  remainder: &workingLine ];
			colorCode = [LDrawUtilities parseColorCodeFromField:parsedField RGB:customRGB];
			if(colorCode == LDrawColorCustomRGB)
				[parsedPart setRGBColor:customRGB];
			else
				[parsedPart setLDrawColor:colorCode];
			
			//Read position.
			// (x)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[3][0] = [parsedField floatValue];
			// (y)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[3][1] = [parsedField floatValue];
			// (z)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[3][2] = [parsedField floatValue];
			
			
			//Read Transformation X.
			// (a)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[0][0] = [parsedField floatValue];
			// (b)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[1][0] = [parsedField floatValue];
			// (c)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[2][0] = [parsedField floatValue];
			
			
			//Read Transformation Y.
			// (d)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[0][1] = [parsedField floatValue];
			// (e)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[1][1] = [parsedField floatValue];
			// (f)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[2][1] = [parsedField floatValue];
			
			
			//Read Transformation Z.
			// (g)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[0][2] = [parsedField floatValue];
			// (h)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			transformation.element[1][2] = [parsedField floatValue];
			// (i)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
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
	}
	@catch(NSException *exception)
	{
		NSLog(@"the part %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [exception name]);
	}
	
	return [parsedPart autorelease];
	
}//end directiveWithString


//========== init ==============================================================
//
// Purpose:		Creates an empty part.
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	[self setDisplayName:@""];
	[self setTransformComponents:IdentityComponents];
//	drawLock = [[NSLock alloc] init];
	
	return self;
	
}//end init


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
	
}//end initWithCoder:


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
	
}//end encodeWithCoder:


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawPart	*copied			= (LDrawPart *)[super copyWithZone:zone];
	Matrix4		 transformation	= [self transformationMatrix];
	
	[copied setDisplayName:[self displayName]];
	[copied setTransformationMatrix:&transformation];
	
	return copied;
	
}//end copyWithZone:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== drawElement =======================================================
//
// Purpose:		Draws the graphic of the element represented. This call is a 
//				subroutine of -draw: in LDrawDrawableElement.
//
//==============================================================================
- (void) drawElement:(NSUInteger) optionsMask withColor:(GLfloat *)drawingColor
{
	LDrawModel  *modelToDraw    = nil;
	BOOL        drawBoundsOnly  = ((optionsMask & DRAW_BOUNDS_ONLY) != 0);
	
	if( hasDisplayList == YES && drawBoundsOnly == NO)
	{
		// Multithreading finally works with one display list per displayed part 
		// AND mutexes around the glCallList. But the mutex contention causes a 
		// 50% increase in drawing time. Gah! 
		
#if SHARE_DISPLAY_LISTS_FOR_PART_COLOR_PAIRS
		glPushMatrix();
			glMultMatrixf(glTransformation);
#endif
//			[drawLock lock];
			glCallList(self->displayListTag);
//			[drawLock unlock];

#if SHARE_DISPLAY_LISTS_FOR_PART_COLOR_PAIRS
		glPopMatrix();
#endif
	}
	else
	{
		glPushMatrix();
		{
//			glTranslated(0, 0, 0);
			glMultMatrixf(glTransformation);
			if(drawBoundsOnly == NO)
			{
				modelToDraw = [[LDrawApplication sharedPartLibrary] modelForPart:self];
				
				//let subreferences use display lists.
				[modelToDraw draw:(optionsMask) 
					  parentColor:drawingColor];
			}
			else
			{
				glColor4fv(drawingColor);
//				glColor4f(drawingColor[0], drawingColor[1], drawingColor[2], 0.25); // debug bounding boxes
				[self drawBounds];
			}
		}
		glPopMatrix();
	}

}//end drawElement:parentColor:


//========== drawBounds ========================================================
//
// Purpose:		Draws the part's bounds as a solid box. Nonrecursive.
//
//==============================================================================
- (void) drawBounds
{
	//Pull the bounds directly from the model; we can't use the part's because 
	// it mangles them based on rotation. In this case, we want to do a raw 
	// draw and let the model matrix transform our drawing appropriately.
	LDrawModel	*modelToDraw	= [[LDrawApplication sharedPartLibrary] modelForPart:self];
	
	//If the model can't be found, we can't draw good bounds for it!
	if(modelToDraw != nil)
	{
		Box3		bounds			= [modelToDraw boundingBox3];
		
		GLfloat		vertices[8][3]	= {	
										{bounds.min.x, bounds.min.y, bounds.min.z},
										{bounds.min.x, bounds.min.y, bounds.max.z},
										{bounds.min.x, bounds.max.y, bounds.max.z},
										{bounds.min.x, bounds.max.y, bounds.min.z},
										
										{bounds.max.x, bounds.min.y, bounds.min.z},
										{bounds.max.x, bounds.min.y, bounds.max.z},
										{bounds.max.x, bounds.max.y, bounds.max.z},
										{bounds.max.x, bounds.max.y, bounds.min.z},
									  };
									  
		GLfloat		normals[6][3]	= {
										{ 1,  0,  0}, //0: +x
										{ 0,  1,  0}, //1: +y
										{ 0,  0,  1}, //2: +z
										{-1,  0,  0}, //3: -x
										{ 1, -1,  0}, //4: -y
										{ 0,  0, -1}, //5: -z
									  };
									  
		//Well, this hardly looks like the most efficient block of code in the world.
		// I tried using vertex arrays, but it was a stunning failue.
		glBegin(GL_QUADS);
			
			//The normal vectors all are backwards from what I expected them to be. 
			//  Why?
			glNormal3fv(normals[0]);//expected 3
			glVertex3fv(vertices[0]);
			glVertex3fv(vertices[3]);
			glVertex3fv(vertices[2]);
			glVertex3fv(vertices[1]);
			
			glNormal3fv(normals[2]);//expected 5, etc.
			glVertex3fv(vertices[0]);
			glVertex3fv(vertices[4]);
			glVertex3fv(vertices[7]);
			glVertex3fv(vertices[3]);
			
			glNormal3fv(normals[4]);
			glVertex3fv(vertices[3]);
			glVertex3fv(vertices[7]);
			glVertex3fv(vertices[6]);
			glVertex3fv(vertices[2]);
			
			glNormal3fv(normals[5]);
			glVertex3fv(vertices[2]);
			glVertex3fv(vertices[6]);
			glVertex3fv(vertices[5]);
			glVertex3fv(vertices[1]);
			
			glNormal3fv(normals[1]);
			glVertex3fv(vertices[1]);
			glVertex3fv(vertices[5]);
			glVertex3fv(vertices[4]);
			glVertex3fv(vertices[0]);
			
			glNormal3fv(normals[3]);
			glVertex3fv(vertices[4]);
			glVertex3fv(vertices[5]);
			glVertex3fv(vertices[6]);
			glVertex3fv(vertices[7]);
			
		glEnd();
		
	}
}//end drawBounds


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
- (NSString *) write
{
	Matrix4 transformation = [self transformationMatrix];

	return [NSString stringWithFormat:
				@"1 %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@",
				[LDrawUtilities outputStringForColorCode:self->color RGB:self->glColor],
				
				[LDrawUtilities outputStringForFloat:transformation.element[3][0]], //position.x,			(x)
				[LDrawUtilities outputStringForFloat:transformation.element[3][1]], //position.y,			(y)
				[LDrawUtilities outputStringForFloat:transformation.element[3][2]], //position.z,			(z)
				
				[LDrawUtilities outputStringForFloat:transformation.element[0][0]], //transformationX.x,	(a)
				[LDrawUtilities outputStringForFloat:transformation.element[1][0]], //transformationX.y,	(b)
				[LDrawUtilities outputStringForFloat:transformation.element[2][0]], //transformationX.z,	(c)
				
				[LDrawUtilities outputStringForFloat:transformation.element[0][1]], //transformationY.x,	(d)
				[LDrawUtilities outputStringForFloat:transformation.element[1][1]], //transformationY.y,	(e)
				[LDrawUtilities outputStringForFloat:transformation.element[2][1]], //transformationY.z,	(f)
				
				[LDrawUtilities outputStringForFloat:transformation.element[0][2]], //transformationZ.x,	(g)
				[LDrawUtilities outputStringForFloat:transformation.element[1][2]], //transformationZ.y,	(h)
				[LDrawUtilities outputStringForFloat:transformation.element[2][2]], //transformationZ.z,	(i)
				
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
- (NSString *) browsingDescription
{
	return [[LDrawApplication sharedPartLibrary] descriptionForPart:self];
	
}//end browsingDescription


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName
{
	return @"Brick";
	
}//end iconName


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return @"InspectionPart";
	
}//end inspectorClassName


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object. Returns InvalidBox if the part 
//				cannot be found.
//
//==============================================================================
- (Box3) boundingBox3
{
	LDrawModel  *modelToDraw        = [[LDrawApplication sharedPartLibrary] modelForPart:self];
	Box3        bounds              = InvalidBox;
	Box3        transformedBounds   = InvalidBox;
	Matrix4     transformation      = [self transformationMatrix];
	
	// We need to have an actual model here. Blithely calling boundingBox3 will 
	// result in most of our Box3 structure being garbage data!
	if(modelToDraw != nil)
	{
		bounds = [modelToDraw boundingBox3];
		
		if(V3EqualBoxes(bounds, InvalidBox) == NO)
		{
			// Transform all the points of the bounding box to find the new 
			// minimum and maximum. 
			int     counter     = 0;
			Point3  vertices[8] = {	
									{bounds.min.x, bounds.min.y, bounds.min.z},
									{bounds.min.x, bounds.min.y, bounds.max.z},
									{bounds.min.x, bounds.max.y, bounds.max.z},
									{bounds.min.x, bounds.max.y, bounds.min.z},
									
									{bounds.max.x, bounds.min.y, bounds.min.z},
									{bounds.max.x, bounds.min.y, bounds.max.z},
									{bounds.max.x, bounds.max.y, bounds.max.z},
									{bounds.max.x, bounds.max.y, bounds.min.z},
								  };
			for(counter = 0; counter < 8; counter++)
			{
				vertices[counter] = V3MulPointByProjMatrix(vertices[counter], transformation);
				transformedBounds = V3UnionBoxAndPoint(transformedBounds, vertices[counter]);
			}
		}
	}
	
	return transformedBounds;
	
}//end boundingBox3


//========== displayName =======================================================
//
// Purpose:		Returns the name of the part as the user typed it. This 
//				maintains the user's upper- and lower-case usage.
//
//==============================================================================
- (NSString *) displayName
{
	return displayName;
	
}//end displayName


//========== enclosingFile =====================================================
//
// Purpose:		Returns the file of which this part is a member.
//
//==============================================================================
- (LDrawFile *) enclosingFile
{
	return [[[self enclosingStep] enclosingModel] enclosingFile];
	
}//end setModel:


//========== enclosingStep =====================================================
//
// Purpose:		Returns the step of which this step is a part.
//
//==============================================================================
- (LDrawStep *) enclosingStep
{
	return (LDrawStep *)[self enclosingDirective];
	
}//end setModel:


//========== position ==========================================================
//
// Purpose:		Returns the coordinates at which the part is drawn.
//
// Notes:		This is purely a convenience method. The actual position is 
//				encoded in the transformation matrix. If you wish to set the 
//				position, you should set either the matrix or the Transformation 
//				Components.
//
//==============================================================================
- (Point3) position
{
	TransformComponents	components	= [self transformComponents];
	Point3				position	= components.translate;
	
	return position;
	
}//end position

/*
To work, this needs to multiply the modelViewGLMatrix by the part transform.

//========== projectedBoundingBoxWithModelView:projection:view: ================
//
// Purpose:		Returns the 2D projection (ignore the z) of the object's bounds.
//
//==============================================================================
- (Box3) projectedBoundingBoxWithModelView:(const GLdouble *)modelViewGLMatrix
								projection:(const GLdouble *)projectionGLMatrix
									  view:(const GLint *)viewport
{
	LDrawModel  *modelToDraw    = [[LDrawApplication sharedPartLibrary] modelForPart:self];
	Box3        projectedBounds = InvalidBox;
	
	projectedBounds = [modelToDraw projectedBoundingBoxWithModelView:modelViewGLMatrix
														  projection:projectionGLMatrix
																view:viewport];
	
	return projectedBounds;
	
}//end projectedBoundingBoxWithModelView:projection:view:
*/

//========== referenceName =====================================================
//
// Purpose:		Returns the name of the part. This is the filename where the 
//				part is found. Since Macintosh computers are case-insensitive, 
//				I have adopted lower-case as the standard for names.
//
//==============================================================================
- (NSString *) referenceName
{
	return referenceName;
	
}//end referenceName


//========== referencedMPDSubmodel =============================================
//
// Purpose:		Returns the MPD model to which this part refers, or nil if there 
//				is no submodel in this part's file which has the name this part 
//				specifies.
//
// Note:		This method is ONLY intended to be used for resolving MPD 
//				references. If you want to resolve the general reference, you 
//				should call -modelForPart: in the PartLibrary!
//
//==============================================================================
- (LDrawModel *) referencedMPDSubmodel
{
	LDrawModel	*model			= nil;
	LDrawFile	*enclosingFile	= [self enclosingFile];
	
	if(enclosingFile != nil)
		model = (LDrawModel *)[enclosingFile modelWithName:self->referenceName];
	
	//No can do if we get a reference back to ourselves. That would be 
	// an infinitely-recursing reference, which is bad!
	if(model == [[self enclosingStep] enclosingModel])
		model = nil;
	
	return model;
}//end referencedMPDSubmodel


//========== transformComponents ===============================================
//
// Purpose:		Returns the individual components of the transformation matrix 
//			    applied to this part. 
//
//==============================================================================
- (TransformComponents) transformComponents
{
	Matrix4				transformation	= [self transformationMatrix];
	TransformComponents	components		= IdentityComponents;
	
	//This is a pretty darn neat little function. I wish I could say I wrote it.
	// It will extract all the user-friendly components out of this nasty matrix.
	Matrix4DecomposeTransformation( transformation, &components );

	return components;
	
}//end transformComponents


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
- (Matrix4) transformationMatrix
{
	return Matrix4CreateFromGLMatrix4(glTransformation);
	
}//end transformationMatrix


#pragma mark -

//========== setLDrawColor: ====================================================
//
// Purpose:		Sets the color of this element.
//
//==============================================================================
-(void) setLDrawColor:(LDrawColorT)newColor
{
	[super setLDrawColor:newColor];
	
	[self removeDisplayList];
	
}//end setLDrawColor:


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
-(void) setDisplayName:(NSString *)newPartName
{
	NSString *newReferenceName = [newPartName lowercaseString];

	[newPartName retain];
	[displayName release];
	
	displayName = newPartName;
	
	[newReferenceName retain];
	[referenceName release];
	referenceName = newReferenceName;
	
	// Force the part library to parse the model this part will display. This 
	// pushes all parsing into the same operation, which improves loading time 
	// predictability and allows better potential threading optimization. 
	[[LDrawApplication sharedPartLibrary] modelForPart:self];
	
	[self removeDisplayList];
	
}//end setDisplayName:


//========== setTransformComponents: ===========================================
//
// Purpose:		Converts the given componets (rotation, scaling, etc.) into an 
//				internal transformation matrix represenation.
//
//==============================================================================
- (void) setTransformComponents:(TransformComponents)newComponents
{
	Matrix4 transformation = Matrix4CreateTransformation(&newComponents);
	
	[self setTransformationMatrix:&transformation];

	[[NSNotificationCenter defaultCenter]
			postNotificationName:LDrawDirectiveDidChangeNotification
						  object:self];
						  
}//end setTransformComponents:


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
	Matrix4GetGLMatrix4(*newMatrix, glTransformation);
	
	[self removeDisplayList];
	
}//end setTransformationMatrix


#pragma mark -
#pragma mark MOVEMENT
#pragma mark -

//========== displacementForNudge: =============================================
//
// Purpose:		Returns the amount by which the element wants to move, given a 
//				"nudge" in the specified direction. A "nudge" is generated by 
//				pressing the arrow keys. We scale this value so as to make 
//				nudging go by plate-heights vertically and brick widths 
//				horizontally.
//
//==============================================================================
- (Vector3) displacementForNudge:(Vector3)nudgeVector
{
	Matrix4 transformationMatrix	= IdentityMatrix4;
	Matrix4 inverseMatrix			= IdentityMatrix4;
	Vector4 worldNudge				= {0, 0, 0, 1};
	Vector4 brickNudge				= {0};
	
	//convert incoming 3D vector to 4D for our math:
	worldNudge.x = nudgeVector.x;
	worldNudge.y = nudgeVector.y;
	worldNudge.z = nudgeVector.z;
	
	//Figure out which direction we're asking to move the part itself.
	transformationMatrix	= [self transformationMatrix];
	inverseMatrix			= Matrix4Invert( transformationMatrix );
	inverseMatrix.element[3][0] = 0; //zero out the translation part, leaving only rotation etc.
	inverseMatrix.element[3][1] = 0;
	inverseMatrix.element[3][2] = 0;
	
	//See if this is a nudge along the brick's "up" direction. 
	// If so, the nudge needs to be a different magnitude, to compensate 
	// for the fact that Lego bricks are not square!
	brickNudge = V4MulPointByMatrix(worldNudge, inverseMatrix);
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

	
	//we now have a nudge based on the correct size: plates or bricks.
	return nudgeVector;
	
}//end displacementForNudge:


//========== componentsSnappedToGrid:minimumAngle: =============================
//
// Purpose:		Returns a copy of the part's current components, but snapped to 
//			    the grid. Kinda a weird legacy API. 
//
//==============================================================================
- (TransformComponents) componentsSnappedToGrid:(float) gridSpacing
								   minimumAngle:(float)degrees
{
	TransformComponents	components		= [self transformComponents];
	
	return [self components:components snappedToGrid:gridSpacing minimumAngle:degrees];
	
}//end componentsSnappedToGrid:minimumAngle:


//========== components:snappedToGrid:minimumAngle: ============================
//
// Purpose:		Aligns the given components to an imaginary grid along lines 
//			    separated by a distance of gridSpacing. This is done 
//			    intelligently based on the current orientation of the receiver: 
//			    if gridSpacing == 20, that is assumed to mean "1 stud," so the 
//			    y-axis (up) of the part will be aligned along a grid spacing of 
//			    24 (1 stud vertically). 
//
//				The part's rotation angles will be adjusted to multiples of the 
//				minimum angle specified.
//
// Parameters:	components	- transform to adjust.
//				gridSpacing	- the grid line interval along stud widths.
//				degrees		- angle granularity. Pass 0 to leave angle 
//							  unchanged. 
//
//==============================================================================
- (TransformComponents) components:(TransformComponents)components
					 snappedToGrid:(float) gridSpacing
					  minimumAngle:(float)degrees
{
	float	rotationRadians			= radians(degrees);
	
	Matrix4 transformationMatrix	= IdentityMatrix4;
	Vector4 yAxisOfPart				= {0, 1, 0, 1};
	Vector4 worldY					= {0, 0, 0, 1}; //yAxisOfPart converted to world coordinates
	Vector3 worldY3					= {0, 0, 0};
	float	gridSpacingYAxis		= 0.0;
	float	gridX					= 0.0;
	float	gridY					= 0.0;
	float	gridZ					= 0.0;
	
	//---------- Adjust position to grid ---------------------------------------

	//Figure out which direction the y-axis is facing in world coordinates:
	transformationMatrix = [self transformationMatrix];
	transformationMatrix.element[3][0] = 0; //zero out the translation part, leaving only rotation etc.
	transformationMatrix.element[3][1] = 0;
	transformationMatrix.element[3][2] = 0;
	worldY	= V4MulPointByMatrix(yAxisOfPart, transformationMatrix);
	
	worldY3	= V3FromV4(worldY);
	worldY3 = V3IsolateGreatestComponent(worldY3);
	worldY3	= V3Normalize(worldY3);
	
	//Get the adjusted grid spacing along the y direction. Remember that Lego 
	// bricks are not cubical, so the grid along the brick's y-axis should be 
	// spaced differently from the grid along its other sides.
	gridSpacingYAxis = gridSpacing;
	
	if(fmod(gridSpacing, 20) == 0)
		gridSpacingYAxis *= 24.0 / 20.0;
	
	else if(fmod(gridSpacing, 10) == 0)
		gridSpacingYAxis *= 8.0 / 10.0;
		
	//The actual grid spacing, in world coordinates. We will adjust the approrpiate 
	// x, y, or z based on which one the part's y-axis is aligned.
	gridX = gridSpacing;
	gridY = gridSpacing;
	gridZ = gridSpacing;

	//Find the direction of the part's Y-axis, and change its grid.
	if(worldY3.x != 0)
		gridX = gridSpacingYAxis;
	
	if(worldY3.y != 0)
		gridY = gridSpacingYAxis;
	
	if(worldY3.z != 0)
		gridZ = gridSpacingYAxis;
	
	// Snap to the Grid!
	// Figure the closest grid line and bump the part to it.
	// Logically, this is a rounding operation with a granularity of the grid 
	// size. So all we need to do is normalize, round, then expand back to the 
	// original size. 
	
	components.translate.x = roundf(components.translate.x/gridX) * gridX;
	components.translate.y = roundf(components.translate.y/gridY) * gridY;
	components.translate.z = roundf(components.translate.z/gridZ) * gridZ;
	

	//---------- Snap angles ---------------------------------------------------
	
	if(rotationRadians != 0)
	{
		components.rotate.x = roundf(components.rotate.x/rotationRadians) * rotationRadians;
		components.rotate.y = roundf(components.rotate.y/rotationRadians) * rotationRadians;
		components.rotate.z = roundf(components.rotate.z/rotationRadians) * rotationRadians;
	}
	
	//round-off errors here? Potential for trouble.
	return components;
	
}//end components:snappedToGrid:minimumAngle:


//========== moveBy: ===========================================================
//
// Purpose:		Moves the receiver in the specified direction.
//
//==============================================================================
- (void) moveBy:(Vector3)moveVector
{	
	Matrix4 transformationMatrix	= [self transformationMatrix];

	//I NEED to modify the matrix itself here. Some parts have funky, fragile 
	// rotation values, and getting the components really badly botches them up.
	transformationMatrix = Matrix4Translate(transformationMatrix, moveVector);
	
	[self setTransformationMatrix:&transformationMatrix];
	
}//end moveBy:


//========== position:snappedToGrid: ===========================================
//
// Purpose:		Orients position at discrete points separated by the given grid 
//				spacing. 
//
// Notes:		This method may be overridden by subclasses to provide more 
//				intelligent grid alignment. 
//
//				This method is provided mainly as a service to drag-and-drop. 
//				In the case of LDrawParts, you should generally avoid this 
//				method in favor of 
//				-[LDrawPart components:snappedToGrid:minimumAngle:].
//
//==============================================================================
- (Point3) position:(Point3)position
	  snappedToGrid:(float)gridSpacing
{
	TransformComponents	components	= IdentityComponents;
	
	// copy the position into a transform
	components.translate = position;
	
	// Snap to grid using intelligent LDrawPart logic
	components = [self components:components snappedToGrid:gridSpacing minimumAngle:0];
	
	// copy the new position back out of the components
	position = components.translate;
	
	return position;
	
}//end position:snappedToGrid:


//========== rotateByDegrees: ==================================================
//
// Purpose:		Rotates the part by the specified angles around its centerpoint.
//
//==============================================================================
- (void) rotateByDegrees:(Tuple3)degreesToRotate
{
	Point3	partCenter	= [self position];
	
	//Rotate!
	[self rotateByDegrees:degreesToRotate centerPoint:partCenter];
	
}//end rotateByDegrees


//========== rotateByDegrees:centerPoint: ======================================
//
// Purpose:		Performs an additive rotation on the part, rotating by the 
//				specified number of degress around each axis. The part will be 
//				rotated around the specified centerpoint.
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
//				Caveat: We have to do some translations to take into account the  
//				centerpoint.
//
//==============================================================================
- (void) rotateByDegrees:(Tuple3)degreesToRotate
			 centerPoint:(Point3)rotationCenter
{
	Matrix4						transform			= [self transformationMatrix];
	Vector3						displacement		= rotationCenter;
	Vector3						negativeDisplacement= V3Negate(rotationCenter);
	
	//Do the rotation around the specified centerpoint.
	transform = Matrix4Translate(transform, negativeDisplacement); //translate to rotationCenter
	transform = Matrix4Rotate(transform, degreesToRotate); //rotate at rotationCenter
	transform = Matrix4Translate(transform, displacement); //translate back to original position
	
	[self setTransformationMatrix:&transform];
	
}//end rotateByDegrees:centerPoint:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== flattenIntoLines:triangles:quadrilaterals:other:currentColor: =====
//
// Purpose:		Appends the directive into the appropriate container. 
//
//==============================================================================
- (void) flattenIntoLines:(LDrawStep *)lines
				triangles:(LDrawStep *)triangles
		   quadrilaterals:(LDrawStep *)quadrilaterals
					other:(LDrawStep *)everythingElse
			 currentColor:(LDrawColorT)parentColor
		 currentTransform:(Matrix4)transform
		  normalTransform:(Matrix3)normalTransform
{
	LDrawModel  *modelToDraw        = nil;
	LDrawModel  *flatCopy           = nil;
	Matrix4		partTransform		= [self transformationMatrix];
	Matrix4     combinedTransform   = IdentityMatrix4;

	[super flattenIntoLines:lines
				  triangles:triangles
			 quadrilaterals:quadrilaterals
					  other:everythingElse
			   currentColor:parentColor
		   currentTransform:transform
			normalTransform:normalTransform];
	
	// Flattening involves applying the part's transform to copies of all 
	// referenced vertices. (We are forced to make copies because you can't call 
	// glMultMatrix inside a glBegin; the only way to draw all like geometry at 
	// once is to have a flat, transformed copy of it.) 
	
	modelToDraw = [[LDrawApplication sharedPartLibrary] modelForPart:self];
	flatCopy    = [modelToDraw copy];
	
	// concatenate the transform and pass it down
	combinedTransform   = Matrix4Multiply(transform, partTransform);
	
	// Normals are actually transformed by a different matrix.
	normalTransform     = Matrix3MakeNormalTransformFromProjMatrix(combinedTransform);
	
	[flatCopy flattenIntoLines:lines
					 triangles:triangles
				quadrilaterals:quadrilaterals
						 other:everythingElse
				  currentColor:[self LDrawColor]
			  currentTransform:combinedTransform
			   normalTransform:normalTransform ];
	
	[flatCopy release];

}//end flattenIntoLines:triangles:quadrilaterals:other:currentColor:


//========== collectPartReport: ================================================
//
// Purpose:		Collects a report on this part. If this is really an MPD 
//				reference, we want to get a report on the submodel and not this 
//				actual part.
//
//==============================================================================
- (void) collectPartReport:(PartReport *)report
{
	LDrawModel *referencedSubmodel = [self referencedMPDSubmodel];
	//There's a bug here: -referencedMPDSubmodel doesn't necessarily tell you if 
	// this actually *is* a submodel reference. It may actually resolve to 
	// something in the part library. In this case, we would draw the library 
	// part, but report the submodel! I'm going to let this ride, because the 
	// specification explicitly says the behavior in such a case is undefined.
	
	if(referencedSubmodel == nil)
		[report registerPart:self];
	else {
		[referencedSubmodel collectPartReport:report];
	}
}//end collectPartReport:


//========== optimizeOpenGL ===================================================
//
// Purpose:		Makes this part run faster by compiling its contents into a 
//				display list if possible.
//
//				This optimization mechanism can only be managed by the 
//				containers which hold the part. 
//
//==============================================================================
- (void) optimizeOpenGL
{
#if SHARE_DISPLAY_LISTS_FOR_PART_COLOR_PAIRS //{
	// Only optimize explicitly colored parts.
	// Uncolored parts need to know about the current color 
	// as they are drawn, which is anathema to optimization. Rats.
	if(self->referenceName != nil && self->color != LDrawCurrentColor)
	{
		LDrawModel *referencedSubmodel	= [self referencedMPDSubmodel];
		
		if(referencedSubmodel == nil)
		{
			self->displayListTag = [[LDrawApplication sharedPartLibrary]
											retainDisplayListForPart:self
															   color:self->glColor];

			if(displayListTag != 0)
				self->hasDisplayList = YES;
		}
		else
		{
			// Don't optimize MPD references. The user can change their 
			// referenced contents, and I don't want to have to keep track 
			// of invalidating display lists when he does. 
		}
	}
	else
		self->hasDisplayList = NO;

// }	
#else //{
	if(self->hasDisplayList == YES)
		[self removeDisplayList];

	if(self->referenceName != nil)
	{
		LDrawModel *referencedSubmodel	= [self referencedMPDSubmodel];
		
		if(referencedSubmodel == nil)
		{
			self->displayListTag = glGenLists(1); //create new list name
			if(self->displayListTag != 0)
			{
				glNewList(self->displayListTag, GL_COMPILE);
					[self draw:DRAW_FOR_DISPLAY_LIST_COMPILE parentColor:self->glColor];
				glEndList();
				
				self->hasDisplayList = YES;
			}
		}
		else
		{
			// Don't optimize MPD references. The user can change their 
			// referenced contents, and I don't want to have to keep track 
			// of invalidating display lists when he does. 
		}
	}
#endif // }
}//end optimizeOpenGL


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager
{
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setTransformComponents:[self transformComponents]];
	[[undoManager prepareWithInvocationTarget:self] setDisplayName:[self displayName]];
	[[undoManager prepareWithInvocationTarget:self] optimizeOpenGL];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesPart", nil)];

}//end registerUndoActions:


//========== removeDisplayList =================================================
//
// Purpose:		Delete the now-invalid associated display list.
//
//==============================================================================
- (void) removeDisplayList
{
#if SHARE_DISPLAY_LISTS_FOR_PART_COLOR_PAIRS == 0 // {
	if(self->hasDisplayList)
	{
		glDeleteLists(self->displayListTag, 1);
		self->hasDisplayList = NO;
	}
#else // }{
	if(self->hasDisplayList)
	{
		self->hasDisplayList = NO;
	}
#endif // }
}//end removeDisplayList


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		It's time to go home to that great Lego room in the sky--where 
//				all teeth marks on secondhand bricks are healed, where the gold 
//				print never rubs off the classic spacemen, and where the white 
//				bricks never discolor.
//
//==============================================================================
- (void) dealloc
{
	//release instance variables.
	[displayName	release];
	[referenceName	release];
	
	[self removeDisplayList];
	
	[super dealloc];
	
}//end dealloc

@end
