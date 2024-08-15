// Complete Mover class
// With collision detection and response
//
// This mover class accelerates according to the force accumulated over TIME
// MASS is taken into consideration by using F=MA (or acceleation = force/mass)
// Mass is represented by the surface area of the this
// 
// The system works thus:-
// within each FRAME of the system
// 1/ calculate the cumulative acceleration (by acceleration += force/mass) by adding all the forces, including friction
// 2/ scale the acceleration by the elapsed time since the last frame (will be about 1/60th second)
// 3/ Add this acceleration to the velocity
// 5/ Move the this by the velocity scaled by the elapsed time since the last frame
// 5/ Set the acceleration back to zero again
// repeat

class Mover {

  Timer timer = new Timer();
  
  PVector location;
  PVector velocity = new PVector(0,0,0);
  PVector acceleration = new PVector(0,0,0);
  private float mass = 10;
  float radius;
  float frictionAmount = 0.3;
  float damping = 0.6; 
  int ballColour; // Add this line
  Mover() {
    setMass(10);
    ballColour = color(random(255), random(255), random(255));
  }
  
  ////////////////////////////////////////////////////////////
  // movement code has not changed except we now set the mass
  // by a method, which calculates the radius of the this
  // required for drawing and collision checking
  
  void setMass(float m){
    // converts mass into surface area
    mass=m;
    radius = 60 * sqrt( mass/ PI );
    
  }
  
  
 void update() {

   if (frameCount > 1) { // Skip applying forces on the first frame
      float gravityMagnitude = myUI.getSliderValue("Gravity");  
      PVector gravity = new PVector(0, gravityMagnitude * 120); // Adjust as needed
      float bounceMagnitude = myUI.getSliderValue("Bounce");  
      damping = bounceMagnitude; 
      acceleration.add(gravity);

      // Assume a simple constant time step for demonstration purposes
      float timeStep = 1.0 / 60.0; // 60 FPS

      velocity.add(PVector.mult(acceleration, timeStep));
      location.add(PVector.mult(velocity, timeStep));

      // Reset acceleration after applying it
      acceleration.set(0, 0, 0);
      
      checkCollisionWithPegs(pegPositions);// Pass peg positions for collision detection
      checkForBounceOffPlinkoEdges(); 
      display();
      collisionResponse(this);
      checkCollisionWithBottomBar();

    }
  
}
  
  void addForce(PVector f){
    // use F= MA or (A = F/M) to calculated acceleration caused by force
    PVector accelerationEffectOfForce = PVector.div(f, mass);
    acceleration.add(accelerationEffectOfForce);
  }

  void display() {
    noStroke();
    strokeWeight(2);
    fill(ballColour);
    pushMatrix(); // Save the current transformation matrix
    translate(location.x, location.y, location.z); // Move to the this's location
    sphere(radius); // Draw the sphere with the given radius
    popMatrix(); // Restore the transformation matrix
  }
  
 
  
  void applyFriction(){
    // modify the acceleration by applying
    // a force in the opposite direction to its velociity
    // to simulate friction
    PVector reverseForce = PVector.mult( velocity, -frictionAmount );
    addForce(reverseForce);
  }
  
  ////////////////////////////////////////////////////////////
  // new collision code
  // call collisionCheck just before or after update in the "main" tab
  
