///////////////////////////////////////////////////////////////////////////////////////// //
// COMS20600 - WEEKS 6 and 7
// ASSIGNMENT 2
// CODE SKELETON
// TITLE: "LED Particle Simulation"
// /////////////////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <platform.h>

out port cled[4] = {PORT_CLOCKLED_0,PORT_CLOCKLED_1,PORT_CLOCKLED_2,PORT_CLOCKLED_3}; out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;
in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;

//overall number of particles threads in the system
#define noParticles 3

// define move forbidden/allowed - make code more readible
#define forbidden 1
#define allowed 0

// true/false
#define true 1
#define false 0

#define CLKWISE 1
#define ACLKWISE -1

// No of cores
#define maxCoreNo 3

// Start position of n'th particle
const int startPosition[noParticles] = {0, 3, 6};

// Start directions of n'th  particles
const int startDirection[noParticles] = {ACLKWISE, CLKWISE, ACLKWISE};

//numbers that function pinsneq returns that correspond to buttons
#define buttonA 14
#define buttonB 13
#define buttonC 11
#define buttonD 7

enum {
	NOTSTARTED = 0,
	RUNNING = 1,
	PAUSED = 2,
	TERMINATED = 4
};

//Particle speed setting
#define PARTICLESPEED 5500000

// Define bool, true and false
//typedef unsigned int bool;
//#define true 1
//#define false 0

///////////////////////////////////////////////////////////////////////////////////////// //
// Helper Functions provided for you
// /////////////////////////////////////////////////////////////////////////////////////////
//DISPLAYS an LED pattern in one quadrant of the clock LEDs
void showLED(out port p, chanend fromVisualiser) {
	unsigned int lightUpPattern;
	unsigned int running = 1;
	while (running) {
		select {
			case fromVisualiser :> lightUpPattern: //read LED pattern from visualiser process
				p <: lightUpPattern; break;
			default:
				break;
		}
	}
}

//send pattern to LEDs
//PLAYS a short sound (pls use with caution and consideration to other students in the labs!)
void playSound(unsigned int wavelength, int duration, out port speaker) { timer tmr;
	int t, isOn = 1;
	tmr :> t;
	for (int i=0; i<duration; i++) {
		isOn = !isOn;
		t += wavelength;
		tmr when timerafter(t) :> void;
		speaker <: isOn;
	}
}

//WAIT function
void waitMoment(uint myTime) {
	timer tmr;
	unsigned int waitTime;
	tmr :> waitTime;
	waitTime += myTime;
	tmr when timerafter(waitTime) :> void;
}

///////////////////////////////////////////////////////////////////////////////////////// //
// RELEVANT PART OF CODE TO EXPAND
// /////////////////////////////////////////////////////////////////////////////////////////
//PROCESS TO COORDINATE DISPLAY of LED Particles
void visualiser(chanend toButtons, chanend show[], chanend toQuadrant[], out port speaker) {

	//array of ant positions to be displayed, all values 0..11
	unsigned int display[noParticles];

	//helper variable to determine system shutdown
	unsigned int running = true;

	//helper variable
	int j;

	// Input from buttons
	int input = 0;

	// Is simulation paused?
	int isPaused = false;

	// Has simulation started?
	int started = false;

	// Flash red leds
	cledR <: 1;

	input = 0;
	while (running) {
		waitMoment(PARTICLESPEED);

		// Check if buttons were pressed
		select {
			case toButtons :> input:
				break;
			default:
				break;
		}


		if(input == RUNNING && (!started || isPaused)) {
			for(int k=0; k<noParticles; k++) {
				show[k] <: RUNNING;
			}
			started = true;
			isPaused = false;
		}

		if(input == PAUSED) {
			for(int k=0; k<noParticles; k++) {
				show[k] <: PAUSED;
			}
			isPaused = true;
		}

		for (int k=0;k<noParticles;k++) {

			if(input == TERMINATED) {
				show[k] <: TERMINATED;
				break;
			}

			select {
				case show[k] :> j:
					if (j<12)
						display[k] = j;
					else
						playSound(20000,20,speaker);

					break;
				/////////////////////////////////////////////////////////////////////// //
				// ADD YOUR CODE HERE TO ACT ON BUTTON INPUT
				// ///////////////////////////////////////////////////////////////////////
				default:
					break;
			}


			//visualise particles
			for (int i=0;i<4;i++) {
				j = 0;
				for (int k=0;k<noParticles;k++)
					j += (16<<(display[k]%3))*(display[k]/3==i);
				toQuadrant[i] <: j;
			}
		}
	}
}

