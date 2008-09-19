//==============================================================================
//
// File:		MatrixMath.h
//
// Purpose:		Mathematical library for computer graphics
//
//				Stolen heavily from GraphicsGems.h  
//				Version 1.0 - Andrew Glassner
//				from "Graphics Gems", Academic Press, 1990
//
//==============================================================================
#include "MatrixMath.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

//Box which represents no bounds. It is defined in such a way that it can 
// be used transparently in size comparisons -- its minimum is inifinity,
// so any valid point will be smaller than that!
const Box3 InvalidBox = {	{ INFINITY,  INFINITY,  INFINITY},
							{-INFINITY, -INFINITY, -INFINITY}   };
							
const TransformComponents IdentityComponents = {
							{1, 1, 1},	//scale;
							0,			//shear_XY;
							0,			//shear_XZ;
							0,			//shear_YZ;
							{0, 0, 0},	//rotate;		//in radians
							{0, 0, 0},	//translate;
							{0, 0, 0, 0}//perspective;
						};

const Matrix4 IdentityMatrix4 = {{	{1, 0, 0, 0},
									{0, 1, 0, 0},
									{0, 0, 1, 0},
									{0, 0, 0, 1} }};

const Point3 ZeroPoint3 = {0.0, 0.0, 0.0};
const Point4 ZeroPoint4 = {0.0, 0.0, 0.0, 0.0};

#pragma mark 2-D LIBRARY
#pragma mark -

/*
 * float = det2x2( float a, float b, float c, float d )
 * 
 * calculate the determinant of a 2x2 matrix.
 */
float det2x2( float a, float b, float c, float d)
{
    float ans;
    ans = a * d - b * c;
    return ans;
}


#pragma mark -
#pragma mark 3-D LIBRARY
#pragma mark -

//========== V3Make ============================================================
//
// Purpose:		create, initialize, and return a new vector
//
//==============================================================================
Vector3 V3Make(float x, float y, float z)
{
	Vector3 v;
	v.x = x;  v.y = y;  v.z = z;
	return(v);
	
}//end V3Make


/* create, initialize, and return a duplicate vector */
Vector3 *V3Duplicate(Vector3 *a)
{
	Vector3 *v = NEWTYPE(Vector3);
	v->x = a->x;  v->y = a->y;  v->z = a->z;
	return(v);
}


//========== V3FromV4 ==========================================================
//
// Purpose:		Create a new 3D vector whose components match the given 4D 
//				vector. Using this function is really only sensible when the 4D 
//				vector is really a 3D one being used for convenience in 4D math.
//
//==============================================================================
Vector3 V3FromV4(Vector4 originalVector)
{
	Vector3 newVector;
	
	//This is very bad.
	if(originalVector.w != 1)
		printf("lossy 4D vector conversion: <%f, %f, %f, %f>\n", originalVector.x, originalVector.y, originalVector.z, originalVector.w);
	
	newVector.x = originalVector.x;
	newVector.y = originalVector.y;
	newVector.z = originalVector.z;
	
	return newVector;
}


#pragma mark -

//========== V3EqualPoints() ===================================================
//
// Purpose:		Returns YES if point1 and point2 have the same coordinates..
//
//==============================================================================
bool V3EqualPoints(Point3 point1, Point3 point2)
{
	if(		point1.x == point2.x
	   &&	point1.y == point2.y
	   &&	point1.z == point2.z )
		return true;
	else
		return false;
		
}//end V3EqualPoints


//========== V3PointsWithinTolerance() =========================================
//
// Purpose:		Returns YES if point1 and point2 are sufficiently close to equal 
//				that we can call them equal. 
//
// Notes:		Floating-point numbers often suffer weird rounding errors which 
//				make them ill-suited for == comparison. 
//
//==============================================================================
bool V3PointsWithinTolerance(Point3 point1, Point3 point2)
{
	if(		fabs(point1.x - point2.x) <= SMALL_NUMBER
	   &&	fabs(point1.y - point2.y) <= SMALL_NUMBER
	   &&	fabs(point1.z - point2.z) <= SMALL_NUMBER )
		return true;
	else
		return false;
	
}//end V3PointsWithinTolerance


//========== V3SquaredLength ===================================================
//
// Purpose:		returns squared length of input vector
//
//==============================================================================
float V3SquaredLength(Vector3 a) 
{
	return (	(a.x * a.x)
			+	(a.y * a.y)
			+	(a.z * a.z) );
	
}//end V3SquaredLength


//========== V3Length ==========================================================
//
// Purpose:		returns length of input vector
//
//==============================================================================
float V3Length(Vector3 a) 
{
	return sqrt(V3SquaredLength(a));
	
}//end V3Length


