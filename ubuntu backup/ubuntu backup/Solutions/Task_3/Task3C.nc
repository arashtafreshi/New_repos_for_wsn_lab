#include "Task3.h"
#include <stdlib.h>
module Task3C {
	uses {
		interface Boot;
		interface Leds;
		interface Packet;
	}
	uses {
		interface AMSend as RadioSend;
		interface AMSend as BeaconSend;
		interface AMSend as AckSend;
		interface AMSend as SerialSend;
		
		interface Receive as RadioReceive;
		interface Receive as SerialReceive;
		interface Receive as AckReceive;
		interface Receive as BeaconReceive;

		interface SplitControl as RadioControl; 
		interface SplitControl as SerialControl;
		
		interface CC2420Packet;
		interface Read<uint16_t>;
		
		interface Timer<TMilli> as BeaconTimer;
		interface Timer<TMilli> as RunningTimer;
		interface Timer<TMilli> as eachSec;
	}
}

implementation {

	bool _radioBusy=FALSE; 
	message_t _RadioSendPacket;
	message_t _ReSendPacket;
	message_t _ReadDoneSendPacket;
	message_t _AckSendPacket;
	message_t _BeaconSendPacket;

	NodeToNodeMsg_t* incomingPacket;
	NodeToNodeMsg_t* TempPacket;
	NodeToNodeMsg_t* _ReSend;
	NodeToNodeMsg_t* _ReadDoneSend;
	
	BeaconMsg_t* _BeaconPacket;
	AckMsg_t* _AckPacket;

	int16_t _tableCounter=0;
	int16_t _SourceID;
	int16_t Power=20;
	int16_t _neighburTable[20][20];
	int16_t _Temperature;
	int i=0;
	int16_t _LedNumber;
	int16_t _Counter=0;
	int16_t _Seq=0;
	

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
		_neighburTable[_tableCounter][2] = 0; // set the ack sign for new Node. It is 0 because no packet sent to this node yet.
		_neighburTable[_tableCounter][3] = 0; // set ack to 0 which means no ack expected to receive from this node
		_tableCounter++; // set for the position for the next new Node 
	}

	void setAckInTable(int NodeID, int AckFlag){ 
		for ( i=0 ; i<_tableCounter ; i++) {
			if (_neighburTable[i][0] == NodeID) {
				_neighburTable[_tableCounter][3] =AckFlag;
			}
		}
	}

	event void Boot.booted() {
		call RadioControl.start(); 
		call SerialControl.start();
	}

	event void RadioControl.startDone(error_t err) {    
		if (err == SUCCESS) { 
			call BeaconTimer.startPeriodic( 7000 );
			call eachSec.startPeriodic( 1000 );
			call RunningTimer.startOneShot(1);
		}
		else {  
			call RadioControl.start();// Try to start it again if failed
		}
	}

	event void Read.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS){
			
			_Temperature=data;
			_ReadDoneSend=(NodeToNodeMsg_t *)( call Packet.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t)));  	
			_ReadDoneSend->Counter=_Seq++;
			_ReadDoneSend->Temperature=_Temperature;
			_ReadDoneSend->SourceID=TOS_NODE_ID;
			call CC2420Packet.setPower( &_RadioSendPacket, Power);
			
			if (incomingPacket->DestID!=0) {
				
				if (_radioBusy==FALSE) {

					_ReadDoneSend->DestID=0;
					
					if (call RadioSend.send(AM_BROADCAST_ADDR, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
						call Leds.led1Toggle();					
						_radioBusy = TRUE;
						
						for ( i=0 ; i<_tableCounter ; i++) { // Set AckFlag to 1 for all neighbors in table
							if (_neighburTable[i][0] >=0) {
								setAckInTable(_neighburTable[i][0],1);
							}
						}
					}
				}
			}
			else  {
				call SerialSend.send(AM_BROADCAST_ADDR, &_RadioSendPacket, sizeof(NodeToNodeMsg_t));	
			}			
		}
	}

	event void RadioSend.sendDone(message_t* msg, error_t error) {
		
		if ( &_RadioSendPacket == msg) {
			_radioBusy = FALSE;
		}
		
	}

	event void SerialSend.sendDone(message_t* msg, error_t error) {
		
	}
	event void AckSend.sendDone(message_t* msg, error_t error) {
		//call Leds.led2On();
		if (&_AckSendPacket == msg) {
			_radioBusy = FALSE;
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
	task void Acksend() {
		
		//setting the payloads of the beacon packet
		_AckPacket=(AckMsg_t *)( call Packet.getPayload(&_AckSendPacket,sizeof(AckMsg_t)));  
		_AckPacket->AckSenderID=TOS_NODE_ID;	
		if (_radioBusy==FALSE) {
			//sending the packet phase
			call CC2420Packet.setPower( &_AckSendPacket, Power);
			if (call AckSend.send(_SourceID,  &_AckSendPacket, sizeof(AckMsg_t))== SUCCESS) {
				_radioBusy = TRUE;
			}
		}
		else {
			post Acksend();
		}
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
			post Acksend();
			
			if (_Counter >_Seq) {// check whether the Packet is new or old

				TempPacket=(NodeToNodeMsg_t *)( call Packet.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t)));
				TempPacket->Counter=incomingPacket->Counter;
				TempPacket->SourceID=incomingPacket->SourceID;
				TempPacket->Temperature=incomingPacket->Temperature;
				TempPacket->DestID=incomingPacket->DestID;
				_Seq=_Counter;  

				if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID!=0){ 
					call Leds.led0Toggle();
					call Read.read();// read codes
				}
				
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
							
							//call Leds.led1Toggle();
							for ( i=0 ; i<_tableCounter ; i++) { // Set AckFlag to 1 for all neighbors in table
								if (_neighburTable[i][0] >=0) {
									setAckInTable(_neighburTable[i][0],1);
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
	event message_t * AckReceive.receive(message_t *msg, void *payload, uint8_t len){ 
		//_BeaconSendPacket
		if (len == sizeof(AckMsg_t)) {
			_AckPacket = (AckMsg_t *)payload;
			setAckInTable (_AckPacket->AckSenderID,0);
		}
		return msg;
	}
	event message_t* SerialReceive.receive(message_t* msg, void* payload, uint8_t len) {  
		//What Node does while it recives packet from Serial
		if (len == sizeof(NodeToNodeMsg_t)) { 
			//call Leds.led1On();
			_Seq++;
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			incomingPacket->Counter=_Seq;
	
			TempPacket=(NodeToNodeMsg_t *)( call Packet.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t)));
			TempPacket->Counter=incomingPacket->Counter;
			TempPacket->SourceID=incomingPacket->SourceID;
			TempPacket->DestID=incomingPacket->DestID;
			if (incomingPacket->DestID==TOS_NODE_ID) {
				
				call Read.read();
			}
			else {
				//call Leds.led1On();
				//Set power of the packet to send
				if (_radioBusy==FALSE) {
					call Leds.led2Toggle();
					call CC2420Packet.setPower(&_RadioSendPacket, Power);
					if (call RadioSend.send(AM_BROADCAST_ADDR, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) { //******************* Problem!!!
						_radioBusy = TRUE;
						for ( i=0 ; i<_tableCounter ; i++) { // Set AckFlag to 1 for all neighbors in table
							if (_neighburTable[i][0] >=0) {
								setAckInTable(_neighburTable[i][0],1);
							}
						}
					}
				}
			}
			
		}
		return msg;
	}
	event void BeaconTimer.fired( ) { 
		//creating the packet phase
		post TBeaconSend();
	}
	event void eachSec.fired(){   	
		for ( i=0; i<_tableCounter; i++){
			if ((call RunningTimer.getNow())-_neighburTable[i][1]>=15000 && _neighburTable[i][0] !=(-1))  { // If no beacon received in 15s from the node, then remove it from neighbur table
				_neighburTable[i][0]=-1;
				_neighburTable[i][1]=-1;
				_neighburTable[i][2]=-1;
				_neighburTable[i][3]=0;
			}
			if ((call RunningTimer.getNow())-_neighburTable[i][2]>=5000 && _neighburTable[i][3] ==1 && _neighburTable[i][0] !=(-1))  { //if it expects the ack and didn't receive it in last 5s, then send command again
				if (_radioBusy==FALSE)
				{
					call CC2420Packet.setPower( &_RadioSendPacket, Power);
					if (call RadioSend.send(_neighburTable[i][0],  &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
						setAckInTable(_neighburTable[i][0],1);
						_radioBusy = TRUE;
						//call Leds.led2Toggle();
					}
				}
				_neighburTable[i][2]=(call RunningTimer.getNow()); // set the sent time; 
			}
			
		}
	}
	event void RunningTimer.fired( ) {   
	}
}