//READ BUTTONS and send commands to Visualiser
void buttonListener(in port buttons, chanend toVisualiser) {

	//button pattern currently pressed
	int buttonInput;

	//Pause flag
	int pause = false;

	//Simulation ON / OFF
	int simulationStarted = false;

	//Simulation Paused / Resumed
	int simulationPaused = false;

	//helper variable to determine system shutdown
	unsigned int running = 1;

	while (running) {

		buttons when pinsneq(15) :> buttonInput;

		/////////////////////////////////////////////////////////////////////// //
		// ADD YOUR CODE HERE TO ACT ON BUTTON INPUT
		// ///////////////////////////////////////////////////////////////////////

		switch(buttonInput){
			case buttonA:
				if(simulationStarted)
					waitMoment(1);
				else {
					simulationStarted = true;
					toVisualiser <: RUNNING;
					waitMoment(1);
					//START SIMULATION
				}
				break;
			case buttonB:
				if(simulationStarted) {
					waitMoment(1);
					simulationPaused = !simulationPaused;
					if(simulationPaused == true) {
						toVisualiser <: RUNNING;
					} else {
						toVisualiser <: PAUSED;
					}
					//PAUSE & RESUME
				} else
					waitMoment(1);
					//
				break;
			case buttonC:
				if(simulationStarted) {
					waitMoment(1);
					simulationStarted = false;
					toVisualiser <: TERMINATED;
					//HALT
				} else
					waitMoment(1);
					//thing
				break;
			case buttonD:
				if(simulationStarted)
					waitMoment(1);
					//Thing
				else
					waitMoment(1);
					//BEFORE START - NUMBER OF PARTICLES
				break;
			default:
				break;
		}


	}
}


// Change current direction to an opposite one
void toggleDirection(int& direction) {
	if(direction == CLKWISE) direction = ACLKWISE;
	else direction = CLKWISE;
}

int getAttemptedPosition(int direction, int position) {

	int attemptedPosition;
	// Choose new attempted position based on current direction
	if(direction == CLKWISE)
		attemptedPosition = position + 1;
	else
		attemptedPosition = position - 1;

	// Go in circle
	if(attemptedPosition == 12) attemptedPosition = 0;
	else if(attemptedPosition == -1) attemptedPosition = 11;

	return attemptedPosition;
}

