import peasy.*;
import processing.core.*;

PeasyCam cam;
Timer preGameTimer = new Timer();
SimpleUI myUI;

///////////////////////////////////////////////////////
///                   VAR INIT                      ///
///////////////////////////////////////////////////////

float boardWidth, boardHeight, boardThickness, pegHeight, pegBaseSize, effectivePegRadius, bottomBarYPosition, dividerWidth, dividerHeight; 
float markerX = -120; // Initial position of the marker
float markerSpeed = 2; // Speed of the marker

int markerDirection = 1; // Direction of the marker movement (1 for right, -1 for left)
int currentPresetIndex = 0;

ArrayList<Mover> balls; // To hold multiple balls
ArrayList<PVector> pegPositions; // Holds the positions of the pegs
ArrayList<PVector> dividerXPositions; // Holds the X positions of each divider's center
ArrayList<CameraPreset> presets = new ArrayList<CameraPreset>();

boolean bottomBarVisible = true;
boolean usePeasyCam = true;
boolean displayTitle = true;
boolean preGame = true; // To track if the pre-game phase is active

PFont boldFont;



// Initialization in setup()
void setup() {
    size(800, 600, P3D);
    
    myUI = new SimpleUI(); // Initialize the SimpleUI instance
    
    
    cam = new PeasyCam(this, 100);
    setupPresets();

    balls = new ArrayList<Mover>(); // Initialize the ArrayList for balls
    
///////////////////////////////////////////////////////
///                   Peg Setup                     ///
///////////////////////////////////////////////////////
    pegPositions = new ArrayList<PVector>(); // Initialize the list for peg positions
    effectivePegRadius = 2;
    int rows = 10;
    int cols = 5;
    float spacing = 50;
    float offset = spacing / 2; // For offsetting rows
    pegBaseSize = 7;
    boardThickness = 8;
    boardWidth = (cols - 1) * spacing + pegBaseSize * 10;
    boardHeight = (rows - 1) * spacing + pegBaseSize * 10 + 110;
    pegHeight = 51;

    // Peg position calculation (kept in setup since it's static)
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            float x = (j - (cols - 1) / 2.0f) * spacing;
            if (i % 2 == 1) x += offset; // Offset for odd rows
            float y = (i - (rows - 1) / 2.0f) * spacing;
            pegPositions.add(new PVector(x, y, pegHeight / 2));
        }
    }
    
///////////////////////////////////////////////////////
///                Barrier Setup                    ///
///////////////////////////////////////////////////////
    int[] barrierX = {-78, -24, 30, 90};
    int[] barrierY = {274, 281, 286, 293, 300, 307};
    for (int i = 0; i < barrierX.length; i++) {
      for (int j = 0; j < barrierY.length; j++) {
        pegPositions.add(new PVector(barrierX[i], barrierY[j], pegHeight / 2));
      }
    }
    
      

///////////////////////////////////////////////////////
///                Camera Setup                     ///
///////////////////////////////////////////////////////
     if (!presets.isEmpty()) {
        CameraPreset initialPreset = presets.get(0);
        cam.lookAt(initialPreset.lookAt.x, initialPreset.lookAt.y, initialPreset.lookAt.z, 500);
        cam.setDistance(initialPreset.distance);
        cam.setActive(false);
    }
