package cornerContourWebGLTest;

import cornerContour.io.Float32Array;
import cornerContour.io.ColorTriangles2D;
import cornerContour.io.IteratorRange;
// contour code
import cornerContour.Sketcher;
import cornerContour.Pen2D;
import cornerContour.StyleSketch;
import cornerContour.StyleEndLine;
// SVG path parser
import justPath.*;
import justPath.transform.ScaleContext;
import justPath.transform.ScaleTranslateContext;
import justPath.transform.TranslationContext;

// webgl gl stuff
import cornerContourWebGLTest.ShaderColor2D;
import cornerContourWebGLTest.HelpGL;
import cornerContourWebGLTest.BufferGL;
import cornerContourWebGLTest.GL;

// html stuff
import cornerContourWebGLTest.Sheet;
import cornerContourWebGLTest.DivertTrace;

import htmlHelper.tools.AnimateTimer;

// js webgl 
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Program;
import js.html.webgl.Texture;

function main(){
    new CornerContourWebGL2();
}

class CornerContourWebGL2 {
    // cornerContour specific code
    var sketcher:       Sketcher;
    var pen2D:          Pen2D;
    // WebGL/Html specific code
    public var gl:               RenderingContext;
        // general inputs
    final vertexPosition         = 'vertexPosition';
    final vertexColor            = 'vertexColor';
    // general
    public var width:            Int;
    public var height:           Int;
    public var mainSheet:        Sheet;
    // Color
    public var programColor:     Program;
    public var bufColor:         Buffer;
    var divertTrace:             DivertTrace;
    var arrData:                 ColorTriangles2D;
    var len:                     Int;
    var totalTriangles:          Int;
    var bufferLength:            Int;
    public function new(){
        divertTrace = new DivertTrace();
        trace('Contour Test');
        width = 1024;
        height = 768;
        creategl();
        // use Pen to draw to Array
        drawContours();
        rearrageDrawData();
        setupProgramColor();
        setupInputColor();
        // call when changing program mode
        setProgramMode();
        setAnimate();
    }
    inline
    function creategl( ){
        mainSheet = new Sheet();
        mainSheet.create( width, height, true );
        gl = mainSheet.gl;
    }
    