//========== V3Negate ==========================================================
//
// Purpose:		negates the input vector and returns it
//
//==============================================================================
Vector3 V3Negate(Vector3 v) 
{
	v.x = - v.x;
	v.y = - v.y;
	v.z = - v.z;
	
	return(v);
	
}//end V3Negate


//========== V3Normalize =======================================================
//
// Purpose:		normalizes the input vector and returns it
//
//==============================================================================
Vector3 V3Normalize(Vector3 v) 
{
	float len = V3Length(v);
	
	if (len != 0.0)
	{
		v.x /= len;
		v.y /= len;
		v.z /= len;
	}
	
	return(v);
	
}//end V3Normalize


//========== V3Scale ===========================================================
//
// Purpose:		scales the input vector to the new length and returns it
//
//==============================================================================
Vector3 V3Scale(Vector3 v, float newlen) 
{
	float len = V3Length(v);
	
	if (len != 0.0)
	{
		v.x *= newlen / len;
		v.y *= newlen / len;
		v.z *= newlen / len;
	}
	
	return(v);
	
}//end V3Scale


//========== V3Add =============================================================
//
// Purpose:		return vector sum c = a + b
//
//==============================================================================
Vector3 V3Add(Vector3 a, Vector3 b)
{
	Vector3 result;

	result.x = a.x + b.x;
	result.y = a.y + b.y;
	result.z = a.z + b.z;
	
	return result;
	
}//end V3Add


//========== V3Sub =============================================================
//
// Purpose:		return vector difference c = a-b
//
//==============================================================================
Vector3 V3Sub(Vector3 a, Vector3 b)
{
	Vector3 result;

	result.x = a.x - b.x;
	result.y = a.y - b.y;
	result.z = a.z - b.z;
	
	return result;
	
}//end V3Sub


//========== V3Dot =============================================================
//
// Purpose:		return the dot product of vectors a and b
//
//==============================================================================
float V3Dot(Vector3 a, Vector3 b) 
{
	return ((a.x * b.x) + (a.y * b.y) + (a.z * b.z));
	
}//end V3Dot


//========== V3Lerp ============================================================
//
// Purpose:		linearly interpolate between vectors by an amount alpha and 
//				return the resulting vector. 
//
//				When alpha=0, result=lo.  When alpha=1, result=hi.
//
//==============================================================================
Vector3 V3Lerp(Vector3 lo, Vector3 hi, float alpha) 
{
	Vector3 result;

	result.x = LERP(alpha, lo.x, hi.x);
	result.y = LERP(alpha, lo.y, hi.y);
	result.z = LERP(alpha, lo.z, hi.z);
	
	return(result);
	
}//end V3Lerp


//========== V3Combine =========================================================
//
// Purpose:		make a linear combination of two vectors and return the result.
//
//				result = (a * ascl) + (b * bscl)
//
//==============================================================================
Vector3 V3Combine (Vector3 a, Vector3 b, float ascl, float bscl) 
{
	Vector3 result;
	
	result.x = (ascl * a.x) + (bscl * b.x);
	result.y = (ascl * a.y) + (bscl * b.y);
	result.z = (ascl * a.z) + (bscl * b.z);
	
	return(result);
	
}//end V3Combine


//========== V3Mul =============================================================
//
// Purpose:		Multiply two vectors together component-wise and return the 
//				result.
//
//==============================================================================
Vector3 V3Mul(Vector3 a, Vector3 b) 
{
	Vector3 result;
	
	result.x = a.x * b.x;
	result.y = a.y * b.y;
	result.z = a.z * b.z;
	
	return(result);
	
}//end V3Mul


//========== V3DistanceBetween2Points ==========================================
//
// Purpose:		return the distance between two points
//
//==============================================================================
float V3DistanceBetween2Points(Point3 a, Point3 b)
{
	float dx = a.x - b.x;
	float dy = a.y - b.y;
	float dz = a.z - b.z;
	
	float distance	= sqrt( (dx*dx) + (dy*dy) + (dz*dz) );
	
	return distance;
	
}//end V3DistanceBetween2Points


//========== V3Cross ===========================================================
//
// Purpose:		return the cross product c = a x b
//
//==============================================================================
Vector3 V3Cross(Vector3 a, Vector3 b)
{
	Vector3 c;

	c.x = (a.y * b.z) - (a.z * b.y);
	c.y = (a.z * b.x) - (a.x * b.z);
	c.z = (a.x * b.y) - (a.y * b.x);
	
	return(c);
	
}//end V3Cross


//========== V3Midpoint ========================================================
//
// Purpose:		Returns the midpoint of the line segment between point1 and 
//				point2.
//
//==============================================================================
Point3 V3Midpoint(Point3 point1, Point3 point2)
{
	Point3 midpoint;
	
	midpoint.x = (point1.x + point2.x) / 2;
	midpoint.y = (point1.y + point2.y) / 2;
	midpoint.z = (point1.z + point2.z) / 2;
	
	return midpoint;
	
}//end V3Midpoint