///////////////////////////////////////////////////////
///           Initial decorative ball drop          ///
///////////////////////////////////////////////////////
    int numberOfBallsToDrop = 10; // Random number between 1 and 10
            for (int i = 0; i < numberOfBallsToDrop; i++) {
                Mover newBall = new Mover();
                float randomX = random(-120, 145); // Random X position within the range
                newBall.location = new PVector(randomX, -250, 20); // Use randomX for the x position
                newBall.setMass(0.1);
                balls.add(newBall);
            }
    
    String fontName = "bubbleboddy Fat";
    boldFont = createFont(fontName, 128);
}
///////////////////////////////////////////////////////
///              Key press detection                ///
///////////////////////////////////////////////////////
void keyPressed() {
  if (key == ' ') { // Checks if the spacebar is pressed
     Mover newBall = new Mover();
    newBall.location = new PVector(markerX, -250, 20); // Use markerX for the x position
    newBall.setMass(0.1);
    balls.add(newBall);
    balls.add(newBall); // Adds the new ball to the ArrayList of balls
  } else if (key == 'c' || key == 'C') {
    // Clears all the balls when 'C' is pressed
    balls.clear();
  } else if (key == '1') {
    bottomBarVisible = !bottomBarVisible;
  } else if (key == 'p' || key == 'P') { 
      if (key == 'p' || key == 'P') {
          usePeasyCam = !usePeasyCam;
          cam.setActive(usePeasyCam);
        }
  } else if (key == TAB) {
    preGame = !preGame; // Toggle pre-game phase
    if (preGame) {
        // Reset the timer if re-entering pre-game phase
        preGameTimer.start();
    } else {
        // Clear balls or other setup for game start
        balls.clear();
    }
    currentPresetIndex = (currentPresetIndex + 1) % presets.size(); // Cycle through presets
    applyPreset(presets.get(currentPresetIndex)); // Apply the current preset
    displayTitle = !displayTitle; 
    cam.setActive(true);
  }
}

void drawSideWalls() {
    float wallThickness = pegBaseSize;
    float wallHeight = pegHeight;
    float wallLength = boardHeight;
    // Left Wall
    pushMatrix();
    translate((-boardWidth / 2 - wallThickness / 2) + 10, 0, wallHeight / 2 - boardThickness / 2);
    fill(100, 100, 255);
    box(wallThickness, wallLength, wallHeight);
    popMatrix();
    // Right Wall
    pushMatrix();
    translate((boardWidth / 2 + wallThickness / 2) + 10, 0, wallHeight / 2 - boardThickness / 2);
    fill(100, 100, 255);
    box(wallThickness, wallLength, wallHeight);
    popMatrix();
}

void drawPegs() {
    for (PVector peg : pegPositions) {
        pushMatrix();
        translate(peg.x, peg.y, peg.z);
        if (peg.y > 273) {
        } else {
                  fill(0, 0, 255); // Blue pegs
        }

        box(pegBaseSize, pegBaseSize, pegHeight); // Draw each peg
        popMatrix();
    }
    
}

void updateBallsAndCheckCollisions(ArrayList<Mover> balls) {
    // Update each ball and check for collisions with other balls
    for (int i = 0; i < balls.size(); i++) {
        Mover ballA = balls.get(i);
        ballA.update(); // Update the ball's position based on its velocity, etc.

        // Check for collisions with other balls
        for (int j = i + 1; j < balls.size(); j++) {
            Mover ballB = balls.get(j);

            // Use the collisionCheck method to see if ballA and ballB are colliding
            if (ballA.collisionCheck(ballB)) {
                // If there's a collision, respond accordingly
                ballA.collisionResponse(ballB);
            }
        }
    }
}

void drawBottomSection() {
  float bottomBarrierHeight = 20; 
  float bottomBarrierThickness = 10; 
  float sectionDepth = pegHeight; 
  

  if (!bottomBarVisible) return;
  // Draw bottom barrier
  pushMatrix();
  translate(10, (boardHeight / 2 + bottomBarrierHeight / 2) - 10, 23); // Position it at the bottom of the board
  fill(100, 100, 255);
  box(boardWidth + 12, bottomBarrierThickness, sectionDepth);
  popMatrix();
  bottomBarYPosition = ((boardHeight / 2 + bottomBarrierHeight / 2) - 12);
}



void drawArrow(float x, float y, float size) {
  pushMatrix();
  translate(x, y, 20); 
  fill(255, 0, 0); // Red arrow
  noStroke();

  // Arrow body
  rectMode(CENTER);
  rect(0, 0, size * 0.2, size);

  // Arrow head - now pointing down
  beginShape();
  vertex(-size * 0.4, size / 2); // Move to bottom half
  vertex(0, size); 
  vertex(size * 0.4, size / 2); // Other side
  endShape(CLOSE);

  popMatrix();
}