  boolean collisionCheck(Mover otherMover){
    
    if(otherMover == this) return false; // can't collide with yourself!
    
    float distance = otherMover.location.dist(this.location);
    float minDist = otherMover.radius + this.radius;
    if (distance < minDist)  return true;
    return false;
  }
  
  
  void collisionResponse(Mover otherMover) {
    // based on https://en.wikipedia.org/wiki/Elastic_collision

    if(otherMover == this) return; // can't collide with yourself!

    PVector v1 = this.velocity;
    PVector v2 = otherMover.velocity;

    PVector cen1 = this.location;
    PVector cen2 = otherMover.location;

    // calculate v1New, the new velocity of this mover
    float massPart1 = 2 * otherMover.mass / (this.mass + otherMover.mass);
    PVector v1subv2 = PVector.sub(v1, v2);
    PVector cen1subCen2 = PVector.sub(cen1, cen2);
    float topBit1 = v1subv2.dot(cen1subCen2);
    float bottomBit1 = cen1subCen2.mag() * cen1subCen2.mag();

    float multiplier1 = massPart1 * (topBit1 / bottomBit1);
    PVector changeV1 = PVector.mult(cen1subCen2, multiplier1);

    PVector v1New = PVector.sub(v1, changeV1).mult(damping); // Apply damping to v1New

    // calculate v2New, the new velocity of other mover
    float massPart2 = 2 * this.mass / (this.mass + otherMover.mass);
    PVector v2subv1 = PVector.sub(v2, v1);
    PVector cen2subCen1 = PVector.sub(cen2, cen1);
    float topBit2 = v2subv1.dot(cen2subCen1);
    float bottomBit2 = cen2subCen1.mag() * cen2subCen1.mag();

    float multiplier2 = massPart2 * (topBit2 / bottomBit2);
    PVector changeV2 = PVector.mult(cen2subCen1, multiplier2);

    PVector v2New = PVector.sub(v2, changeV2).mult(damping); // Apply damping to v2New

    this.velocity = v1New;
    otherMover.velocity = v2New;
    ensureNoOverlap(otherMover);
}
  
 
void ensureNoOverlap(Mover otherMover) {
    PVector direction = PVector.sub(this.location, otherMover.location);
    float distance = direction.mag();
    float minDistance = this.radius + otherMover.radius;

    // Check if balls are overlapping
    if (distance < minDistance) {
        float overlap = minDistance - distance;

        // Normalize the direction vector, then scale it by half the overlap distance
        direction.normalize();
        direction.mult(overlap + 0.5);

        // Separate the balls based on their mass
        float totalMass = this.mass + otherMover.mass;
        PVector separation = PVector.mult(direction, (otherMover.mass / totalMass));

        this.location.add(PVector.mult(separation, 1.1)); // Adjusted multiplier to separate further
        otherMover.location.sub(PVector.mult(separation, 1.1));
    }
}
  
  
     void checkForBounceOffPlinkoEdges() {
       if (frameCount > 10){
          PVector collisionNormalLeft = new PVector(1, 0); // Normal pointing right for left wall collision
          PVector collisionNormalRight = new PVector(-1, 0); // Normal pointing left for right wall collision
          // Check collision with left wall
          if (this.location.x - this.radius < -125) {
              this.velocity = PVector.sub(this.velocity, PVector.mult(collisionNormalLeft, 2 * this.velocity.dot(collisionNormalLeft)));
              this.velocity.mult(damping); // Apply damping
              // Adjust the this's position to prevent sticking
              this.location.x = -125 + this.radius;
          }
          // Check collision with right wall
          else if (this.location.x + this.radius > 150) {
              this.velocity = PVector.sub(this.velocity, PVector.mult(collisionNormalRight, 2 * this.velocity.dot(collisionNormalRight)));
              this.velocity.mult(damping); // Apply damping
              this.location.x = 150 - this.radius;
          }
       }
}
    void checkCollisionWithPegs(ArrayList<PVector> pegPositions) {
      for (PVector peg : pegPositions) {
        float distance = PVector.dist(this.location, new PVector(peg.x, peg.y, this.location.z));
        if (distance < (this.radius + effectivePegRadius)) {
            // Calculate collision normal for X and Y only
            PVector collisionNormal = PVector.sub(new PVector(this.location.x, this.location.y), new PVector(peg.x, peg.y)).normalize();
            
            // Reflect the ball's velocity vector across the collision normal, ignoring Z
            float originalZVelocity = this.velocity.z; // Save original Z velocity
            PVector reflectedVelocity = PVector.sub(this.velocity, PVector.mult(collisionNormal, 2 * this.velocity.dot(collisionNormal)));
            reflectedVelocity.z = originalZVelocity; // Restore original Z velocity
            
            // Apply damping to simulate energy loss, if necessary
            reflectedVelocity.mult(damping); 
            
            // Nudge the ball slightly away from the peg to prevent sticking
            PVector nudge = PVector.mult(collisionNormal, this.radius + effectivePegRadius - distance + 0.5f); // Slightly greater than overlap
            this.location.add(nudge);
            
            // Update the ball's velocity
            this.velocity = reflectedVelocity;
            
            break; 
          }
      }
    }
  // Example method in the Mover class for checking collision with the bottom bar
  void checkCollisionWithBottomBar() {
      if (!bottomBarVisible) return;
      // Assuming the ball bounces back when hitting the bottom bar
      if (this.location.y + this.radius >= bottomBarYPosition) {
          this.velocity.y *= -damping; // Invert Y velocity to bounce, apply damping to simulate energy loss
          this.location.y = bottomBarYPosition - this.radius; // Adjust the ball's position to prevent it from going into the bar
      }
  }
  
}
