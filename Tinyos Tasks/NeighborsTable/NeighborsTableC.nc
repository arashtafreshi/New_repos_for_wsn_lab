#include "NeighborsTable.h"
#include <stdlib.h>
module NeighborsTableC {
	uses {
		interface Boot;
		interface Leds;
		interface Packet;
	}
	uses {
		interface AMSend as RadioSend;
		interface AMSend as BeaconSend;
		interface AMSend as SerialSend;
		
		interface Receive as RadioReceive;

		interface Receive as BeaconReceive;

		interface SplitControl as RadioControl; 
		interface SplitControl as SerialControl;
		
		interface CC2420Packet;
		
		interface Timer<TMilli> as BeaconTimer;
		interface Timer<TMilli> as RunningTimer;
		interface Timer<TMilli> as eachSec;
	}
}

implementation {

	bool _radioBusy=FALSE; 
	message_t _RadioSendPacket;
	message_t _BeaconSendPacket;

	NodeToNodeMsg_t* incomingPacket;
	NodeToNodeMsg_t* TempPacket;
	NodeToNodeMsg_t* _ReadDoneSend;
	
	BeaconMsg_t* _BeaconPacket;


	int16_t _tableCounter=0;
	int16_t _SourceID;
	int16_t Power=20;
	int16_t _neighburTable[20][3];
	int16_t _Neighbors = 0;
	int i=0;
	int16_t _LedNumber;
	int16_t _Counter=0;
	int16_t _Seq=0;
	int16_t _receivedFrom[20];
	int16_t _timerCounter = 0;
	int16_t _step = 0;
	int16_t _PacketCounter = 0;

	void initReceivedFrom(){
		for (i=0 ; i<20 ; i++){
			_receivedFrom[i]=0;
		}
	}

	bool isReceivedBefore(int ID){
		for (i=0 ; i<20 ; i++){
			
			if(_receivedFrom[i]==1){
				return TRUE;
			}	
		}
		return FALSE;
	}
	bool isNeighburExists(int ID)  {
		for ( i=0 ; i<_tableCounter ; i++) {
			if (_neighburTable[i][0] == ID)  {
				_neighburTable[i][1] = call RunningTimer.getNow();
				return TRUE;
			}
		}
		return FALSE;
	}

	void addToTable( int ID) {
		_neighburTable[_tableCounter][0] = ID; // set the ID of the new Node
		_neighburTable[_tableCounter][1] = call RunningTimer.getNow(); // set the arrival time of beacon
		_neighburTable[_tableCounter][2] = 0; // indecates number of times it packet received from this node
		_tableCounter++; // set for the position for the next new Node 
	}

	void sendNeighborsTable(){
		TempPacket=(NodeToNodeMsg_t *)( call Packet.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t)));
		for ( i=0 ; i<_tableCounter ; i++) {
			if (_neighburTable[i][0] != (-1))  {
				_Neighbors = (_step*10) + _neighburTable[i][0];
			}
		}

		_PacketCounter++;
		TempPacket->Counter=_PacketCounter;
		TempPacket->SourceID=TOS_NODE_ID;
		TempPacket->Neighbors=_Neighbors;
		TempPacket->DestID=0;

		call CC2420Packet.setPower(&_RadioSendPacket, Power);// Set the power of packet in runtime.
		//call Leds.led1On();
		if (call RadioSend.send(AM_BROADCAST_ADDR, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
			_radioBusy = TRUE;
		
		}

	}

	event void Boot.booted() {
		call RadioControl.start(); 
		call SerialControl.start();
	}

	event void RadioControl.startDone(error_t err) {    
		if (err == SUCCESS) { 
			call BeaconTimer.startPeriodic( 2000 );
			call eachSec.startPeriodic( 1000 );
			call RunningTimer.startOneShot(1);
			initReceivedFrom();
		}
		else {  
			call RadioControl.start();// Try to start it again if failed
		}
	}



	event void RadioSend.sendDone(message_t* msg, error_t error) {
		
		if ( &_RadioSendPacket == msg) {
			_radioBusy = FALSE;
		}
		
	}

	event void SerialSend.sendDone(message_t* msg, error_t error) {
		
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
					call Leds.led2Toggle();	
				}
			}
			else {
				post TBeaconSend();
			}
	}

	event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) { // SerialSend - RadioSend - Read
		if (len == sizeof(NodeToNodeMsg_t)) { 	
			//call Leds.led0On(); 
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			_Counter=incomingPacket->Counter;
			_SourceID=incomingPacket->SourceID;
			

			for ( i=0 ; i<_tableCounter ; i++) {
				if (_neighburTable[i][0] == _SourceID)  {
					if(_neighburTable[i][2] < _Counter){
						_neighburTable[i][2] = _Counter;
						TempPacket=(NodeToNodeMsg_t *)( call Packet.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t)));
						TempPacket->Counter=incomingPacket->Counter;
						TempPacket->SourceID=incomingPacket->SourceID;
						TempPacket->Neighbors=incomingPacket->Neighbors;
						TempPacket->DestID=incomingPacket->DestID;
						_Seq=_Counter;  

			
						if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID==0)  {
								call Leds.led0Toggle();
							if (call SerialSend.send(AM_BROADCAST_ADDR, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
								call Leds.led1Toggle();
							}
						}

						if (incomingPacket->DestID!=TOS_NODE_ID){
							//call Leds.led0On();
							if (_radioBusy==FALSE) {

								call CC2420Packet.setPower(&_RadioSendPacket, Power);// Set the power of packet in runtime.
								//call Leds.led1On();
								if (call RadioSend.send(AM_BROADCAST_ADDR, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
									_radioBusy = TRUE;
						
								}
							}
						}
					}
				}
			}
			
			
		}
		return msg;
	}
	event message_t * BeaconReceive.receive(message_t *msg, void *payload, uint8_t len){  
		//what motes do when they recieve Beacon message  
		if (len == sizeof(BeaconMsg_t))  {
		  	//call Leds.led2Toggle();
			_BeaconPacket = (BeaconMsg_t *)payload;
			if (isNeighburExists(_BeaconPacket->BeaconSenderID)==FALSE)  { // The received beacon refers to a Node which is not in the table yet and it is new
				addToTable(_BeaconPacket->BeaconSenderID); // adds the new Node to the Neighbur Table
				//call Leds.led2Toggle();
			}
		}
		return msg;
	}


	event void BeaconTimer.fired( ) { 
		//creating the packet phase
		post TBeaconSend();
	}

	event void eachSec.fired(){   	
		_timerCounter ++;
		for ( i=0; i<_tableCounter; i++){
			if ((call RunningTimer.getNow())-_neighburTable[i][1]>=5000 && _neighburTable[i][0] !=(-1))  { // If no beacon received in 15s from the node, then remove it from neighbur table
				_neighburTable[i][0]=-1;
				_neighburTable[i][1]=-1;
			}

			
		}

		if(_timerCounter == 10){
			
		}
	}
	event void RunningTimer.fired( ) {   
	}
}


