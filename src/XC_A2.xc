///////////////////////////////////////////////////////////////////////////////////////// //
// COMS20600 - WEEKS 6 and 7
// ASSIGNMENT 2
// CODE SKELETON
// TITLE: "LED Particle Simulation"
// /////////////////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <platform.h>

out port cled[4] = {PORT_CLOCKLED_0,PORT_CLOCKLED_1,PORT_CLOCKLED_2,PORT_CLOCKLED_3};
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;
in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;
out port buttonLed = PORT_BUTTONLED;

//overall number of particles threads in the system
#define noParticles 4

//max particles to display
#define maxParticles 5

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
#define numberOfCores 4

// Start position of n'th particle
const int startPositions[maxParticles] = {0, 3, 6, 8, 10};//, 2};

// Start directions of n'th  particles
const int startDirections[maxParticles] = {ACLKWISE, CLKWISE, ACLKWISE, CLKWISE, ACLKWISE};//, CLKWISE};

// Start speed of particles
const unsigned int speed[maxParticles] = {10, 11, 12, 12, 15};//, 25};

//numbers that function pinsneq returns that correspond to buttons
#define buttonA 14
#define buttonB 13
#define buttonC 11
#define buttonD 7

enum {
	RUNNING = 21,
	PAUSED = 22,
	TERMINATED = 23,
	COLLISION = 30,
	KILL = 66
};

//Particle max speed setting
#define MAXPARTICLESPEED 275000

// Delay buttons so you can click on them a bit 'slower'
#define BUTTONDELAY 32000000

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
			case fromVisualiser :> lightUpPattern: {//read LED pattern from visualiser process
				if(lightUpPattern == TERMINATED) {
					p <: 0;
					running = false;
					break;
				}
				p <: lightUpPattern;
			}
			break;
			default:
				break;
		}
	}
	//printf("Going to kill showLED\n");
}

