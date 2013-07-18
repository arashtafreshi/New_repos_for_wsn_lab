#include "Task3.h"
#include <stdlib.h>
module Task3C {
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
	//Interfaces for task3 +++++++++++++++
	uses {
		interface Read<uint16_t>;
		interface PacketAcknowledgements;//allows the enabling of ACKs
	}  
	//Beacon
	uses { 
		interface AMSend as BeaconSend;
		interface AMSend as AckSend;
		interface Receive as BeaconReceive;
		interface Timer<TMilli> as BeaconTimer;
		interface Timer<TMilli> as DeleteNeighbor;
	}

	//Ack
	uses{
		interface Receive as AckReceive;
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
	int16_t Power=3;
	int16_t _neighburTable[][];
	BeaconMsg_t* _BeaconPacket;
	AckMsg_t* _AckPacket;
	bool _newNeighburFlag;
	int16_t _tableCounter=0;
	int16_t _SourceID;
	AckMsg_t* _AckPacket;
	BeaconMsg_t* _BeaconPacket;



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

	void isNeighburExists(int ID)  {
		for (int i=0 ; i<_tableCounter ; i++) {
			if (_neighburTable[i][0] == ID)  {
				_newNeighburFlag=FALSE;
				_neighburTable[_tableCounter][1] = BeaconTimer.getNow();
			}

		}
	}

	void addToTable(int ID) {
		_neighburTable[_tableCounter][0] = ID; // set the ID of the new Node
		_neighburTable[_tableCounter][1] = BeaconTimer.getNow(); // set the arrival time of beacon
		_neighburTable[_tableCounter][2] = 0; // set the ack sign for new Node. It is 0 because no packet sent to this node yet.
		_neighburTable[_tableCounter][3] = 0; // set ack to 0 which means no ack expected to receive from this node
		_tableCounter++; // set for the position for the next new Node 
	}

	void setAckInTable(int SenderID){ //****************** DONE!
		for (int i=0 ; i<_tableCounter ; i++) {
			if (_neighburTable[i][0] == SenderID)  {

				_neighburTable[_tableCounter][3] =0;
			}
		}

	}


	void SendAckPacket(int _SourceID)  {
		if (_radioBusy==FALSE)
			{
				//setting the payloads of the beacon packet
				_AckPacket=(AckMsg_t *)( call Packet.getPayload(&_Packet,sizeof(AckMsg_t)));  	
				_AckPacket->SourceID=_SourceID;// Its Node ID as Beacon sender
			}
			
			//sending the packet phase
			call CC2420Packet.setPower(msg, Power);
			if (call AckSend.send(AM_BROADCAST_ADDR,  &_Packet, sizeof(AckMsg_t))== SUCCESS) {
				_radioBusy = TRUE;
			}


	}
	event void Boot.booted() {

		call RadioControl.start(); // start Radio communication 
		call SerialControl.start();// start Serial communication
	}

	event void RadioControl.startDone(error_t err) {    
		if (err == SUCCESS) { // SUCCESS: There is no error
  	call BeaconTimer.startPeriodic( 2000 );
	call BeaconTimer.startPeriodic( 1000 );
    }
    else {  
      call RadioControl.start();// Try to start it again if failed
    }
		
	}
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	event void Read.readDone(error_t result, uint16_t data) {
		// store measurement in buffer

		if (TOS_NODE_ID==0)  {
			send serail to PC

		}
		else {
			

		}
		
	}
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&_Packet == msg) {

			_radioBusy = FALSE;
		}
	}
event void AckSend.sendDone(message_t* msg, error_t error) {
		if (&_Packet == msg) {

			_radioBusy = FALSE;
		}
	}

event void BeaconSend.sendDone(message_t* msg, error_t error) {
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

	event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) { //********** Read() & send Serial  & send Ack
		//What motes do while they recive packet in radio
		if (len == sizeof(NodeToNodeMsg_t)) { 
			
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			_Counter=incomingPacket->Counter;
			_SourceID=incomingPacket->SourceID;
			if (_Counter >_Seq) {// check whether the Packet is new or old
				
				_Seq=_Counter;  
				if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID!=0){          
					call Read.read();// read codes
					call Leds.led0On();
				}
				
				if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID==0)  {
					// Send Serial to PC
					call Leds.led0On();
				}

				if (incomingPacket->DestID!=TOS_NODE_ID){
					call Leds.led0Off();
					call CC2420Packet.setPower(msg, Power);// Set the power of packet in runtime.
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(NodeToNodeMsg_t))== SUCCESS) {
						_radioBusy = TRUE;
						SendAckPacket(_SourceID);
					}
				}
			}
		}
		return msg;
	}

	event message_t * BeaconReceive.receive(message_t *msg, void *payload, uint8_t len){  //**************		DONE!
		//what motes do when they recieve Beacon message  
		if (len == sizeof(BeaconMsg_t))  {

			_BeaconPacket = (BeaconMsg_t *)payload;
			_newNeighburFlag = TRUE;
			isNeighburExists(_BeaconPacket->BeaconSenderID); // check whether the beacon sender exists in table or not. If not, then set _newNeighburFlag = TRUE
			if (_newNeighburFlag = TRUE)  { // The received beacon refers to a Node which is not in the table yet and it is new
				addToTable(_BeaconPacket->BeaconSenderID); // adds the new Node to the Neighbur Table
			}
			return msg;
		}
	}
	event message_t * AckReceive.receive(message_t *msg, void *payload, uint8_t len){ // ***************	DONE!

		if (len == sizeof(AckMsg_t))  {

			_AckPacket = (AckMsg_t *)payload;
			setAckInTable (_AckPacket->AckSenderID);

		}

	}

	event message_t* SerialReceive.receive(message_t* msg, void* payload, uint8_t len) {  //****************** Read()
		//What Node does while it recives packet from Serial
		if (len == sizeof(NodeToNodeMsg_t)) { 
			_Seq++;
			incomingPacket = (NodeToNodeMsg_t *)payload;  
			incomingPacket->Counter=_Seq;
			
			if (incomingPacket->DestID==TOS_NODE_ID) {

				call Read.read();
			}
			else {
				//Set power of the packet to send
				call CC2420Packet.setPower(msg, Power);
				
				if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(NodeToNodeMsg_t))== SUCCESS) {
					
					_radioBusy = TRUE;
				}
			}
			
		}
		return msg;
	}


		event void BeaconTimer.fired( ) { //*************** DONE!
			//creating the packet phase
			if (_radioBusy==FALSE)
			{
				//setting the payloads of the beacon packet
				_BeaconPacket=(BeaconMsg_t *)( call Packet.getPayload(&_Packet,sizeof(BeaconMsg_t)));  	
				_BeaconPacket->BeaconSenderID=TOS_NODE_ID;// Its Node ID as Beacon sender
			}
			
			//sending the packet phase
			call CC2420Packet.setPower(msg, Power);
			if (call BeaconSend.send(AM_BROADCAST_ADDR,  &_Packet, sizeof(BeaconMsg_t))== SUCCESS) {
				_radioBusy = TRUE;
			}
		}
}


