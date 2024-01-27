// Star Constellation Generator
// This program creates a starry sky with constellations on a canvas.

int cols, rows;          // Number of columns and rows in the grid
float unitSize;          // Size of each grid unit
Star[][] stars;          // 2D array to store Star objects

void setup() {
  size(600, 600);         // Set the size of the canvas
  cols = 10;              // Number of columns in the grid
  rows = 10;              // Number of rows in the grid
  unitSize = width / cols; // Calculate the size of each grid unit
  stars = new Star[cols][rows]; // Initialize the array for stars
  
  // Populate stars randomly
  populateStars();
  
  // Draw constellations
  drawConstellations();
}

void draw() {
  // Display stars and constellations
  displayStars();
  displayConstellations();
}

void populateStars() {
  // Populate the stars array with randomly generated stars
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      // Randomly decide whether to create a star at this position; if greater than 0.5, created, otherwise, not
      if (random(1) > 0.5) {
        float x = i * unitSize + unitSize / 2;
        float y = j * unitSize + unitSize / 2;
        int points = int(random(5, 8)); // Random number of points for the star
        float size = unitSize * random(0.2, 0.8); // Random size within a specified range
        color starColor = color(random(255), random(255), random(255)); // Random fill color for the star
        stars[i][j] = new Star(x, y, points, size, starColor);
      }
    }
  }
}

void drawConstellations() {
  // Draw random constellations by connecting stars
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      if (stars[i][j] != null) {
        int lines = int(random(4)); // Random number of constellation lines
        for (int k = 0; k < lines; k++) {
          drawConstellationLine(i, j);
        }
      }
    }
  }
}

void drawConstellationLine(int i, int j) {
  // Draw a line between two stars to form a constellation
  int neighborI = int(random(cols));
  int neighborJ = int(random(rows));
  
  if (stars[neighborI][neighborJ] != null) {
    color lineColor = color(random(255), random(255), random(255)); // Random stroke color for the line
    stroke(lineColor);
    line(stars[i][j].x, stars[i][j].y, stars[neighborI][neighborJ].x, stars[neighborI][neighborJ].y);
  }
}

void displayStars() {
  // Display each star on the canvas
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      if (stars[i][j] != null) {
        stars[i][j].display();
      }
    }
  }
}

void displayConstellations() {
  // Additional display logic for constellations if needed
}

class Star {
  float x, y;    // Position of the star
  int points;    // Number of points in the star shape
  float size;    // Size of the star
  color fillColor; // Fill color of the star
  
  Star(float x, float y, int points, float size, color fillColor) {
    // Constructor to initialize a Star object
    this.x = x;
    this.y = y;
    this.points = points;
    this.size = size;
    this.fillColor = fillColor;
  }
  
  // Reference: https://processing.org/examples/star.html
  void display() {
    // Display stars using a shape with multiple vertices and random fill color
    fill(fillColor);
    noStroke();
    beginShape();
    float angleOff = TWO_PI / (2 * points); // Calculate angle offset for star shape
    for (float angle = 0; angle < TWO_PI; angle += angleOff) {
      float sx = x + cos(angle) * size / 2;
      float sy = y + sin(angle) * size / 2;
      vertex(sx, sy);
      
      angle += angleOff;
      float bx = x + cos(angle) * size / 4; // Adjust size for star
      float by = y + sin(angle) * size / 4; // Adjust size for star
      vertex(bx, by);
    }
    endShape(CLOSE);
  }
}