//========== V3BoundsFromPoints ================================================
//
// Purpose:		Sorts the points into their minimum and maximum.
//
//==============================================================================
Box3 V3BoundsFromPoints(Point3 point1, Point3 point2)
{
	Box3 bounds;

	bounds.min.x = MIN(point1.x, point2.x);
	bounds.min.y = MIN(point1.y, point2.y);
	bounds.min.z = MIN(point1.z, point2.z);
	
	bounds.max.x = MAX(point1.x, point2.x);
	bounds.max.y = MAX(point1.y, point2.y);
	bounds.max.z = MAX(point1.z, point2.z);
	
	return bounds;
	
}//end V3BoundsFromPoints


//========== V3EqualBoxes ======================================================
//
// Purpose:		Returns 1 (YES) if the two boxes are equal; 0 otherwise.
//
//==============================================================================
int V3EqualBoxes(Box3 box1, Box3 box2)
{
	return (	box1.min.x == box2.min.x
			&&	box1.min.y == box2.min.y
			&&	box1.min.z == box2.min.z
				
			&&	box1.max.x == box2.max.x
			&&	box1.max.y == box2.max.y
			&&	box1.max.z == box2.max.z  );
			
}//end V3EqualBoxes


//========== V3UnionBox ========================================================
//
// Purpose:		Returns the smallest box that completely encloses both aBox and 
//				bBox. 
//
// Notes:		If you pass something stupid in as the parameter, you will get 
//				an appropriately stupid answer. 
//
//==============================================================================
Box3 V3UnionBox(Box3 aBox, Box3 bBox)
{
	Box3	bounds				= InvalidBox;
	
	bounds.min.x = MIN(aBox.min.x, bBox.min.x);
	bounds.min.y = MIN(aBox.min.y, bBox.min.y);
	bounds.min.z = MIN(aBox.min.z, bBox.min.z);
	
	bounds.max.x = MAX(aBox.max.x, bBox.max.x);
	bounds.max.y = MAX(aBox.max.y, bBox.max.y);
	bounds.max.z = MAX(aBox.max.z, bBox.max.z);
	
	return bounds;

}//end V3UnionBox


//========== V3IsolateGreatestComponent ========================================
//
// Purpose:		Leaves unchanged the component of vector which has the greatest 
//				absolute value, but zeroes the other components. 
//				Example: <4, -7, 1> -> <0, -7, 0>.
//				This is useful for figuring out the direction of input.
//
//==============================================================================
Vector3 V3IsolateGreatestComponent(Vector3 vector)
{
	if(fabs(vector.x) > fabs(vector.y) )
	{
		vector.y = 0;
		
		if(fabs(vector.x) > fabs(vector.z) )
			vector.z = 0;
		else
			vector.x = 0;
	}
	else
	{
		vector.x = 0;
		
		if(fabs(vector.y) > fabs(vector.z) )
			vector.z = 0;
		else
			vector.y = 0;
	}
	
	return vector;
	
}//end V3IsolateGreatestComponent


//========== V3MulPointByMatrix ================================================
//
// Purpose:		multiply a point by a matrix and return the transformed point
//
//==============================================================================
Point3 V3MulPointByMatrix(Point3 pin, Matrix3 m)
{
	Point3 pout = ZeroPoint3;
	
	pout.x =	(pin.x * m.element[0][0])
			 +	(pin.y * m.element[1][0])
			 +	(pin.z * m.element[2][0]);
			 
	pout.y =	(pin.x * m.element[0][1])
			 +	(pin.y * m.element[1][1])
			 +	(pin.z * m.element[2][1]);
			 
	pout.z =	(pin.x * m.element[0][2])
			 +	(pin.y * m.element[1][2])
			 +	(pin.z * m.element[2][2]);
		
	return pout;
	
}//end V3MulPointByMatrix


//========== V3MulPointByProjMatrix ============================================
//
// Purpose:		multiply a point by a projective matrix and return the 
//				transformed point 
//
//==============================================================================
Point3 V3MulPointByProjMatrix(Point3 pin, Matrix4 m)
{
	Point3 pout = ZeroPoint3;
	float	w	= 0.0;
	
	pout.x =	(pin.x * m.element[0][0])
			 +	(pin.y * m.element[1][0])
			 + 	(pin.z * m.element[2][0])
			 +	m.element[3][0];
			 
	pout.y =	(pin.x * m.element[0][1])
			 +	(pin.y * m.element[1][1])
			 + 	(pin.z * m.element[2][1])
			 +	m.element[3][1];
			 
	pout.z =	(pin.x * m.element[0][2])
			 +	(pin.y * m.element[1][2])
			 + 	(pin.z * m.element[2][2])
			 +	m.element[3][2];
			 
	w =			(pin.x * m.element[0][3])
			 +	(pin.y * m.element[1][3])
			 +	(pin.z * m.element[2][3])
			 +	m.element[3][3];
			 
	if (w != 0.0)
	{
		pout.x /= w;
		pout.y /= w;
		pout.z /= w;
	}
	
	return(pout);
	
}//end V3MulPointByProjMatrix


