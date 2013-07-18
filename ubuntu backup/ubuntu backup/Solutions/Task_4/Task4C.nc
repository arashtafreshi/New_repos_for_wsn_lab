#include "Task4.h"
#include <stdlib.h>
module Task4C {
	uses {
		interface Boot;
		interface Leds;
	}
	uses {
		interface AMSend as RadioSend;
		interface AMSend as BeaconSend;
		interface AMSend as SerialSend;
		
		interface Receive as RadioReceive;
		interface Receive as SerialReceive;
		interface Receive as BeaconReceive;
		
		interface SplitControl as RadioControl; 
		interface SplitControl as SerialControl;
		
		interface CC2420Packet;
		interface Read<uint16_t>;
		
		interface Timer<TMilli> as BeaconTimer;
		interface Timer<TMilli> as RunningTimer;
		interface Timer<TMilli> as eachSec;
		
		//Interface for Ack
		interface PacketAcknowledgements;
	}
}

implementation {
	
	bool _radioBusy=FALSE; 
	message_t _RadioSendPacket;
	message_t _AckSendPacket;
	message_t _BeaconSendPacket;
	message_t _SerialSendPacket;
	
	NodeToNodeMsg_t buffer;
	
	NodeToNodeMsg_t* TempPacket;
	NodeToNodeMsg_t* incomingPacket;
	BeaconMsg_t* _BeaconPacket;
	NodeToNodeMsg_t* _ReSend;
	
	uint16_t _tableCounter=0;
	uint16_t _SourceID;
	uint16_t Power=20;
	uint16_t _neighburTable[20][20];
	uint16_t _Temperature;
	int i=0;
	uint16_t _LedNumber;
	uint16_t _Counter=0;
	uint16_t _Seq=0;
	
	uint16_t _Rssi;
	uint16_t _ParentNodeID=-1;//-1 means that it does not have any parent yet.
	uint16_t _TOS_NODE_Eetx=VERY_LARGE_EETX_VALUE;//Save Eetx of current node 
	uint16_t _Parent;
	
	task void Serialmsgsend();
	task void Radiomsgsend();
	task void Radiomsgsendtosource();
	
    uint16_t SelectParent(void) {
		//Search and select Best option(lowest EETX) in nodes which has good RSSI
		uint16_t _MinEetx=VERY_LARGE_EETX_VALUE;
		for ( i=0 ; i<_tableCounter ; i++) {
			if (_neighburTable[i][2] > RSSI_THRESHOLD) {//if RSSI of the recieved beacon is bigger than threshold
				if (_neighburTable[i][3] < _MinEetx )  {//in order to find the MInEetx among our neighbours
					if(_neighburTable[i][5] == 0) {// if Node is not my child! to avoid loop in tree
						_MinEetx=_neighburTable[i][3] ;
						_ParentNodeID=_neighburTable[i][0] ;
					}
				}
			}
		}
		return _ParentNodeID;	
	}
	uint16_t ComputeEETX(void) {
		uint16_t _ParentEetx=VERY_LARGE_EETX_VALUE;
		if (TOS_NODE_ID==0) {
			_TOS_NODE_Eetx=0;
		}
		if (TOS_NODE_ID!=0) {
			_Parent=SelectParent();
			for ( i=0 ; i<_tableCounter ; i++) {
				if (_neighburTable[i][0]== _Parent )  {
					_ParentEetx=_neighburTable[i][3] ;
				}
			}
			_TOS_NODE_Eetx = _ParentEetx + 1;
		}
		return _TOS_NODE_Eetx;
	}
	bool isNeighburExists(int ID,uint16_t Rssi,uint16_t Eetx,uint16_t Parent)  {
		for ( i=0 ; i<_tableCounter ; i++) {
			if (_neighburTable[i][0] == ID) {
				_neighburTable[i][1] = call RunningTimer.getNow();
				_neighburTable[_tableCounter][2] = Rssi;// add recieved Rssi to the array
				_neighburTable[_tableCounter][3] = Eetx;//
				_neighburTable[_tableCounter][4] = Parent;
				if (Parent==TOS_NODE_ID && _neighburTable[_tableCounter][5]==0){
					_neighburTable[_tableCounter][5] = 1;
				}
				if (Parent!=TOS_NODE_ID && _neighburTable[_tableCounter][5]==1) {
					_neighburTable[_tableCounter][5]=0;
				}
				return TRUE;
			}
		}
		return FALSE;
	}
	void addToTable( int ID,uint16_t Rssi,uint16_t Eetx,uint16_t Parent) {
		_neighburTable[_tableCounter][0] = ID; // set the ID of the new Node
		_neighburTable[_tableCounter][1] = call RunningTimer.getNow(); // set the arrival time of beacon
		_neighburTable[_tableCounter][2] = Rssi;// add recieved Rssi to the array
		_neighburTable[_tableCounter][3] = Eetx;//
		_neighburTable[_tableCounter][4] = Parent;//set the parent of recieved node.
		//Start to set our children
		if (Parent==TOS_NODE_ID){
			_neighburTable[_tableCounter][5] = 1;
		}
		else {
			_neighburTable[_tableCounter][5] = 0;// if it is this is my child it beacome 1 
		}
		_tableCounter++; // set for the position for the next new Node 
	}
	task void TBeaconSend() {
		//setting the payloads of the beacon packet
		_BeaconPacket=(BeaconMsg_t *)( call BeaconSend.getPayload(&_BeaconSendPacket,sizeof(BeaconMsg_t)));  	
		_BeaconPacket->BeaconSenderID=TOS_NODE_ID;// Its Node ID as Beacon sender
		_BeaconPacket->Parent=SelectParent();//Set the parent of the node befor send beacon
		_BeaconPacket->Eetx=ComputeEETX();//Set the eetx of the node befor sending beacon++++++++++++++++++++++++++++
		if (_radioBusy==FALSE) {
			call CC2420Packet.setPower( &_BeaconSendPacket, Power);
			if (call BeaconSend.send(AM_BROADCAST_ADDR,  &_BeaconSendPacket, sizeof(BeaconMsg_t))== SUCCESS) {
				_radioBusy = TRUE;
				//call Leds.led1Toggle();	
			}
		}
		else {
			post TBeaconSend();
		}
	}	
	task void Radiomsgsend(){
		if (_radioBusy==FALSE) {
			TempPacket=(NodeToNodeMsg_t *)( call RadioSend.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t)));
			TempPacket->Counter=buffer.Counter;
			TempPacket->SourceID=buffer.SourceID;
			TempPacket->DestID=buffer.DestID;
			TempPacket->Temperature=buffer.Temperature;
			call CC2420Packet.setPower( &_RadioSendPacket, Power);
			if (call RadioSend.send(AM_BROADCAST_ADDR, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
				//call Leds.led1Toggle();					
				_radioBusy = TRUE;
			} else {
				post Radiomsgsend();
			}
		} else {
			post Radiomsgsend();
		}
	}
	task void Radiomsgsendtosource(){
		if (_radioBusy==FALSE) {
			TempPacket=(NodeToNodeMsg_t *)( call RadioSend.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t)));
			TempPacket->Counter=buffer.Counter;
			TempPacket->SourceID=buffer.SourceID;
			TempPacket->DestID=buffer.DestID;
			TempPacket->Temperature=buffer.Temperature;
			_Parent=SelectParent();
			call CC2420Packet.setPower( &_RadioSendPacket, Power);
			call PacketAcknowledgements.requestAck(&_RadioSendPacket);	
			if (call RadioSend.send(_Parent, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
				call Leds.led1Toggle();					
				_radioBusy = TRUE;
				} else {
				post Radiomsgsendtosource();
			}
			} else {
			post Radiomsgsendtosource();
		}
	}
    task void Serialmsgsend(){
		TempPacket=(NodeToNodeMsg_t *)( call SerialSend.getPayload(&_SerialSendPacket,sizeof(NodeToNodeMsg_t)));
		TempPacket->Counter=buffer.Counter;
		TempPacket->SourceID=buffer.SourceID;
		TempPacket->DestID=buffer.DestID;
		TempPacket->Temperature=buffer.Temperature;
		call SerialSend.send(AM_BROADCAST_ADDR, &_SerialSendPacket, sizeof(NodeToNodeMsg_t));	
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
		}
		else {  
			call RadioControl.start();// Try to start it again if failed
		}
	}
	event void Read.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS){
			_Seq++;
			_Temperature=data;
			buffer.Counter=_Seq;
			buffer.Temperature=_Temperature;
			buffer.SourceID=TOS_NODE_ID;
			buffer.DestID=0;
			if (TOS_NODE_ID != 0) {				
				post Radiomsgsendtosource();
			}
			else  {
				post Serialmsgsend();
			}			
		}
	}
	event void RadioSend.sendDone(message_t* msg, error_t error) {
		if ( &_RadioSendPacket == msg) {
			_radioBusy = FALSE;
		}
		_ReSend=(NodeToNodeMsg_t *)( call RadioSend.getPayload(&_RadioSendPacket,sizeof(NodeToNodeMsg_t))); 
		if(_ReSend->DestID!=0) {
			// Do Nothing because we do not asked for Ack
		}
		if(_ReSend->DestID==0) {
		
			if(call PacketAcknowledgements.wasAcked(msg)){
				// do something if packet was acked
			}
			else {
				_Parent=SelectParent();			
				call CC2420Packet.setPower(&_RadioSendPacket, Power);
				call PacketAcknowledgements.requestAck(&_RadioSendPacket);
				if (call RadioSend.send(_Parent, &_RadioSendPacket, sizeof(NodeToNodeMsg_t))== SUCCESS) {
					_radioBusy = TRUE;
				}
			}
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
	event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) { // SerialSend - RadioSend - Read
		if (len == sizeof(NodeToNodeMsg_t)) { 	
			//call Leds.led0On(); 
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			_Counter=incomingPacket->Counter;
			_SourceID=incomingPacket->SourceID;

			if (_Counter >_Seq) {// check whether the Packet is new or old
				
				buffer.Counter=incomingPacket->Counter;
				buffer.SourceID=incomingPacket->SourceID;
				buffer.Temperature=incomingPacket->Temperature;
				buffer.DestID=incomingPacket->DestID;
				_Seq=_Counter;  
				
				if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID!=0){ 
					//call Leds.led0Toggle();
					call Read.read();// read codes
				}
				
				if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID==0)  {
					post Serialmsgsend();
				}
				
				if (incomingPacket->DestID!=TOS_NODE_ID && incomingPacket->DestID==0){
					post Radiomsgsendtosource();
				}
				if (incomingPacket->DestID!=TOS_NODE_ID && incomingPacket->DestID!=0){
					post Radiomsgsend();
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
			_Rssi=call CC2420Packet.getRssi(msg);// recieve the RSSI of the recieved packet
			printf("The RSSI is!!: %u\n", _Rssi);
			if (isNeighburExists(_BeaconPacket->BeaconSenderID,_Rssi,_BeaconPacket->Eetx,_BeaconPacket->Parent)==FALSE)  { // Check if it is there and update
				addToTable(_BeaconPacket->BeaconSenderID,_Rssi,_BeaconPacket->Eetx,_BeaconPacket->Parent); // adds the new Node to the Neighbur Table
				//call Leds.led2Toggle();
			}
		}
		return msg;
	}
	event message_t* SerialReceive.receive(message_t* msg, void* payload, uint8_t len) {  
		//What Node does while it recives packet from Serial
		if (len == sizeof(NodeToNodeMsg_t)) { 
			//call Leds.led1On();
			_Seq++;
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			buffer.Counter=incomingPacket->Counter;
			buffer.SourceID=incomingPacket->SourceID;
			buffer.DestID=incomingPacket->DestID;
			buffer.Counter=_Seq;
			if (incomingPacket->DestID==TOS_NODE_ID) {
				call Read.read();
			}
			else {
				post Radiomsgsend();
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
				_neighburTable[i][3]=VERY_LARGE_EETX_VALUE;
				_neighburTable[i][4]=-1;
				_neighburTable[i][5]=-1;
			}
		}
	}
	event void RunningTimer.fired( ) {   
	}
}


