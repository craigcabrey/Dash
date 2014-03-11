module components.lights;
import core, components, graphics;
import utility;

import gl3n.linalg;

class Light : IComponent
{
private:
	vec3 _color;

public:
	mixin( Property!( _color, AccessModifier.Public ) );

	this( vec3 color )
	{
		this.color = color;
	}
	
	override void update() { }
	override void shutdown() { }
}

class AmbientLight : Light 
{ 
	this( vec3 color )
	{
		super( color );
	}
}

/* 
 * Directional Light data
 */
class DirectionalLight : Light
{
private:
	vec3 _direction;

public:
	mixin( Property!( _direction, AccessModifier.Public ) );

	this( vec3 color, vec3 direction )
	{
		this.direction = direction;
		super( color );
	}
}

/*
 * Point Light data
 */
class PointLight : Light
{
private:
	float _radius;
	mat4 _matrix;

public:
	/*
	 * The area that lighting will be calculated for 
	 */
	mixin( Property!( _radius, AccessModifier.Public ) );

	this( vec3 color, float radius )
	{
		this.radius = radius;
		super( color );
	}

	public mat4 getTransform()
	{
		_matrix = mat4.identity;
		// Scale
		_matrix.scale( radius, radius, radius );
		// Translate
		vec3 position = owner.transform.worldPosition;
		_matrix.translate( position.x, position.y, position.z );
		return _matrix;
	}

}

/*
 * SpotLight Stub
 */
class SpotLight : Light
{
public:
	this( vec3 color )
	{
		super( color );
	}
}

static this()
{
	import yaml;
	IComponent.initializers[ "Light" ] = ( Node yml, GameObject obj )
	{

		obj.light = yml.get!Light;
		obj.light.owner = obj;

		return obj.light;
	};
}