//========== V3MatMul ==========================================================
//
// Purpose:		multiply together matrices c = ab
//
// Notes:		c must not point to either of the input matrices
//
//==============================================================================
Matrix4 *V3MatMul(Matrix4 *a, Matrix4 *b, Matrix4 *c)
{
	int i, j, k;
	for (i=0; i<4; i++) {
		for (j=0; j<4; j++) {
			c->element[i][j] = 0;
			for (k=0; k<4; k++) c->element[i][j] += 
				a->element[i][k] * b->element[k][j];
		}
	}
	return(c);
}


//========== V3Print ===========================================================
//
// Purpose:		Prints the given 3D point.
//
//==============================================================================
void V3Print(Point3 point)
{
	printf("(%12.6f, %12.6f, %12.6f)\n", point.x, point.y, point.z);
	
}//end V3Print


/*
 * float = det3x3(  a1, a2, a3, b1, b2, b3, c1, c2, c3 )
 * 
 * calculate the determinant of a 3x3 matrix
 * in the form
 *
 *     | a1,  b1,  c1 |
 *     | a2,  b2,  c2 |
 *     | a3,  b3,  c3 |
 */

float det3x3( a1, a2, a3, b1, b2, b3, c1, c2, c3 )
float a1, a2, a3, b1, b2, b3, c1, c2, c3;
{
    float ans;
	
    ans = a1 * det2x2( b2, b3, c2, c3 )
        - b1 * det2x2( a2, a3, c2, c3 )
        + c1 * det2x2( a2, a3, b2, b3 );
    return ans;
}

#pragma mark -
#pragma mark 4-D LIBRARY
#pragma mark -

//========== V4Make ============================================================
//
// Purpose:		Makes a new 4-dimensional vector.
//
//==============================================================================
Vector4 V4Make(float x, float y, float z, float w)
{
	Vector4 v;
	
	v.x = x;
	v.y = y;
	v.z = z;
	v.w = w;
	
	return(v);
	
}//end V4Make


//========== V3FromV4 ==========================================================
//
// Purpose:		Create a new 4D vector whose components match the given 3D 
//				vector, with a 1 in the 4th dimension.
//
//==============================================================================
Vector4 V4FromV3(Vector3 originalVector)
{
	Vector4 newVector;
	
	newVector.x = originalVector.x;
	newVector.y = originalVector.y;
	newVector.z = originalVector.z;
	newVector.w = 1;
	
	return newVector;
	
}//end V4FromV3


//========== V4MulPointByMatrix() ==============================================
//
// Purpose:		multiply a hom. point by a matrix and return the transformed 
//				point
//
// Source:		Graphic Gems II, Spencer W. Thomas
//
//==============================================================================
Vector4 V4MulPointByMatrix(Vector4 pin, Matrix4 m)
{
	Vector4 pout;

	pout.x	=	(pin.x * m.element[0][0])
			 +	(pin.y * m.element[1][0])
			 +	(pin.z * m.element[2][0])
			 +	(pin.w * m.element[3][0]);
			 
	pout.y	=	(pin.x * m.element[0][1])
			 +	(pin.y * m.element[1][1])
			 +	(pin.z * m.element[2][1])
			 +	(pin.w * m.element[3][1]);
	
	pout.z	=	(pin.x * m.element[0][2])
			 +	(pin.y * m.element[1][2])
			 +	(pin.z * m.element[2][2])
			 +	(pin.w * m.element[3][2]);
		
	pout.w	=	(pin.x * m.element[0][3])
			 +	(pin.y * m.element[1][3])
			 +	(pin.z * m.element[2][3])
			 +	(pin.w * m.element[3][3]);
		
	return (pout);
	
}//end V4MulPointByMatrix


#pragma mark -

//========== Matrix4CreateFromGLMatrix4() ======================================
//
// Purpose:		Returns a two-dimensional (row matrix) representation of the 
//				given OpenGL transformation matrix.
//
//																  +-       -+
//				+-                             -+        +-     -+| a d g 0 |
//				|a d g 0 b e h 0 c f i 0 x y z 1|  -->   |x y z 1|| b e h 0 |
//				+-                             -+        +-     -+| c f i 0 |
//													              | x y z 1 |
//																  +-       -+
//					  OpenGL Matrix Format                Matrix4 Format
//				(flat column-major of transpose)   (shown multiplied by a point)  
//
//==============================================================================
Matrix4 Matrix4CreateFromGLMatrix4(const GLfloat *glMatrix)
{
	int		row, column;
	Matrix4	newMatrix;
	
	for(row = 0; row < 4; row++)
		for(column = 0; column < 4; column++)
			newMatrix.element[row][column] = glMatrix[row * 4 + column];
	
	return newMatrix;
}


