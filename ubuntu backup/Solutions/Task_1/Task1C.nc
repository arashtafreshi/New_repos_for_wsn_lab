#include <Timer.h>
#include "Task1.h"// the difference between <> and "" is that <> means the define one but"" means theone that we created
module Task1C
{
	// General Interfaces
	uses
	{
		interface Boot;
		interface Leds;
	}
	
	uses interface Timer<TMilli> as Timer0;
	
	//Radio Interfaces
	uses
	{
		interface Packet;// allow us to work with packet and extract data
		interface AMPacket;//special packet
		interface AMSend;// allow us to send active message types
		interface SplitControl as AMControl; // allow us to do some basic data extraction
		interface Receive;
	}	
}

implementation
{
	
	bool _radioBusy=FALSE;// store the state of Radio Chip - we check if Radio is busy then we wait
	NodeToNodeMsg_t* _Packet; // 
	int16_t _LedNumber;
	int16_t _Counter=0;
	int16_t _Seq=0;
	uint16_t  Data=0;
	NodeToNodeMsg_t* incomingPacket;
	
	event void Boot.booted()
	{
		//counter == 0;
		//
		dbg("Boot", "Application booted.\n");//debug message when it boots
		call AMControl.start();//we need to start Splitcontrol
		
	}
	
	// we write this to make sure that AMCONTROL star
	event void AMControl.startDone(error_t err) 
	{
		// means that we have no error
		if (err == SUCCESS) 
		{
			if (TOS_NODE_ID ==0)
			{
				call Timer0.startPeriodic(10000);
			}
		}
		else
		{
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err)
	{
	}

	event void AMSend.sendDone(message_t* msg, error_t error)
	{
		// If the mgs and our packet are the same size then it means that the radio is not busy more and it sent.
		if (&_Packet == msg)
		{
			_radioBusy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) 
	{
		dbg("RadioCountToLedsC", "Received packet of length %hhu.\n", len);
		
		//check the packet whether this is for us or not
		if (len == sizeof(NodeToNodeMsg_t)) 
		{ 
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			_Counter=incomingPacket->Counter;
			if (_Counter >_Seq)
			{
				_Seq=_Counter;				    
				Data= incomingPacket->Data;
				// call Leds.set(msg->counter);

				if (Data == 0) {
					call Leds.led0On();
				}
				else {
					call Leds.led0Off();
				}
				if (Data == 1) {
					call Leds.led1On();
				}
				else {
					call Leds.led1Off();
				}
				if (Data == 2) {
					call Leds.led2On();
				}
				else {
					call Leds.led2Off();
				}
				
				if (call AMSend.send(AM_BROADCAST_ADDR, & msg, sizeof(NodeToNodeMsg_t))== SUCCESS)
				{
					_radioBusy = TRUE;
				}
			}
		}
		//return msg;
		
	}
	
	event void Timer0.fired( )
	{   	

		//creating the packet
		if (_radioBusy==FALSE)
		{
			_Packet=call Packet.getPayload(&_Packet,sizeof(NodeToNodeMsg_t));//Sizeof use for check whether the packet is the one that we expected or not  	
			//getPayLoad means we recieve a packet
			
			_Packet->NodeID=TOS_NODE_ID;// Node iD of the sensor board which assign by itself
			_LedNumber = rand() % 3; //Generating random LED number
			_Packet->Data= _LedNumber; //i=random();)random function ra run konad
			_Packet->Counter=_Seq++;
			//set Leds
			if (_LedNumber == 0) {
				call Leds.led0On();
			}
			else {
				call Leds.led0Off();
			}
			if (_LedNumber == 1) {
				call Leds.led1On();
			}
			else {
				call Leds.led1Off();
			}
			if (_LedNumber == 2) {
				call Leds.led2On();
			}
			else {
				call Leds.led2Off();
			}
		}
		//sending the packet
		if (call AMSend.send(AM_BROADCAST_ADDR, & _Packet, sizeof(NodeToNodeMsg_t))== SUCCESS)
		{
			_radioBusy = TRUE;
		}
	}
	

}