void setupPresets() {
    presets.add(new CameraPreset(new PVector(8.4702215f, 0.40635705f, 0.0f), 199.8234596899309f, 0.0f, 0.0f));
    presets.add(new CameraPreset(new PVector(8.4702215f, 0.40635705f, 0.0f), 607.1079968169681f, 0.0f, 0.0f));

    // Apply the first preset initially
    applyPreset(presets.get(0));
}

void applyPreset(CameraPreset preset) {
    cam.lookAt(preset.lookAt.x, preset.lookAt.y, preset.lookAt.z);
    cam.setDistance(preset.distance);

}

void applyCustomCameraPreset() {

    camera(
        30.0, 40.0, 100.0, // eyeX, eyeY, eyeZ
        0.0, 0.0, 0.0, // centerX, centerY, centerZ
        0.0, 1.0, 0.0  // upX, upY, upZ
    );

}

void handleUIEvent(UIEventData uied) {
  if (uied.uiLabel.equals("START") && uied.mouseEventType.equals("mouseReleased")) {
    

    preGame = !preGame; 
    if (preGame) {

        preGameTimer.start();
    } else {

        balls.clear();
    }
    currentPresetIndex = (currentPresetIndex + 1) % presets.size(); // Cycle through presets
    applyPreset(presets.get(currentPresetIndex)); 
    displayTitle = !displayTitle; 
    cam.setActive(true);
    balls.clear();
    

  }
}

void drawHUD() {
    if (preGame){
    fill(0); // Set text color to black for visibility
    textFont(boldFont);
    textSize(128); // Increase text size for bigger text
    textAlign(CENTER, CENTER); // Center the text alignment
    text("PLINKO", width / 2, height / 2 - 30); 
    textSize(32); 
    text("Press TAB to start", width / 2, height / 2 + 120);


    myUI.addSlider("Gravity", 20, 100);
    myUI.addSlider("Bounce", 20, 180);
    myUI.update(); 
    } else {
    fill(0); // Set text color to black for visibility
    textAlign(LEFT, CENTER); // Center the text alignment
    textSize(20); // Increase text size for bigger text
    text("Press SPACE to drop ball", 20, 20); 
    text("Press C to clear", 20, 40); 
    text("Press 1 to release balls", 20, 60); 


    }
}
void preGameDec() {
  if (preGameTimer.getTimeSinceStart() > 14) {
            // Clear existing balls
            balls.clear();
            // Drop a random number of balls
            int numberOfBallsToDrop = 10; // Random number between 1 and 10
            for (int i = 0; i < numberOfBallsToDrop; i++) {
                Mover newBall = new Mover();
                float randomX = random(-120, 145); // Random X position within the range
                newBall.location = new PVector(randomX, -250, 20); // Use randomX for the x position
                newBall.setMass(0.1);
                balls.add(newBall);
            }
            // Reset the timer after dropping the balls
            preGameTimer.start();
        }
}
void draw() {
    background(255);
    noStroke();
    
    if (preGame) {
        preGameDec();
    }
    
    if (!usePeasyCam) {
        applyCustomCameraPreset();
    }
    // Update and draw the marker as an arrow
    markerX += markerSpeed * markerDirection;
    if (markerX >= 145 || markerX <= -120) {
        markerDirection *= -1;
    }
    // Draw the arrow marker
    drawArrow(markerX, -300, 40); 
    PVector gravity = new PVector(0, 0.1);
    updateBallsAndCheckCollisions(balls);
    for (Mover ball : balls) {
        ball.addForce(gravity);
        ball.update();
    }

    lights();
    drawSideWalls();
    drawBottomSection();
    drawPegs();
    pushMatrix();
    fill(200); // Light gray
    translate(10, 0, 0); // Slightly adjust the board position
    box(boardWidth, boardHeight, boardThickness);
    popMatrix();
    cam.beginHUD(); // Temporarily disable the camera's effect
    drawHUD(); // Draw the HUD elements
    cam.endHUD(); // Re-enable the camera's effect
}