//========== Matrix4CreateTransformation() =====================================
//
// Purpose:		Given the scale, shear, rotation, translation, and perspective 
//				paramaters, create a 4x4 transformation.element matrix used to 
//				modify row-matrix points.
//
//				To reverse the procedure, pass the returned matrix to Matrix4DecomposeTransformation().
//
// Notes:		This ignores perspective, which is not supported.
//
// Source:		Allen Smith, after too much handwork.
//
//==============================================================================
Matrix4 Matrix4CreateTransformation(TransformComponents *components)
{
	Matrix4	transformation = IdentityMatrix4; //zero out the whole thing.
	float	rotation[3][3];
	
	//Create the rotation matrix.
	double sinX = sin(components->rotate.x);
	double cosX = cos(components->rotate.x);
	
	double sinY = sin(components->rotate.y);
	double cosY = cos(components->rotate.y);
	
	double sinZ = sin(components->rotate.z);
	double cosZ = cos(components->rotate.z);
	
	rotation[0][0] = cosY * cosZ;
	rotation[0][1] = cosY * sinZ;
	rotation[0][2] = -sinY;
	
	rotation[1][0] = sinX*sinY*cosZ - cosX*sinZ;
	rotation[1][1] = sinX*sinY*sinZ + cosX*cosZ;
	rotation[1][2] = sinX*cosY;
	
	rotation[2][0] = cosX*sinY*cosZ + sinX*sinZ;
	rotation[2][1] = cosX*sinY*sinZ - sinX*cosZ;
	rotation[2][2] = cosX*cosY;
	
	//Build the transformation.element matrix.
	// Seeing the transformation.element matrix in these terms helps to make sense of Matrix4DecomposeTransformation().
	transformation.element[0][0] = components->scale.x * rotation[0][0];
	transformation.element[0][1] = components->scale.x * rotation[0][1];
	transformation.element[0][2] = components->scale.x * rotation[0][2];

	transformation.element[1][0] = components->scale.y * (components->shear_XY * rotation[0][0] + rotation[1][0]);
	transformation.element[1][1] = components->scale.y * (components->shear_XY * rotation[0][1] + rotation[1][1]);
	transformation.element[1][2] = components->scale.y * (components->shear_XY * rotation[0][2] + rotation[1][2]);

	transformation.element[2][0] = components->scale.z * (components->shear_XZ * rotation[0][0] + components->shear_YZ * rotation[1][0] + rotation[2][0]);
	transformation.element[2][1] = components->scale.z * (components->shear_XZ * rotation[0][1] + components->shear_YZ * rotation[1][1] + rotation[2][1]);
	transformation.element[2][2] = components->scale.z * (components->shear_XZ * rotation[0][2] + components->shear_YZ * rotation[1][2] + rotation[2][2]);
	
	//translation is so nice and easy.
	transformation.element[3][0] = components->translate.x;
	transformation.element[3][1] = components->translate.y;
	transformation.element[3][2] = components->translate.z;
	
	//And lastly the corner.
	transformation.element[3][3] = 1;
	
	return transformation;
	
}//end Matrix4CreateTransformation


