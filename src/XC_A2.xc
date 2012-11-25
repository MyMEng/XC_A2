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
	RUNNING = 21,
	PAUSED = 22,
	TERMINATED = 23
};

//Particle speed setting
#define PARTICLESPEED 8500000

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

	//keep track of synced particles
	int synced[noParticles];

	//helper variable
	int j;

	// Input from buttons
	int input = 0, previousInput = 0;

	// Is simulation paused?
	int isPaused = false;

	// Has simulation started?
	int started = false;

	// Flash red leds
	cledR <: 1;

	// Say it's synchronized initially - wait for input
	for(int k = 0; k < noParticles; k++) {
		synced[k] = true;
	}

	while (running) {
		waitMoment(PARTICLESPEED);

		// Check if buttons were pressed
		select {
			case toButtons :> input: {
				printf("Vis got input %d\n", input);



				if(previousInput != input) {
					for(int i = 0; i < noParticles; i++) {
						synced[i] = false;
					}
					previousInput = input;
				}
				break;
			}
			default: {
				break;
			}
		}

		if(input == TERMINATED && !started)
		{
			for(int k = 0; k < noParticles; k++)
				show[k] <: TERMINATED;

			running = false;
			continue;
		}

		if(input == RUNNING && (!started || isPaused)) {
			printf("Going to start\n");
			for(int k = 0; k < noParticles; k++) {
				show[k] <: RUNNING;
				synced[k] = true;
			}
			started = true;
			isPaused = false;
		}

		for (int k=0;k<noParticles;k++) {

			//int wasPauseSent = false;
			select {
				case show[k] :> j: {



					// Got a position to display
					if (j<12) {
						// Update displayed position
						display[k] = j;
					} else if(j == 1000) {
						show[k] <: input;

						if(input == TERMINATED)
							synced[k] = true;
//						if(input == PAUSED && !isPaused)
//						{
//							printf("%d Going to send pause\n", k);
//							show[k] <: PAUSED;
//						}
					} else {
						printf("Wierd input\n");
					}
					break;
				}
				default: {
					break;
				}
			}
			//if(wasPauseSent)
			//	break;

			//visualise particles
			for (int i=0;i<4;i++) {
				j = 0;
				for (int k=0;k<noParticles;k++)
					j += (16<<(display[k]%3))*(display[k]/3==i);
				toQuadrant[i] <: j;
			}
		}

		if(input == PAUSED) {
			isPaused = true;
		} else if(input == TERMINATED) {
			int canFinish;
			for(int k = 0; k < noParticles;k++) {
				canFinish = canFinish & synced[k];
			}

			if(canFinish)
				running = false;
			continue;
		}
	}

	printf("Going to kill visualiser\n");
	for (int k=0;k<4;k++)
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
					waitMoment(BUTTONDELAY);
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
					waitMoment(BUTTONDELAY);
				}
				break;
			case buttonC:
				//HALT
				simulationStarted = false;
				toVisualiser <: TERMINATED;
				waitMoment(BUTTONDELAY);
				running = false;
				break;
			case buttonD:
				if(simulationStarted)
					waitMoment(BUTTONDELAY);
					//Thing
				else
					waitMoment(BUTTONDELAY);
					//BEFORE START - NUMBER OF PARTICLES
				break;
			default:
				break;
		}

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

	// Display start position
	toVisualiser <: startPosition;

	while(running) {

		select {
			case toVisualiser :> status:
				printf("%d Got a status changed selected %d\n", startPosition, status);
				break;
			default:
				break;
		}

		//printf("%d Got a status changed selected %d\n", startPosition, status);
		if(!started && status == RUNNING)
			started = true;

		if(status == TERMINATED && !started)
			break;

		if(!started) continue;

		select {
			case left :> leftMoveForbidden: {
				if(status == PAUSED) {
					left <: PAUSED;
				} else if(status == TERMINATED) {
					left <: TERMINATED;
				} else if(leftMoveForbidden == position) {
					left <: forbidden;
					toggleDirection(currentDirection);
				} else {
					left <: allowed;
				}
				break;
			}
			case right :> rightMoveForbidden: {

				if(status == PAUSED) {
					right <: PAUSED;
				} else if(status == TERMINATED) {
					right <: TERMINATED;
				} else if(rightMoveForbidden == position) {
					right <: forbidden;
					toggleDirection(currentDirection);
				} else {
					right <: allowed;
				}

				break;
			}
			default: {

				if(status == PAUSED || status == TERMINATED)
					break;

				attemptedPosition = getAttemptedPosition(currentDirection, position);

				if(currentDirection == CLKWISE) {

					// Ask
					left <: attemptedPosition;

					// Get answer
					left :> leftMoveForbidden;

					if(leftMoveForbidden == allowed) {
						position = attemptedPosition;

						// check if status changed
//						select {
//							case toVisualiser :> status:
//								break;
//							default:
//								break;
//						}

						if(status == RUNNING) {
							toVisualiser <: position;
							toVisualiser <: 1000;
							toVisualiser :> status;
							break;
						}

					} else if(leftMoveForbidden == PAUSED) {
						status = PAUSED;
						break;
					} else if(leftMoveForbidden == TERMINATED) {
						status = TERMINATED;
						break;
					} else {
						toggleDirection(currentDirection);
					}

				} else {

					right <: attemptedPosition;
					right :> rightMoveForbidden;

					if(rightMoveForbidden == allowed) {
						position = attemptedPosition;

						// check if status changed
					/*	select {
							case toVisualiser :> status:
								break;
							default:
								break;
						}*/

						if(status == RUNNING) {
							toVisualiser <: position;
							// synch
							toVisualiser <: 1000;
							toVisualiser :> status;
							break;
						}

					} else if(rightMoveForbidden == PAUSED) {
						status = PAUSED;
						break;
					} else if(rightMoveForbidden == TERMINATED) {
						status = TERMINATED;
						break;
					} else {
						toggleDirection(currentDirection);
					}
				}

				break;
			} // default
		} // select

		if(status == TERMINATED)
		{
			select {
				case left :> leftMoveForbidden:
					left <: TERMINATED;
					break;
				case right :> rightMoveForbidden:
					right <: TERMINATED;
					break;
				default:
					break;
			}
			running = false;
		}


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
