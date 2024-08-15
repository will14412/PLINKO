class CameraPreset {
    PVector lookAt;
    float distance;
    float theta; 
    float phi; 

    // Constructor
    CameraPreset(PVector lookAt, float distance, float theta, float phi) {
        this.lookAt = lookAt;
        this.distance = distance;
        this.theta = theta;
        this.phi = phi; 
    }
}