//PARTICLE...thread to represent a particle - to be replicated noParticle-times
void particle(chanend left, chanend right, chanend toVisualiser, int startPosition, int startDirection) {

	//overall no of moves performed by particle so far
	unsigned int moveCounter = 0;

	//the current particle position
	unsigned int position = startPosition;

	unsigned int attemptedPosition;

	int currentDirection = startDirection;

	int leftMoveForbidden = 0;

	int rightMoveForbidden = 0;

	int currentVelocity = 1;

	int running = true;
	int started = false;
	int paused = false;

	int status = 0;

	/////////////////////////////////////////////////////////////////////// //
	// ADD YOUR CODE HERE TO SIMULATE PARTICLE BEHAVIOUR
	// ///////////////////////////////////////////////////////////////////////
	while(running) {
		// Assume the particle was requested position check
		int wasAsked = true;

		status = 0;

		// Check any state change for the simulation
		select {
			case toVisualiser :> status:
				break;
			default:
				break;
		}

		if(status == RUNNING) {
			printf("Starting or resuming\n");
			started = true;
			paused = false;
		} else if(status == PAUSED) {
			printf("Pausing!\n");
			paused = true;
		} else if(status == TERMINATED) {
			printf("Going to terminate\n");
			running = false;
			started = false;
			continue;
		}

		//printf("%d is now at position: %d\n",startPosition, position);
		toVisualiser <: position;

		if(paused || !started)
			continue;

		// Respond to position check requests
		while(wasAsked) {
			// See if left or right asks something
			select {
				case right :> rightMoveForbidden:
					//printf("%d: Was asked from right\n", startPosition);
					if(rightMoveForbidden == position) {
						// Position taken
						right <: forbidden;
						//Now we have to change direction - collision detected
						toggleDirection(currentDirection);
						wasAsked = false;
						//printf("%d Rejected move to: %d\n",startPosition, rightMoveForbidden);
					} else {
						right <: allowed;
						//printf("%d Allowed move to: %d\n",startPosition, rightMoveForbidden);
					}
					wasAsked = true;
					break;
				case left :> leftMoveForbidden:
					//printf("%d: Was asked from left\n", startPosition);
					if(leftMoveForbidden == position) {
						// Position taken, don't allow to move
						left <: forbidden;
						//Now we have to change direction - collision detected
						toggleDirection(currentDirection);
						// Now your turn
						wasAsked = false;
						//printf("%d Rejected move to: %d\n",startPosition, leftMoveForbidden);
					} else {
						left <: allowed;
						//printf("%d Allowed move to: %d\n",startPosition, leftMoveForbidden);
					}
					wasAsked = true;
				break;
				default:
					// No one wanted anything
					wasAsked = false;
					break;
			}
		}

		// Choose new attempted position based on current direction
		attemptedPosition = getAttemptedPosition(currentDirection, position);

		// If nothing asking, go and ask
		if(currentDirection == ACLKWISE) {

			int noReply = true;

			//printf("%d: Asking right\n", startPosition);
			right <: attemptedPosition;

			while(noReply) {
				select {
					case right :> rightMoveForbidden:
						//printf("%d: Got response from my right\n", startPosition);
						// Yay! Got response!
						noReply = false;
						break;
					default:
						// Wait for reply
						break;
				}
			}

			if(rightMoveForbidden == allowed) {
				position = attemptedPosition;
				//printf("%d Moving to: %d\n",startPosition, attemptedPosition);
			}
			else {
				// if move not allowed -> collision
				toggleDirection(currentDirection);
			}

		} else if(currentDirection == CLKWISE) {

			int noReply = true;

			//printf("%d: Asking left\n", startPosition);
			left <: attemptedPosition;

			while(noReply) {
				select {
					case left :> leftMoveForbidden:
						//printf("%d: Got response from my left\n", startPosition);
						noReply = false;
						break;
					default:
						//waitMoment(10000);
						break;
				}
			}

			if(leftMoveForbidden == allowed) {
				//printf("%d Moving to: %d\n",startPosition, attemptedPosition);
				position = attemptedPosition;
			}
			else {
				toggleDirection(currentDirection);
			}
		}



		//the verdict of the left neighbour if move is allowed

		//the verdict of the right neighbour if move is allowed

		//the current particle velocity
		//waitMoment(1000);

	}
	printf("Particle terminates...\n");
}

//MAIN PROCESS defining channels, orchestrating and starting the threads
int main(void) {

	//helper channels for LED visualisation
	chan quadrant[4];

	//channels to link visualiser with particles
	chan neighbours[noParticles];

	//channels to link neighbouring particles
	chan buttonToVisualiser;

	//channel to link buttons and visualiser
	chan show[noParticles];

	//MAIN PROCESS HARNESS
	par{
		//BUTTON LISTENER THREAD
		on stdcore[0]: buttonListener(buttons,buttonToVisualiser);

		par(int i = 0; i < noParticles; i++) {

			on stdcore[i % maxCoreNo] : particle(neighbours[(i==0) ? noParticles - 1 : i - 1],
					neighbours[(i == (noParticles - 1)) ? 0 : i + 1],
					show[i], startPosition[i], startDirection[i]);
		}

		//VISUALISER THREAD
		on stdcore[0]: visualiser(buttonToVisualiser, show, quadrant, speaker);

		//REPLICATION FOR THREADS PERFORMING LED VISUALISATION
		par (int k=0;k<4;k++) {
			on stdcore[k%4]: showLED(cled[k],quadrant[k]);
		}
	}
	return 0;
}
