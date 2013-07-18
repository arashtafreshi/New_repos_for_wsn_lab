#include "Task3.h"
#include <stdlib.h>
module Task3C {
	uses {
		interface Boot;
		interface Leds;
		interface Packet;
	}
	uses {

		interface AMSend as BeaconSend;
		interface Receive as BeaconReceive;

		interface SplitControl as RadioControl; 
		interface SplitControl as SerialControl;
		
		interface CC2420Packet;

		
		interface Timer<TMilli> as BeaconTimer;

	}
}

implementation {

	bool _radioBusy=FALSE; 


	message_t _BeaconSendPacket;
	BeaconMsg_t* _BeaconPacket;

	int16_t _SourceID;
	int16_t Power=20;

	int i=0;
	int16_t _LedNumber;
	int16_t _Counter=0;
	int16_t _Seq=0;
	

	event void Boot.booted() {
		call RadioControl.start(); 
		call SerialControl.start();
	}

	event void RadioControl.startDone(error_t err) {    
		if (err == SUCCESS) { 
			call BeaconTimer.startPeriodic( 7000 );
		}
		else {  
			call RadioControl.start();// Try to start it again if failed
		}
	}


	event void BeaconSend.sendDone(message_t* msg, error_t error) {
		if (&_BeaconSendPacket == msg) {
			_radioBusy = FALSE;
		}
	}
	event void SerialControl.startDone(error_t err) {	
		if (err == SUCCESS) {
			
		}
		else {
			call SerialControl.start();
		}
	}
	event void SerialControl.stopDone(error_t err) {

	}
	event void RadioControl.stopDone(error_t err) {

	}


	task void TBeaconSend() {
			//setting the payloads of the beacon packet
			_BeaconPacket=(BeaconMsg_t *)( call Packet.getPayload(&_BeaconSendPacket,sizeof(BeaconMsg_t)));  	
			_BeaconPacket->BeaconSenderID=TOS_NODE_ID;// Its Node ID as Beacon sender
			if (_radioBusy==FALSE) {
				call CC2420Packet.setPower( &_BeaconSendPacket, Power);
				if (call BeaconSend.send(AM_BROADCAST_ADDR,  &_BeaconSendPacket, sizeof(BeaconMsg_t))== SUCCESS) {
					_radioBusy = TRUE;
					call Leds.led1Toggle();	
				}
			}
			else {
				post TBeaconSend();
			}
	}


	event message_t * BeaconReceive.receive(message_t *msg, void *payload, uint8_t len){  
		//what motes do when they recieve Beacon message  
		if (len == sizeof(BeaconMsg_t))  {
		  	call Leds.led2Toggle();


		}
		return msg;
	}
	

	event void BeaconTimer.fired( ) { 
		//creating the packet phase
		post TBeaconSend();
	}


}