//========== Matrix4DecomposeTransformation() ==================================
//
// Purpose:		Decompose a non-degenerate 4x4 transformation.element matrix 
//				into the sequence of transformations that produced it.
//
//		[Sx][Sy][Sz][Shearx/y][Sx/z][Sz/y][Rx][Ry][Rz][Tx][Ty][Tz][P(x,y,z,w)]
//
//				The coefficient of each transformation.element is returned in 
//				the corresponding element of the vector tran.
//
// Returns:		1 upon success, 0 if the matrix is singular.
//
// Source:		Graphic Gems II, Spencer W. Thomas
//
//==============================================================================
int Matrix4DecomposeTransformation( Matrix4 originalMatrix,
									TransformComponents *decomposed )
{
	int			counter		= 0;
	int			j			= 0;
	Matrix4		localMatrix	= originalMatrix;
	Matrix4		pmat, invpmat, tinvpmat;
	Vector4		prhs, psol;
	Point3		row[3];
	
 	// Normalize the matrix.
 	if ( localMatrix.element[3][3] == 0 )
 		return 0;
	
 	for ( counter=0; counter<4;counter++ )
 		for ( j=0; j<4; j++ )
 			localMatrix.element[counter][j] /= localMatrix.element[3][3];
	
 	//pmat is used to solve for perspective, but it also provides
	//an easy way to test for singularity of the upper 3x3 component.
 	pmat = localMatrix;
 	for ( counter = 0; counter < 3; counter++ )
 		pmat.element[counter][3] = 0;
 	pmat.element[3][3] = 1;
	
 	if ( Matrix4x4Determinant(&pmat) == 0.0 )
 		return 0;
	
 	// First, isolate perspective.  This is the messiest.
	// Perspective is not used by Bricksmith.
 	if ( localMatrix.element[0][3] != 0 || localMatrix.element[1][3] != 0 ||
		 localMatrix.element[2][3] != 0 ) {
 		// prhs is the right hand side of the equation.
 		prhs.x = localMatrix.element[0][3];
 		prhs.y = localMatrix.element[1][3];
 		prhs.z = localMatrix.element[2][3];
 		prhs.w = localMatrix.element[3][3];
		
 		// Solve the equation by inverting pmat and multiplying
		// prhs by the inverse.  (This is the easiest way, not
		// necessarily the best.)
		// inverse function (and Matrix4x4Determinant, above) from the Matrix
		// Inversion gem in the first volume.
 		invpmat		= Matrix4Invert(pmat);
		tinvpmat	= Matrix4Transpose(invpmat);
 		psol		= V4MulPointByMatrix(prhs, tinvpmat);
		
 		// Stuff the answer away.
 		decomposed->perspective.x = psol.x;
 		decomposed->perspective.y = psol.y;
 		decomposed->perspective.z = psol.z;
 		decomposed->perspective.w = psol.w;
 		// Clear the perspective partition.
 		localMatrix.element[0][3] = 0;
		localMatrix.element[1][3] = 0;
		localMatrix.element[2][3] = 0;
 		localMatrix.element[3][3] = 1;
 	}
	//No perspective
	else{
 		decomposed->perspective.x = 0;
		decomposed->perspective.y = 0;
		decomposed->perspective.z = 0;
		decomposed->perspective.w = 0;
	}
	
 	// Next take care of translation (easy).
	decomposed->translate.x = localMatrix.element[3][0];
	decomposed->translate.y = localMatrix.element[3][1];
	decomposed->translate.z = localMatrix.element[3][2];
	
	//Zero out the translation as we continue to decompose.
	for ( counter = 0; counter < 3; counter++ ) {
		localMatrix.element[3][counter] = 0;
 	}
	
 	// Now get scale and shear.
 	for ( counter=0; counter<3; counter++ ) {
 		row[counter].x = localMatrix.element[counter][0];
 		row[counter].y = localMatrix.element[counter][1];
 		row[counter].z = localMatrix.element[counter][2];
 	}
	
 	// Compute X scale factor and normalize first row.
 	decomposed->scale.x = V3Length(row[0]);
 	row[0] = V3Scale(row[0], 1.0);
	
 	// Compute XY shear factor and make 2nd row orthogonal to 1st.
 	decomposed->shear_XY = V3Dot(row[0], row[1]);
 	row[1] = V3Combine(row[1], row[0], 1.0, -decomposed->shear_XY);
	
 	// Now, compute Y scale and normalize 2nd row.
 	decomposed->scale.y = V3Length(row[1]);
 	row[1] = V3Scale(row[1], 1.0);
 	decomposed->shear_XY /= decomposed->scale.y;
	
 	// Compute XZ and YZ shears, orthogonalize 3rd row.
 	decomposed->shear_XZ = V3Dot(row[0], row[2]);
 	row[2] = V3Combine(row[2], row[0], 1.0, -decomposed->shear_XZ);
 	decomposed->shear_YZ = V3Dot(row[1], row[2]);
 	row[2] = V3Combine(row[2], row[1], 1.0, -decomposed->shear_YZ);
	
 	// Next, get Z scale and normalize 3rd row.
 	decomposed->scale.z = V3Length(row[2]);
 	row[2] = V3Scale(row[2], 1.0);
 	decomposed->shear_XZ /= decomposed->scale.z;
 	decomposed->shear_YZ /= decomposed->scale.z;
	
 	// At this point, the matrix (in rows[]) is orthonormal.
 	// Check for a coordinate system flip.  If the determinant
 	// is -1, then negate the matrix and the scaling factors.
 	if ( V3Dot( row[0], V3Cross(row[1], row[2]) ) < 0 )
	{
		decomposed->scale.x *= -1;
		decomposed->scale.y *= -1;
		decomposed->scale.z *= -1;
		
 		for ( counter = 0; counter < 3; counter++ )
		{
 			row[counter].x *= -1;
 			row[counter].y *= -1;
 			row[counter].z *= -1;
 		}
		
	}
	
	
	// Now, extract the rotation angles.
	decomposed->rotate.y = asin(-row[0].z);
	
	//cos(Y) != 0.
	// We can just use some simple algebra on the simplest components 
	// of the rotation matrix.
 	if ( fabs(cos(decomposed->rotate.y)) > SMALL_NUMBER ) { //within a tolerance of zero.
 		decomposed->rotate.x = atan2(row[1].z, row[2].z);
 		decomposed->rotate.z = atan2(row[0].y, row[0].x);
 	}
	//cos(Y) == 0; so Y = +/- PI/2
	// this is a "singularity" that zeroes out the information we would 
	// usually use to determine X and Y.
	
	else if( decomposed->rotate.y < 0) { // -PI/2
 		decomposed->rotate.x = atan2(-row[2].y, row[1].y);
 		decomposed->rotate.z = 0;
 	}
	else if( decomposed->rotate.y > 0) { // +PI/2
 		decomposed->rotate.x = atan2(row[2].y, row[1].y);
 		decomposed->rotate.z = 0;
 	}
	
 	// All done!
 	return 1;
	
}//end Matrix4DecomposeTransformation