//send pattern to LEDs
//PLAYS a short sound (pls use with caution and consideration to other students in the labs!)
void playSound(unsigned int wavelength, int duration, out port speaker) {
	timer tmr;
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

//Function that counts waitMoment for visualiser
inline unsigned int particleSpeed() {
	int s = 0;
	for(int i = 0; i < noParticles; i++) {
		s = s *MAXPARTICLESPEED * speed[i];
	}
	return s;
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
	int input = PAUSED;

	// Flash red initally
	cledR <: 0;
	cledG <: 1;

	// Say it's synchronized initially - wait for input
	// Get initial positions
	for(int i = 0; i < noParticles; i++) {
		show[i] :> j;
		display[i] = j;
	}

	while (running) {

		// Check if buttons were pressed
		select {
			case toButtons :> input:
				break;
			default:
				break;
		}


		if(input == TERMINATED) {
			int stop;
			for(int k = 0; k < noParticles; k++) {
				select {
					case show[k] :> j:
						stop = true;
						show[k] <: TERMINATED;
						break;
					default:
						break;
				}
			}

			if(stop) {
				//printf("Stop.\n");
				running = false;
				continue;
			}
		}

		//waitMoment(particleSpeed());
		waitMoment(MAXPARTICLESPEED);


		for (int k=0; k<noParticles; k++) {

			if(input == RUNNING || input == TERMINATED)
			{


				select {
					case show[k] :> j: {
						// Got a position to display
						if (j < 12 && j >= 0) {
							// Update displayed position
							display[k] = j;
							show[k] <: input;

							if(input == TERMINATED)
								display[k] = TERMINATED;

						} else {
							int requestedPosition = j - 1000;
							int result = allowed;
							for(int i = 0; i < noParticles; i++)
							{
								if(display[i] == requestedPosition)
								{
									if(input == TERMINATED) {
										show[i] <: TERMINATED;
									} else {
										show[i] <: COLLISION;
										playSound(200000, 5, speaker);
									}
									result = forbidden;
									break;
								}
							}
							if(result == allowed) {
								display[k] = requestedPosition;
							}
							if(input != TERMINATED)
								show[k] <: result;
							else {
								show[k] <: TERMINATED;
								display[k] = TERMINATED;
							}
						}
						break;
					}
					default:
						break;
				}
			}

		}



		// Tell status of game by color of leds
		cledG <: input == PAUSED;
		cledR <: input != PAUSED;

		// Visualise particles at their given position
		for (int i=0; i<= maxCoreNo; i++) {

			j = 0;

			for (int k=0; k<noParticles; k++) {
				if(display[k] == TERMINATED)
					j = 0;
				else {
					j += (16<<(display[k]%3))*(display[k]/3==i);
				}
			}

			toQuadrant[i] <: j;
		}

//		for (int k=0;k<noParticles;k++) {
//			running = true;
//			if(display[k] == TERMINATED)
//				running = false;
//		}
		if(input == TERMINATED)
		{
			running = false;
		}
	}


	//printf("Going to kill visualiser\n");

//	for (int k=0;k<noParticles;k++) {
//		show[k] :> j;
//		show[k] <: TERMINATED;
//	}

	for (int k=0; k<= maxCoreNo; k++)
		toQuadrant[k] <: TERMINATED;
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

	int prevInput;
	//helper variable to determine system shutdown
	unsigned int running = 1;

	while (running) {

		buttons when pinsneq(0) :> buttonInput;

		if(prevInput == buttonInput)
			continue;

		/////////////////////////////////////////////////////////////////////// //
		// ADD YOUR CODE HERE TO ACT ON BUTTON INPUT
		// ///////////////////////////////////////////////////////////////////////

		switch(buttonInput){
			case buttonA:
				if(simulationStarted)
					break;
				else {
					//START SIMULATION
					simulationStarted = true;
					toVisualiser <: RUNNING;
				}
				break;
			case buttonB:
				//PAUSE & RESUME
				if(simulationStarted) {
					if(simulationPaused) {
						simulationPaused = false;
						toVisualiser <: RUNNING;
					} else {
						simulationPaused = true;
						toVisualiser <: PAUSED;
					}
				}
				break;
			case buttonC:
				//HALT
				simulationStarted = false;
				simulationPaused = false;
				toVisualiser <: TERMINATED;
				running = false;
				break;
			case buttonD:
				if(simulationStarted) {}
					//Thing
				else {}
					//BEFORE START - NUMBER OF PARTICLES
				break;
			default:
				break;
		}

		buttonLed <: (1 * simulationStarted) + (2 * simulationPaused);
		waitMoment(BUTTONDELAY);

		prevInput = buttonInput;
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
void particle(chanend left, chanend right, chanend toVisualiser, int startPosition, int startDirection, int startVelocity) {

	//overall no of moves performed by particle so far
	unsigned int moveCounter = 0;

	//the current particle position
	unsigned int position = startPosition;

	unsigned int attemptedPosition;

	int currentDirection = startDirection;

	int leftMoveForbidden = 0;

	int rightMoveForbidden = 0;

	int currentVelocity = 1;

	// Is still simulating?
	int running = true;

	// Pause initially
	int status = PAUSED;

	int isMaster = false;
	int kills = false;
	int skip = startVelocity;

	// Display start position
	toVisualiser <: startPosition;

	isMaster = startPositions[0] == startPosition;
	if(isMaster)
	{
		//printf("I am a master!\n");
		right <: 0;
	}


	while(running) {
		int waitForUpdate = true;

		// Pass status to the left
		//printf("%d Wait left\n", startPosition);
		while(waitForUpdate) {
			select {
				case right :> status:
					//printf("Got terminated\n");
					waitForUpdate = false;
					if(kills == false) {
						// not a killer, pass it
						left <: status;
					}
					running = false;
					break;
				case left :> status:

					//printf("I am %d got from left: %d\n",  startPosition, status);

					waitForUpdate = false;
					break;
				case toVisualiser :> status:

					//printf("%d got some update!\n", startPosition);
					if(status == COLLISION) {
						toggleDirection(currentDirection);
					}

					if(status == TERMINATED) {
						//printf("Got terminated\n");
						waitForUpdate = false;
					}

					break;
			}
		}

		if(!running)
			continue;

		// Report position unless terminating
		if(status != TERMINATED) {
			toVisualiser <: position;
		}

		if(status != COLLISION && status != TERMINATED) {
		// Receive status
			select {
				case toVisualiser :> status:
					//printf("%d Going synced\n", startPosition);
					break;
			}
		}

		if(status == TERMINATED) {
			// Do nothing...
		} else if(status == COLLISION) {
			//printf("%d I guess i need to bumpt\n", startPosition);
			toggleDirection(currentDirection);

		} else if(status == RUNNING) {

			if(skip > 0) {
				skip--;
			} else {
				skip = startVelocity;

				//printf("%d I am free to go!\n", startPosition);

				attemptedPosition = getAttemptedPosition(currentDirection, position);

				toVisualiser <: (attemptedPosition + 1000);

				toVisualiser :> rightMoveForbidden;

				if(rightMoveForbidden == TERMINATED) {
					status = TERMINATED;
					//printf("Got terminated\n");
				}
				else if(rightMoveForbidden == allowed)
					position = attemptedPosition;
				else
				{
					if(currentDirection == CLKWISE) {
						//int newStatus = ((status << 2) & COLLISION);
						//printf("%d One to me left should change dir\n", startPosition);
					} else  {
						//printf("%d One to me right should change dir\n", startPosition);
					}
					toggleDirection(currentDirection);
				}


			}

		}


		// Read status from right
		//printf("%d Send right\n", startPosition);
		if(status == TERMINATED)
		{
			kills = true;
			left <: TERMINATED;
			continue;
		}

		//printf("I am %d, sending to right: %d\n",  startPosition, status);
		right <: status;
	}
	//printf("%d Particle terminates...\n", startPosition);
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

			on stdcore[i % maxCoreNo] : particle(neighbours[ (i - 1 + noParticles)%noParticles], neighbours[i%noParticles],
					show[i], startPositions[i], startDirections[i], speed[i]);
		}

//		on stdcore[0] : particle(neighbours[3], neighbours[0], show[0], startPositions[0], startDirections[0], speed[0]);
//		on stdcore[1] : particle(neighbours[0], neighbours[1], show[1], startPositions[1], startDirections[1], speed[1]);
//		on stdcore[2] : particle(neighbours[1], neighbours[2], show[2], startPositions[2], startDirections[2], speed[2]);
//		on stdcore[3] : particle(neighbours[2], neighbours[3], show[3], startPositions[3], startDirections[3], speed[3]);

		//VISUALISER THREAD
		on stdcore[0]: visualiser(buttonToVisualiser, show, quadrant, speaker);

		//REPLICATION FOR THREADS PERFORMING LED VISUALISATION
		par (int k=0; k<numberOfCores; k++) {
			on stdcore[k%numberOfCores]: showLED(cled[k],quadrant[k]);
		}
	}
	return 0;
}