    public
    function rearrageDrawData(){
        trace( 'rearrangeDrawData' );
        var pen = pen2D;
        var data = pen.arr;
        // triangle length
        totalTriangles = Std.int( data.size/7 );
        bufferLength = totalTriangles*3;
         // xy rgba = 6
        len = Std.int( totalTriangles * 6 * 3 );
        var j = 0;
        arrData = new ColorTriangles2D( len );
        for( i in 0...totalTriangles ){
            pen.pos = i;
            // populate arrData.
            arrData.pos    = i;
            arrData.argb   = Std.int( data.color );
            arrData.ax     = gx( data.ax );
            arrData.ay     = gy( data.ay );
            arrData.bx     = gx( data.bx );
            arrData.by     = gy( data.by );
            arrData.cx     = gx( data.cx );
            arrData.cy     = gy( data.cy );
        }
    }
    public
    function drawContours(){
        trace( 'drawContours' );
        pen2D = new Pen2D( 0xFF0000FF );
        pen2D.currentColor = 0xff0000FF;
        // TURTLE CODE HERE
        enneagram( 150, 510, 2 );
        heptagram( 370, 240, 5 );
        pentagram( 50, 140, 10 );
    }
    public
    function enneagram( x: Float, y: Float, size: Float ){
        sketcher = new Sketcher( pen2D, StyleSketch.Fine, StyleEndLine.no );
        var sides = 9;
        var angle: Float = Sketcher.sidetaGram( 9 );
        var s = Std.int( pen2D.pos );
        sketcher.setPosition( x, y )
                .penSize( size )
                .yellow()
                .penColorChange( -0.09, 0.01, 0.09 )
                .west()
                .fillOff()
                .beginRepeat( sides ) // to make corners nice, do extra turn.
                .archBezier( 300, 150, -10 )
                .right( angle )
                .penColorChange( -0.09, 0.01, 0.09 )
                .endRepeat()
                .blue();
        allRange.push( s...Std.int( pen2D.pos ) );
    }
    public
    function heptagram( x: Float, y: Float, size: Float ){
        var sketcher = new Sketcher( pen2D, StyleSketch.Fine, StyleEndLine.no );
        var sides = 7;
        var angle: Float = Sketcher.sidetaGram( 7 );
        var s = Std.int( pen2D.pos );
        sketcher.setPosition( x, y )
                .penSize( size )
                .plum()
                .west()
                .fillOff()
                .beginRepeat( sides+1 ) // to make corners nice, do extra turn.
                .archBezier( 300, 150, 30 )
                .right( angle )
                .penColorChange( 0.09, 0.1, -0.09 )
                .endRepeat()
                .blue();
        allRange.push( s...Std.int( pen2D.pos ) );
    }
    public
    function pentagram( x: Float, y: Float, size ){
        var sketcher = new Sketcher( pen2D, StyleSketch.Fine, StyleEndLine.no );
        var sides = 5;
        var angle: Float = Sketcher.sidetaGram( 6 );
        var s = Std.int( pen2D.pos );
        sketcher.setPosition( x, y )
                .penSize( size )
                .blue()
                .west()
                .fillOff()
                .beginRepeat( sides+1 )
                .archBezier( 300, 150, 30 )
                .right( 144 ) // sugar my sedetaGram does not work for small values
                .penColorChange( 0.09, 0.1, -0.09 )
                .endRepeat()
                .blue();
        var range = s...Std.int( pen2D.pos );
        allRange.push( range );
    }
    function setProgramMode() {
        gl.useProgram( programColor );
        updateBufferXY_RGBA( gl, programColor, vertexPosition, vertexColor );
        gl.bindBuffer( GL.ARRAY_BUFFER, bufColor );
    }
    inline
    function setupProgramColor(){
        programColor = programSetup( gl, vertexString, fragmentString );
    }
    var drawCount = 0;
    var count = 0;
    var speed = 0.055;
    var toggle = true;
    var allRange = new Array<IteratorRange>();
    var theta = 0.;
    inline
    function render(){
        clearAll( gl, width, height, 0., 0., 0., 1. );
        var triSize = 6*3;
        var totalTriangles = Std.int( pen2D.arr.size/7 );
        ( toggle )? count++: count--;
        var starting = 0;
        var ending = 0;
        var l = allRange.length;
        var extra = 0;
        var allEnded = 0;
        var allStarted = 0;
        for( i in 0...l ){
            var range = allRange[i];
            var addOn: Float = count*(range.max - range.start)/100;
            // used so the roughly finish at same time.
            var ending = range.start + Math.round( addOn*speed )*triSize;
            if( ending > range.max - 1 ) {
                ending = range.max - 1;
                allEnded++;
            }
            if( ending < range.start ){
                ending = range.start;
                allStarted++;
            }
            switch( i ){
                case 0:
                    arrData.rotateRange( range, gx(150 + 70), gy(510-70), Math.PI/100 );
                case 1:
                    arrData.translateRange( range, 0.005 * Math.sin( theta*theta - Math.PI/4 ), 0.005 * Math.sin( theta - Math.PI/8 ) );
                case 2:
                    arrData.alphaRange( range, 0.5 + 0.3*Math.sin( theta - Math.PI/2 ) );
            }
            drawData( programColor, arrData.getFloat32Array(), range.start, ending, triSize );
            if( allEnded == 3 ) toggle = false;
            if( allStarted == 3 ) toggle = true;
        }
        theta+= 0.1;
    }
    inline
    function setAnimate(){
        AnimateTimer.create();
        AnimateTimer.onFrame = function( v: Int ) render();
    }
    inline
    function setupInputColor(){
        gl.bindBuffer( GL.ARRAY_BUFFER, null );
        gl.useProgram( programColor );
        var arr = arrData.getFloat32Array();
        bufColor = interleaveXY_RGBA( gl
                                    , programColor
                                    , arr
                                    , vertexPosition, vertexColor, true );
        gl.bindBuffer( GL.ARRAY_BUFFER, bufColor );
    }

    public
    function drawData( program: Program, dataGL: Float32Array, start: Int, end: Int, triSize: Int ){
        var partData = dataGL.subarray( start*triSize, end*triSize );
        gl.bufferSubData( GL.ARRAY_BUFFER, 0, cast partData );
        gl.useProgram( program );
        gl.drawArrays( GL.TRIANGLES, 0, Std.int( ( end - start ) * 3));
    }
    
    public inline
    function gx( v: Float ): Float {
        return -( 1 - 2*v/width );
    }
    public inline
    function gy( v: Float ): Float {
        return ( 1 - 2*v/height );
    }
}