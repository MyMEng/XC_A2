///////////////////////////////////////////////////////////////////////////////////////// //
// COMS20600 - WEEKS 6 and 7
// ASSIGNMENT 2
// CODE SKELETON
// TITLE: "LED Particle Simulation"
// /////////////////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <platform.h>

//Ports definitions
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

//define true/false
#define true 1
#define false 0

//define directions
#define CLKWISE 1
#define ACLKWISE -1

// No of cores
#define maxCoreNo 3
#define numberOfCores 4

// Start position of n'th particle
const int startPositions[maxParticles] = {0, 3, 6, 8, 10};

// Start directions of n'th  particles
const int startDirections[maxParticles] = {ACLKWISE, CLKWISE, ACLKWISE, CLKWISE, ACLKWISE};

// Start speed of particles
const unsigned int speed[maxParticles] = {5, 13, 20, 31, 15};

//numbers that function pinsneq returns that correspond to buttons
#define buttonA 14
#define buttonB 13
#define buttonC 11
#define buttonD 7

//define flags to control simulation
enum {
	NOTSTARTED = 20,
	RUNNING = 21,
	PAUSED = 22,
	TERMINATED = 23,
	COLLISION = 30,
	KILL = 66,
	MOVE_LEFT = 70,
	MOVE_RIGHT = 71,
	NEXT_PARTICLE = 72
};

//Particle max speed setting
#define MAXPARTICLESPEED 275000

// Delay buttons so you can click on them a bit 'slower'
#define BUTTONDELAY 3200000

////////////////////////////////////////////////////////////////////////////////////////////
// Helper Functions provided for you
////////////////////////////////////////////////////////////////////////////////////////////

//send pattern to LEDs
//DISPLAYS an LED pattern in one quadrant of the clock LEDs
void showLED(out port p, chanend fromVisualiser) {
	unsigned int lightUpPattern;
	unsigned int running = 1;
	while (running) {
		select {
			case fromVisualiser :> lightUpPattern: {
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
}

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

	// Currently 'edited' particle
	int part = 0;

	// Attempted position in 'edit' mode
	int attempted;

	// Info about start position that might be sent to a particle
	int info = 0;

	// Input from buttons
	int input = NOTSTARTED;

	// Has simulation started
	int started = false;

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

		// If not running, set up particle position
		switch(input) {
			case MOVE_LEFT:
				// Move current particle to the left
				attempted = display[part] + 1;

				// Move by two or more if positions are taken
				while(true) {
					int next = false;
					if(attempted == -1) {
						attempted = 11;
					} else if(attempted == 12) {
						attempted = 0;
					}

					for(int i = 0; i < noParticles; i++) {
						if(display[i] == attempted) {
							next = true;
							attempted++;
							break;
						}
					}
					if(next) continue;
					break;
				}

				display[part] = attempted;

				input = NOTSTARTED;
				continue;
				break;
			case MOVE_RIGHT:
				// Move current particle to the right

				attempted = display[part] - 1;

				while(true) {
					int next = false;
					if(attempted == -1) {
						attempted = 11;
					} else if(attempted == 12) {
						attempted = 0;
					}

					for(int i = 0; i < noParticles; i++) {
						if(display[i] == attempted) {
							next = true;
							attempted--;
							continue;
						}
					}
					if(next) continue;
					break;
				}
				display[part] = attempted;
				input = NOTSTARTED;
				continue;
				break;
			case NEXT_PARTICLE:
				// Send to particle
				info = display[part];
				info = info << 8;

				// Add an id
				info += 33;

				// Send to particle
				show[part] <: info;

				// Change particle
				part++;
				if(part >= noParticles)
					part = 0;
				// Reset input
				input = NOTSTARTED;
				continue;
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
				running = false;
				continue;
			}
		}

		//waitMoment(particleSpeed());
		waitMoment(MAXPARTICLESPEED);

		// Let particles know that simulation has started
		if(!started && input == RUNNING) {
			started = true;
			for(int i = 0; i < noParticles; i++) {
				show[i] <: RUNNING;
			}
			continue;
		}

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
										//play sound on collision
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
							if(input != TERMINATED){
								show[k] <: result;
							}else {
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
		cledG <: input == PAUSED || input == NOTSTARTED;
		cledR <: input != PAUSED && input != NOTSTARTED;

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

		if(input == TERMINATED)
		{
			running = false;
		}
	}

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

		//////////////////////////////////////////////////////////////////////////
		// ADD YOUR CODE HERE TO ACT ON BUTTON INPUT
		//////////////////////////////////////////////////////////////////////////

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
				else {
					toVisualiser <: MOVE_LEFT;
				}
				break;
			case buttonC:
				//HALT
				if(simulationStarted) {
					simulationStarted = false;
					simulationPaused = false;
					toVisualiser <: TERMINATED;
					running = false;
				} else {
					toVisualiser <: MOVE_RIGHT;
				}
				break;
			case buttonD:
				if(!simulationStarted) {
					toVisualiser <: NEXT_PARTICLE;
				}

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

	// Used to check if information from visualiser is initial position
	int info;

	// Has simulation started?
	int started = false;

	// Display start position
	toVisualiser <: startPosition;

	isMaster = startPositions[0] == startPosition;

	while(!started) {
		select {
			case toVisualiser :> info:
				if(info == RUNNING) {
					started = true;
					status = RUNNING;
					break;
				} else if(info == TERMINATED) {
					started = true;
					running = false;
					break;
				}
				else if((info & 0xFF) == 33) {
					position = (info >> 8);
					break;
				}
			break;
			default:
				break;
		}

	}

	if(isMaster)
	{
		right <: status;
	}

	while(running) {

		int waitForUpdate = true;

		// Pass status to the left
		while(waitForUpdate) {
			select {
				case right :> status:
					waitForUpdate = false;
					if(kills == false) {
						// not a killer, pass it
						left <: status;
					}
					running = false;
					break;
				case left :> status:
					waitForUpdate = false;
					break;
				case toVisualiser :> status:

					if(status == COLLISION) {
						toggleDirection(currentDirection);
					}

					if(status == TERMINATED) {
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
					break;
			}
		}

		if(status == TERMINATED) {
			// Do nothing...
		} else if(status == COLLISION) {
			toggleDirection(currentDirection);

		} else if(status == RUNNING) {

			if(skip > 0) {
				skip--;
			} else {
				skip = startVelocity;

				attemptedPosition = getAttemptedPosition(currentDirection, position);

				toVisualiser <: (attemptedPosition + 1000);

				toVisualiser :> rightMoveForbidden;

				if(rightMoveForbidden == TERMINATED) {
					status = TERMINATED;
				}
				else if(rightMoveForbidden == allowed)
					position = attemptedPosition;
				else
				{
					if(currentDirection == CLKWISE) {

					} else  {

					}
					toggleDirection(currentDirection);
				}


			}

		}


		// Read status from right
		if(status == TERMINATED)
		{
			kills = true;
			left <: TERMINATED;
			continue;
		}

		right <: status;
	}
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

		//VISUALISER THREAD
		on stdcore[0]: visualiser(buttonToVisualiser, show, quadrant, speaker);

		//REPLICATION FOR THREADS PERFORMING LED VISUALISATION
		par (int k=0; k<numberOfCores; k++) {
			on stdcore[k%numberOfCores]: showLED(cled[k],quadrant[k]);
		}
	}
	return 0;
}
