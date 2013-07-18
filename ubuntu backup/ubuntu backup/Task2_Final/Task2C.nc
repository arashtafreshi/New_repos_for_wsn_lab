

#include "Task2.h"// the difference between <> and "" is that <> means the define one but"" means theone that we created
#include <stdlib.h>
module Task2C

{

	// General Interfaces

	uses

	{
		interface Boot;
		interface Leds;
	}

	// Timer



	//Radio Interfaces
	uses
	{
		
		interface AMSend;// allow us to send active message types
		interface SplitControl as RadioControl; // allow us to do some basic data extraction
		interface SplitControl as SerialControl;
		interface Receive as RadioReceive;
		interface Receive as SerialReceive;
		interface CC2420Packet;
	}	
}



implementation
{
	// Variables
	bool _radioBusy=FALSE;      // store the state of Radio Chip - we check if Radio is busy then we wait
	message_t _Packet; //
	int16_t _LedNumber;
	int16_t _Counter=0;
	int16_t _Seq=0;
	uint16_t  Data=0;
	NodeToNodeMsg_t* incomingPacket;
	NodeToNodeMsg_t* _content;
	int16_t Power;

	// Method For toggle LEDs
	void setLed(int i)  {

		dbg("Alert", "Toggle LED Number %hhu.\n",i);
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

	// Boot WSNs
	event void Boot.booted()
	{
		// Show Booted Node
		dbg("Boot", "This node booted\n");
		//we need to start Split control in all nodes
		call RadioControl.start();
		call SerialControl.start();
	}


	// Make sure That AMComntrol started
	event void RadioControl.startDone(error_t err) 
	{
		// SUCCESS: There is no error
		if (err == SUCCESS) 
		{
			// Only the Node(0) should start the timer

		}
		else
		{
			// Try to start it again if failed
			call RadioControl.start();
		}
	}


	// rwpresents whether the packet sent or not and it is desired one
	event void AMSend.sendDone(message_t* msg, error_t error)
	{
		// msg is the message buffer sent
		// If the sent Packet and the intended Packet (_Packet) have the same size then 
		// the radio is not busy any more.
		if (&_Packet == msg)
		{
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
	event void RadioControl.stopDone(error_t err)

	{

	}


	event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) 
	{
		
		
		//check whether this Pcket is for us or not
		if (len == sizeof(NodeToNodeMsg_t)) 
		{ 
			//Extract Payload
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			_Counter=incomingPacket->Counter;
			// check whether the Packet is new or old, if it is new (just receive the new one)
			if (_Counter >_Seq)
			{
				if (incomingPacket->DestID==TOS_NODE_ID){
				_Seq=_Counter;				    
				_LedNumber= incomingPacket->ledToToggle;
				dbg("Alert", "Received packet with sequence No.  %hhu.\n", _Seq);
				// Set LEDs
				setLed(_LedNumber);
				}
				// Now it's time to forward the Packet to neighbors
				else{
					call CC2420Packet.setPower(msg, Power);
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(NodeToNodeMsg_t))== SUCCESS)
					{
						// it is busy now
						_radioBusy = TRUE;
					}
				}
			}
		}
		return msg;
	}
	

	event message_t* SerialReceive.receive(message_t* msg, void* payload, uint8_t len) 
	{
		
		
		//check whether this Pcket is for us or not
		if (len == sizeof(NodeToNodeMsg_t)) 
		{ 
			//Extract Payload
			_Counter++;
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			incomingPacket->Counter=_Counter;
			// check whether the Packet is new or old, if it is new (just receive the new one)
			_Seq=_Counter;
				if (incomingPacket->DestID==TOS_NODE_ID){
				    
				_LedNumber= incomingPacket->ledToToggle;
				dbg("Alert", "Received packet with sequence No.  %hhu.\n", _Seq);
				// Set LEDs
				setLed(_LedNumber);
				}
				// Now it's time to forward the Packet to neighbors
				else{
					call CC2420Packet.setPower(msg, Power);
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(NodeToNodeMsg_t))== SUCCESS)
					{
						// it is busy now
						_radioBusy = TRUE;
					}
				}
			
		}
		return msg;
	}



}




