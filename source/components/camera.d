/**
 * Defines the Camera class, which manages a view and projection matrix.
 */
module components.camera;
import core, components, graphics, utility;

import gl3n.linalg;
import std.conv;

/**
 * Camera manages a view and projection matrix.
 */
final class Camera : IComponent, IDirtyable
{
private:
    float _prevFov, _prevNear, _prevFar, _prevWidth, _prevHeight;

    float _fov, _near, _far;
    vec2 _projectionConstants; // For rebuilding linear Z in shaders
    mat4 _prevLocalMatrix;
    mat4 _viewMatrix;
    mat4 _inverseViewMatrix;
    mat4 _perspectiveMatrix;
    mat4 _inversePerspectiveMatrix;
    mat4 _orthogonalMatrix;
    mat4 _inverseOrthogonalMatrix;

public:
    override void update() { }
    override void shutdown() { }

    /// TODO
    mixin( ThisDirtyGetter!( _viewMatrix, updateViewMatrix ) );
    /// TODO
    mixin( ThisDirtyGetter!( _inverseViewMatrix, updateViewMatrix ) );
    /// TODO
    mixin( Property!( _fov, AccessModifier.Public ) );
    /// TODO
    mixin( Property!( _near, AccessModifier.Public ) );
    /// TODO
    mixin( Property!( _far, AccessModifier.Public ) );
    
    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final vec2 projectionConstants()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _projectionConstants;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4 perspectiveMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _perspectiveMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4 inversePerspectiveMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _inversePerspectiveMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4 orthogonalMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _orthogonalMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4 inverseOrthogonalMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _inverseOrthogonalMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final void updateViewMatrix()
    {
        //Assuming pitch & yaw are in radians
        float cosPitch = cos( owner.transform.rotation.pitch );
        float sinPitch = sin( owner.transform.rotation.pitch );
        float cosYaw = cos( owner.transform.rotation.yaw );
        float sinYaw = sin( owner.transform.rotation.yaw );

        vec3 xaxis = vec3( cosYaw, 0.0f, -sinYaw );
        vec3 yaxis = vec3( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
        vec3 zaxis = vec3( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

        _viewMatrix.clear( 0.0f );
        _viewMatrix[ 0 ] = xaxis.vector ~ -( xaxis * owner.transform.position );
        _viewMatrix[ 1 ] = yaxis.vector ~ -( yaxis * owner.transform.position );
        _viewMatrix[ 2 ] = zaxis.vector ~ -( zaxis * owner.transform.position );
        _viewMatrix[ 3 ] = [ 0, 0, 0, 1 ];
        
        _inverseViewMatrix = _viewMatrix.inverse();
    }

    /**
     * Creates a view matrix looking at a position.
     *
     * Params:
     *  targetPos = The position for the camera to look at.
     *  cameraPos = The camera's position.
     *  worldUp = The up direction in the world.
     *
     * Returns: 
     * A right handed view matrix for the given params.
     */
    final static shared(mat4) lookAt( vec3 targetPos, vec3 cameraPos, vec3 worldUp = vec3(0,1,0) )
    {
        vec3 zaxis = ( cameraPos - targetPos );
        zaxis.normalize;
        vec3 xaxis = cross( worldUp, zaxis );
        xaxis.normalize;
        vec3 yaxis = cross( zaxis, xaxis );

        mat4 result = mat4.identity;

        result[0][0] = xaxis.x;
        result[1][0] = xaxis.y;
        result[2][0] = xaxis.z;
        result[3][0] = -dot( xaxis, cameraPos );
        result[0][1] = yaxis.x;
        result[1][1] = yaxis.y;
        result[2][1] = yaxis.z;
        result[3][1] = -dot( yaxis, cameraPos );
        result[0][2] = zaxis.x;
        result[1][2] = zaxis.y;
        result[2][2] = zaxis.z;
        result[3][2] = -dot( zaxis, cameraPos );

        return result.transposed;
    }



    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final override @property bool isDirty()
    {
        auto result = owner.transform.matrix != _prevLocalMatrix;

        _prevLocalMatrix = owner.transform.matrix;

        return result;
    }

private:

    /*
     * Returns whether any of the variables necessary for the projection matrices have changed
     */
    final bool projectionDirty()
    {
        return _fov != _prevFov ||
            _far != _prevFar ||
            _near != _prevNear ||
            cast(float)Graphics.width != _prevWidth ||
            cast(float)Graphics.height != _prevHeight;
    }

    /*
     * Updates the projection constants, perspective matrix, and inverse perspective matrix
     */
    final void updatePerspective()
    {
        _projectionConstants = vec2( ( -_far * _near ) / ( _far - _near ), _far / ( _far - _near ) );
        _perspectiveMatrix = mat4.perspective( cast(float)Graphics.width, cast(float)Graphics.height, _fov, _near, _far );
        _inversePerspectiveMatrix = _perspectiveMatrix.inverse();
    }

    /*
     * Updates the orthogonal matrix, and inverse orthogonal matrix
     */
    final void updateOrthogonal()
    {
        _orthogonalMatrix = mat4.identity;

        _orthogonalMatrix[0][0] = 2.0f / Graphics.width; 
        _orthogonalMatrix[1][1] = 2.0f / Graphics.height;
        _orthogonalMatrix[2][2] = -2.0f / (far - near);
        _orthogonalMatrix[3][3] = 1.0f;

        _inverseOrthogonalMatrix = _orthogonalMatrix.inverse();
    }

    /*
     * Sets the _prev values for the projection variables
     */
    final void updateProjectionDirty()
    {
        _prevFov = _fov;
        _prevFar = _far;
        _prevNear = _near;
        _prevWidth = cast(float)Graphics.width;
        _prevHeight = cast(float)Graphics.height;
    }
}

static this()
{
    import yaml;
    IComponent.initializers[ "Camera" ] = ( Node yml, GameObject obj )
    {
        obj.camera = new Camera;
        obj.camera.owner = obj;

        //float fromYaml;
        if( !yml.tryFind( "FOV", obj.camera._fov ) )
            logFatal( obj.name, " is missing FOV value for its camera. ");
        if( !yml.tryFind( "Near", obj.camera._near ) )
            logFatal( obj.name, " is missing near plane value for its camera. ");
        if( !yml.tryFind( "Far", obj.camera._far ) )
            logFatal( obj.name, " is missing Far plane value for its camera. ");

        obj.camera.updatePerspective();
        obj.camera.updateOrthogonal();
        obj.camera.updateProjectionDirty();

        return obj.camera;
    };
}