//========== Matrix4Rotate() ===================================================
//
// Purpose:		Rotates the given matrix by the given number of degrees around 
//				each axis, placing the rotated matrix into the Matrix specified 
//				by the result parameter. Also returns result.
//
// Note:		You may safely pass the same matrix for original and result.
//
//==============================================================================
Matrix4 Matrix4Rotate(Matrix4 original, Tuple3 degreesToRotate)
{
	TransformComponents	rotateComponents	= IdentityComponents;
	Matrix4				addedRotation		= IdentityMatrix4;
	Matrix4				newMatrix			= IdentityMatrix4;

	//Create a new matrix that causes the rotation we want.
	//  (start with identity matrix)
	rotateComponents.rotate.x = radians(degreesToRotate.x);
	rotateComponents.rotate.y = radians(degreesToRotate.y);
	rotateComponents.rotate.z = radians(degreesToRotate.z);
	addedRotation = Matrix4CreateTransformation(&rotateComponents);
	
	V3MatMul(&original, &addedRotation, &newMatrix); //rotate at rotationCenter
	
	return newMatrix;

}//end Matrix4Rotate


//========== Matrix4Translate() ================================================
//
// Purpose:		Translates the given matrix by the given displacement, placing 
//				the translated matrix into the Matrix specified by the result 
//				parameter. Also returns result.
//
// Note:		You may safely pass the same matrix for original and result.
//
//==============================================================================
Matrix4 Matrix4Translate(Matrix4 original, Vector3 displacement)
{
	Matrix4 result = IdentityMatrix4;
	
	//Copy original to result
	result = original;
	
	result.element[3][0] += displacement.x; //applied directly to 
	result.element[3][1] += displacement.y; //the matrix because 
	result.element[3][2] += displacement.z; //that's easier here.
	
	return result;
	
}//end Matrix4Translate


//========== Matrix4Transpose() ================================================
//
// Purpose:		transpose rotation portion of matrix a, return b
//
// Source:		Graphic Gems II, Spencer W. Thomas
//
//==============================================================================
Matrix4 Matrix4Transpose(Matrix4 a)
{
	Matrix4 transpose	= IdentityMatrix4;
	int		i, j;
	
	for (i=0; i<4; i++)
		for (j=0; j<4; j++)
			transpose.element[i][j] = a.element[j][i];
			
	return transpose;
	
}//end Matrix4Transpose


//========== Matrix4Invert() ===================================================
//
// Purpose:		calculate the inverse of a 4x4 matrix
//
//				 -1     
//				A  = ___1__ adjoint A
//					  det A
//
//==============================================================================
Matrix4 Matrix4Invert( Matrix4 in )
{
	Matrix4 out	= IdentityMatrix4;
    int		i, j;
    float	det	= 0.0;
	
    /* calculate the adjoint matrix */
	
    Matrix4Adjoint( &in, &out );
	
    /*  calculate the 4x4 determinant
		*  if the determinant is zero, 
		*  then the inverse matrix is not unique.
		*/
	
    det = Matrix4x4Determinant( &in );
	
    if ( fabs( det ) < SMALL_NUMBER)
	{
        printf("Non-singular matrix, no inverse!\n");
        exit(1);
    }
	
    /* scale the adjoint matrix to get the inverse */
	
    for (i=0; i<4; i++)
        for(j=0; j<4; j++)
			out.element[i][j] = out.element[i][j] / det;
	
	return out;
	
}//end Matrix4Invert


