/**
 * Visualizer
 *
 * Given an input audio stream, this visualizer dynamically draws shapes in 
 * response to the audio.
 *
 * Depends on the Minim library - you must import it into the sketch before it 
 * will run.
 *
 * See spec/visualizer.txt for more details.
 *
 * Notes, todo, thoughts, modifications from the spec:
 * - We have 6 shape parameters:
 *		* Position 
 *		* Angle 
 *		* Speed 
 *		* Size 
 *		* Type 
 *		* Color 
 * - However, we really only get two parameters from the music:
 *		1. On beat (boolean)
 *		2. Amplitude for this frequency band (FFT) (float, 2048 of them)
 *		(We *could* do separate FFT on the left and right channels - not sure if 
 *		  that would be interesting though.)
 *
 * - So, if we want to morph all 6 shape parameters, we'll need a few random 
 *	 variables as well.
 * - Actually, if you think about it, position/angle/speed are kind of 
 *   impacting the same thing.
 * - Proposition:
 *		* Position: derived from angle and speed
 *		* Angle: randomly generated at start, but "bounce" off of walls to stay bounded
 *		* Speed: function of BPM. basically, update position on every beat by a fixed amount
 *		* Size: function of FFT results (continuous)
 *		* Type: fixed?
 *		* Color: maybe also a function of BPM? idk
 * 
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

FFT fft;
BeatDetect beat;
Minim minim;
AudioPlayer file;

/* User-defined values: */
final int BANDS = 1024;	 // Number of frequency bands
final int GROUPS = 32;	 // Number of groups to divide the frequency bands into - also, number of shapes.
final int MINSIZE = 10;  // shape sizes
final int MAXSIZE = 300; 
final int FFT_SCALE = 64; // scale the FFT results
final int SPEED = 100; // how far to advance on each beat
final int BEAT_SENSITIVITY = 200; // beat sensitivity - corresponds to 200 BPM i think?



/**
 * VizShape
 *
 * Represents a shape in the visualizer.
 *
 * @param heading: the angle of the shape
 * @param shape: the PShape object
 */
class VizShape{
	float xDir;
	float yDir;
	float x;
	float y;
	float w;
	float h;
	int flavor; // triangle=0, rectangle, star, ellipse=3
	int points;
	float oldAmp;
	color fill;

	/* Random shape constructor */
	VizShape(){
		this.oldAmp = 0;
		this.flavor = int(random(4));
		if(this.flavor == 2)
			this.points = int(random(5, 7));
		this.w = random(MINSIZE, MAXSIZE);
		this.h = random(MINSIZE, MAXSIZE);
		this.x = random(width);
		this.y = random(height);
		this.xDir = random(2) - 1;
		this.yDir = random(2) - 1;
		this.fill = color(random(256), random(256), random(256));
	}

	void scale(float newAmp){
		if(oldAmp == 0){
			oldAmp = newAmp;
			return;
		}
		if(newAmp == 0)
			newAmp = 0.01;
		float factor = newAmp / oldAmp;
		if(factor == 1.0)
			return;
	    w *= factor;
		h *= factor;
		if(w > MAXSIZE)
			w = MAXSIZE;
		if(h > MAXSIZE)
			h = MAXSIZE;
		oldAmp = newAmp;
	}

	void move(int speed){
		float newX = x + xDir * speed;
		float newY = y + yDir * speed;

		// Perform bounds checking 
		if (newX < 0 || newX > width){
			xDir *= -1;
			newX = x + xDir * speed;
		}
		if ( newY < 0 ||  newY > height){
			yDir *= -1;
			newY = y + yDir * speed;
		}

		x = newX;
		y = newY;
	}

	void draw(){
		PShape shape;
		switch(flavor){
			case 0: // TRIANGLE
					// technically not the randomly generated width and height but that's ok :)
				shape = createShape(TRIANGLE, x, y, x+w, y, x+(w/2), y+h);
				break;
			case 1: // RECTANGLE
				shape = createShape(RECT, x, y, w, h);
				break;
			case 2: // STAR
				shape = createStar(x, y, points, w, fill);
				break;
			default: // ELLIPSE
				shape = createShape(ELLIPSE, x, y, w, h);
				break;
		}
		shape.setFill(fill);
		shape(shape);
	}
/* References the Star class from earlier Constellation program. */
PShape createStar(float x, float y, int points, float size, color fill){
	PShape star = createShape();
	star.beginShape();
	star.fill(fill);
	star.noStroke();
	float angleOff = TWO_PI / (2 * points); // Calculate angle offset for star shape
	for (float angle = 0; angle < TWO_PI; angle += angleOff) {
		float sx = x + cos(angle) * size / 2;
		float sy = y + sin(angle) * size / 2;
		star.vertex(sx, sy);

		angle += angleOff;
		float bx = x + cos(angle) * size / 4; // Adjust size for star
		float by = y + sin(angle) * size / 4; // Adjust size for star
		star.vertex(bx, by);
	}
	star.endShape(CLOSE);

	return star;
}
}


VizShape[] shapes = new VizShape[GROUPS]; // Array of shapes

void setup() {
	size(800, 800);         // Set the size of the canvas
	background(0);		  // Set the background color

	// Initialize audio analysis objects
	Minim minim = new Minim(this);
	file = minim.loadFile("audio.mp3", BANDS);
	fft = new FFT(file.bufferSize(), file.sampleRate());
	beat = new BeatDetect(file.bufferSize(), file.sampleRate());
	beat.setSensitivity(BEAT_SENSITIVITY); 

	// Instantiate shapes.
	for (int i = 0; i < GROUPS; i++) {
		shapes[i] = new VizShape();
	}

	// Start playing the audio file
	file.loop();
}

void draw() {
	background(0); // clear the canvas

	// perform audio analysis
	beat.detect(file.mix);
	fft.forward(file.mix);

	// if on beat, update shape positions
	if (beat.isOnset(8)) {
		print("BEAT\n");

		// Iterate through each shape:
		for (int i = 0; i < GROUPS; i++) {
			shapes[i].move(SPEED);
		}
	}

	// Update sizes and draw shapes
	for (int i = 0; i < GROUPS; i++) {
		// Average the FFT results for this shape
		float sum = 0;
		for (int j = 0; j < BANDS/GROUPS; j++){
			sum += fft.getBand(i * BANDS/GROUPS + j);
		}
		sum /= (BANDS/GROUPS);
		// Update sizes based on FFT results
		shapes[i].scale(sum);

		// Draw all shapes
		shapes[i].draw();
	}
}
