module math.quaternion;
import core.global;
import math.matrix;

import std.signals, std.conv;
import std.math;

class Quaternion
{
public:
	this()
	{
		this( 0.0f, 0.0f, 0.0f, 1.0f );
	}

	this( const float x, const float y, const float z, const float angle )
	{
		immutable float fHalfAngle = angle / 2.0f;
		immutable float fSin = sin( fHalfAngle );

		_w = cos( fHalfAngle );
		_x = fSin * x;
		_y = fSin * y;
		_z = fSin * z;

		connect( &this.updateMatrix );
	}

	mixin Signal!( string, string );

	mixin( EmmittingProperty!( "float", "x", "public" ) );
	mixin( EmmittingProperty!( "float", "y" ) );
	mixin( EmmittingProperty!( "float", "z" ) );
	mixin( EmmittingProperty!( "float", "w" ) );

	mixin( Property!( "Matrix!4", "matrix" ) );

private:
	void updateMatrix( string name, string newVal )
	{
		matrix.matrix[ 0 ][ 0 ] = 1.0f - 2.0f * y * y - 2.0f * z * z;
		matrix.matrix[ 0 ][ 1 ] = 2.0f * x * y - 2.0f * z * w;
		matrix.matrix[ 0 ][ 2 ] = 2.0f * x * z + 2.0f * y * w;
		matrix.matrix[ 1 ][ 0 ] = 2.0f * x * y + 2.0f * z * w;
		matrix.matrix[ 1 ][ 1 ] = 1.0f - 2.0f * x * x - 2.0f * z * z;
		matrix.matrix[ 1 ][ 2 ] = 2.0f * y * z - 2.0f * x * w;
		matrix.matrix[ 2 ][ 0 ] = 2.0f * x * z - 2.0f * y * w;
		matrix.matrix[ 2 ][ 1 ] = 2.0f * y * z + 2.0f * x * w;
		matrix.matrix[ 2 ][ 2 ] = 1.0f - 2.0f * x * x - 2.0f * y * y;
	}
}