//========== Matrix4Adjoint() ==================================================
//
// Purpose:		calculate the adjoint of a 4x4 matrix
//
//				Let  a   denote the minor determinant of matrix A obtained by
//					  ij
//
//				deleting the ith row and jth column from A.
//
//								i+j
//				Let  b   = (-1)    a
//					  ij            ji
//
//				The matrix B = (b  ) is the adjoint of A
//								 ij
//
//==============================================================================
void Matrix4Adjoint( Matrix4 *in, Matrix4 *out )
{
    float a1, a2, a3, a4, b1, b2, b3, b4;
    float c1, c2, c3, c4, d1, d2, d3, d4;
	
    /* assign to individual variable names to aid  */
    /* selecting correct values  */
	
	a1 = in->element[0][0]; b1 = in->element[0][1]; 
	c1 = in->element[0][2]; d1 = in->element[0][3];
	
	a2 = in->element[1][0]; b2 = in->element[1][1]; 
	c2 = in->element[1][2]; d2 = in->element[1][3];
	
	a3 = in->element[2][0]; b3 = in->element[2][1];
	c3 = in->element[2][2]; d3 = in->element[2][3];
	
	a4 = in->element[3][0]; b4 = in->element[3][1]; 
	c4 = in->element[3][2]; d4 = in->element[3][3];
	
	
    /* row column labeling reversed since we transpose rows & columns */
	
    out->element[0][0]  =   det3x3( b2, b3, b4, c2, c3, c4, d2, d3, d4);
    out->element[1][0]  = - det3x3( a2, a3, a4, c2, c3, c4, d2, d3, d4);
    out->element[2][0]  =   det3x3( a2, a3, a4, b2, b3, b4, d2, d3, d4);
    out->element[3][0]  = - det3x3( a2, a3, a4, b2, b3, b4, c2, c3, c4);
	
    out->element[0][1]  = - det3x3( b1, b3, b4, c1, c3, c4, d1, d3, d4);
    out->element[1][1]  =   det3x3( a1, a3, a4, c1, c3, c4, d1, d3, d4);
    out->element[2][1]  = - det3x3( a1, a3, a4, b1, b3, b4, d1, d3, d4);
    out->element[3][1]  =   det3x3( a1, a3, a4, b1, b3, b4, c1, c3, c4);
	
    out->element[0][2]  =   det3x3( b1, b2, b4, c1, c2, c4, d1, d2, d4);
    out->element[1][2]  = - det3x3( a1, a2, a4, c1, c2, c4, d1, d2, d4);
    out->element[2][2]  =   det3x3( a1, a2, a4, b1, b2, b4, d1, d2, d4);
    out->element[3][2]  = - det3x3( a1, a2, a4, b1, b2, b4, c1, c2, c4);
	
    out->element[0][3]  = - det3x3( b1, b2, b3, c1, c2, c3, d1, d2, d3);
    out->element[1][3]  =   det3x3( a1, a2, a3, c1, c2, c3, d1, d2, d3);
    out->element[2][3]  = - det3x3( a1, a2, a3, b1, b2, b3, d1, d2, d3);
    out->element[3][3]  =   det3x3( a1, a2, a3, b1, b2, b3, c1, c2, c3);
}


//========== Matrix4x4Determinant() ============================================
//
// Purpose:		calculate the determinant of a 4x4 matrix.
//
// Source:		Graphic Gems II, Spencer W. Thomas
//
//==============================================================================
float Matrix4x4Determinant( Matrix4 *m )
{
    float ans;
    float a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, 			d4;
	
    /* assign to individual variable names to aid selecting */
	/*  correct elements */
	
	a1 = m->element[0][0]; b1 = m->element[0][1]; 
	c1 = m->element[0][2]; d1 = m->element[0][3];
	
	a2 = m->element[1][0]; b2 = m->element[1][1]; 
	c2 = m->element[1][2]; d2 = m->element[1][3];
	
	a3 = m->element[2][0]; b3 = m->element[2][1]; 
	c3 = m->element[2][2]; d3 = m->element[2][3];
	
	a4 = m->element[3][0]; b4 = m->element[3][1]; 
	c4 = m->element[3][2]; d4 = m->element[3][3];
	
    ans = a1 * det3x3( b2, b3, b4, c2, c3, c4, d2, d3, d4)
        - b1 * det3x3( a2, a3, a4, c2, c3, c4, d2, d3, d4)
        + c1 * det3x3( a2, a3, a4, b2, b3, b4, d2, d3, d4)
        - d1 * det3x3( a2, a3, a4, b2, b3, b4, c2, c3, c4);
    return ans;
}


//========== Matrix4Print() ====================================================
//
// Purpose:		Prints the elements of matrix.
//
//==============================================================================
void Matrix4Print(Matrix4 *matrix)
{
	int counter;
	
	for(counter = 0; counter < 4; counter++)
	{
		printf("[%12.6f %12.6f %12.6f %12.6f]\n",	
								matrix->element[counter][0],
								matrix->element[counter][1],
								matrix->element[counter][2],
								matrix->element[counter][3] );
	}
	printf("\n");
}//end Matrix4Print