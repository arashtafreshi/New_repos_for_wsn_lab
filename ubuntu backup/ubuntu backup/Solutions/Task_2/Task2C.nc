#include "Task2.h"
#include <stdlib.h>
module Task2C {
	// General Interfaces
	uses {
		interface Boot;
		interface Leds;
	}
	//Radio and Serial Interfaces
	uses {
		interface AMSend;
		interface SplitControl as RadioControl; 
		interface SplitControl as SerialControl;
		interface Receive as RadioReceive;
		interface Receive as SerialReceive;
		interface CC2420Packet;
	}	
}

implementation {
	
	bool _radioBusy=FALSE; 
	message_t _Packet;
	int16_t _LedNumber;
	int16_t _Counter=0;
	int16_t _Seq=0;
	NodeToNodeMsg_t* incomingPacket;
	NodeToNodeMsg_t* _content;
	int16_t Power=2;

	// Method For toggle LEDs
	void setLed(int i) {
	
		if (i == 0) {
			call Leds.led0On();
		}
		else {
			call Leds.led0Off();
		}
		if (i == 1) {
			call Leds.led1On();
		}
		else {
			call Leds.led1Off();
		}
		if (i == 2) {
			call Leds.led2On();
		}
		else {
			call Leds.led2Off();
		}
	}
	
	event void Boot.booted() {

		call RadioControl.start(); // start Radio communication 
		call SerialControl.start();// start Serial communication
	}

	event void RadioControl.startDone(error_t err) {		
	
		if (err == SUCCESS) { // SUCCESS: There is no error
	
		}
		else {	
			call RadioControl.start();// Try to start it again if failed
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
	
		if (&_Packet == msg) {
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

	event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) { 
		//What motes do while they recive packet in radio
		if (len == sizeof(NodeToNodeMsg_t)) { 
		
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			_Counter=incomingPacket->Counter;
			
			if (_Counter >_Seq) {// check whether the Packet is new or old
		
				_Seq=_Counter;	
				if (incomingPacket->DestID==TOS_NODE_ID){			    
					_LedNumber= incomingPacket->ledToToggle;
					setLed(_LedNumber);
				}
				else {
				
					call CC2420Packet.setPower(msg, Power);// Set the power of packet in runtime.
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(NodeToNodeMsg_t))== SUCCESS) {
						_radioBusy = TRUE;
					}
				}
			}
		}
		return msg;
	}
	
	event message_t* SerialReceive.receive(message_t* msg, void* payload, uint8_t len) {
		//What mote 0 do while it recive packet in radio
		if (len == sizeof(NodeToNodeMsg_t)) { 
			
			_Seq++;
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			incomingPacket->Counter=_Seq;
			
			if (incomingPacket->DestID==TOS_NODE_ID) {
			
				_LedNumber= incomingPacket->ledToToggle;
				setLed(_LedNumber);
			
			}
			else {
				//Set the power of packet to send
				call CC2420Packet.setPower(msg, Power);
				if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(NodeToNodeMsg_t))== SUCCESS) {
					
					_radioBusy = TRUE;
				
				}
			}
			
		}
		return msg;
	}
}




