/**
 We implemented two different aspect of persistency.

	1_ Keep Temprature as a Sensor data in Flash - with ConfigStorage. 

	2-(Optional) Keep Last Message that node received as the last message with LogStorage.By keeping this we prevent command lost if sensors get shutdown.  

*/	




	#include "Task5.h"
	#include <stdlib.h>
	module Task5C {
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
			interface Timer<TMilli> as TempUpdateTimer;
			
			interface PacketAcknowledgements;
			
			//interface for storage
			interface Mount as ConfigMount;
			interface ConfigStorage as Config;
			
			//interface for log
			interface LogRead;
			//use this interface  to write small blocks of data to flash
			interface LogWrite;
			interface Packet;
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
		
		//new for Task5
		bool m_busy = TRUE;
		logentry_t m_entry;
		
		uint8_t state;
		config_t conf;
		
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
					call Leds.led0Toggle();	
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
					//call Leds.led1Toggle();					
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
			//Before the flash chip can be used, it must be mounted using the two-phase mount/mountDone command
			call TempUpdateTimer.startPeriodic( 10000 );	
		}
		event void RadioControl.startDone(error_t err) {    
			if (err == SUCCESS) { 
				//it first tries to read flash memory if any was written during a previous boot cycle:
				if (call LogRead.read(&m_entry, sizeof(logentry_t)) != SUCCESS) {
					// Handle error
				}
				call BeaconTimer.startPeriodic( 2000 );
				call eachSec.startPeriodic( 1000 );
				call RunningTimer.startOneShot(1);	
			}
			else {  
				call RadioControl.start();
			}
		}
		event void Read.readDone(error_t result, uint16_t data) {
			if (result == SUCCESS){
				
				_Temperature=data;
				
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
			if ( (error == SUCCESS) && (msg == &m_entry.msg) ) {
				call Packet.clear(&m_entry.msg);
				if (call LogRead.read(&m_entry, sizeof(logentry_t)) != SUCCESS) {
					// Handle error.
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
				
				incomingPacket = (NodeToNodeMsg_t *)payload;  
				_Counter=incomingPacket->Counter;
				_SourceID=incomingPacket->SourceID;
				if (_Counter >_Seq) {
					//stores new packets received over the radio to flash
					if (!m_busy) {
						m_busy = TRUE;
						m_entry.len = len;// save len of the message and message in m_entry
						m_entry.msg = *msg;
						//call LogWrite.erase();
						//Append:allows a buffer to be appended to the end of the data already written.
						if (call LogWrite.append(&m_entry, sizeof(logentry_t)) != SUCCESS) {
							m_busy = FALSE;
						}
					}
					buffer.Counter=incomingPacket->Counter;
					buffer.SourceID=incomingPacket->SourceID;
					buffer.Temperature=incomingPacket->Temperature;
					buffer.DestID=incomingPacket->DestID;
					_Seq=_Counter;  
					
					if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID!=0){ 
						call Leds.led1Toggle();
						//call Read.read();// read codes
						_Seq++;
						buffer.Counter=_Seq;
						call Config.read(CONFIG_ADDR, &conf, sizeof(conf));
						buffer.Temperature=conf.Data;
						buffer.SourceID=TOS_NODE_ID;
						buffer.DestID=0;
						if (TOS_NODE_ID != 0) {				
							post Radiomsgsendtosource();
						}
						else  {
							post Serialmsgsend();
						}		
					}
					
					if (incomingPacket->DestID==TOS_NODE_ID && TOS_NODE_ID==0)  {
						post Serialmsgsend();
					}
					
					if (incomingPacket->DestID!=TOS_NODE_ID && incomingPacket->DestID==0){
						post Radiomsgsendtosource();
					}
					if (incomingPacket->DestID!=TOS_NODE_ID && incomingPacket->DestID!=0){
						call Leds.led2On();	
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
				        call Leds.led1Toggle();
					call Config.read(CONFIG_ADDR, &conf, sizeof(conf));
					buffer.Temperature=conf.Data;
					post Serialmsgsend();
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
		event void TempUpdateTimer.fired( ) {  
			call Read.read();
			if (call ConfigMount.mount() != SUCCESS) { 
				// Handle failure
			}
		}
		/*The following code shows how to check if the volume is valid.
		and if it is, how to initiate a read from the volume using the ConfigStore.read command.
		*/
		event void ConfigMount.mountDone(error_t error) {
			if (error == SUCCESS) {
				if (call Config.valid() == TRUE) {
					//it is valid, then start read from volum by Config.read 
					if (call Config.read(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
						// Handle failure
					}
				}
				else {
					// Invalid volume.  Config.Commit to make it valid.
					if (call Config.commit() == SUCCESS) {
					}
					else {
						// Handle failure
					}
				}
			}
			else{
				// Handle failure
			}
		}
		/*
	*if read is succesful then this will happen. 
	*first check for a successful read.if yes, check for version number.,if valid, copy to local variable
	*if version distmach,set the value of the configuration information to a default value 
	*finally call config.write
	*/
		event void Config.readDone(storage_addr_t addr, void* buf,storage_len_t len, error_t err) __attribute__((noinline)) {
			if (err == SUCCESS) {
				//void * memcpy ( void * destination, const void * source, size_t num );
				
				memcpy(&conf, buf, len);
				if (conf.version == CONFIG_VERSION) {
					
					conf.Data=_Temperature;
					
				}
				else {
					// Version mismatch. Restore default.
					conf.version = CONFIG_VERSION;
					conf.Data=DEFAULT_TEMPERATURE;
					
				}
				call Config.write(CONFIG_ADDR, &conf, sizeof(conf));
			}
			else {
				// Handle failure.
			}
		}
		/* 
	*data is not necessary written to flash when configstore.write() called and writedone is signaled.
	*to ensure data is persisted to flash, a ConfigStore.commit call is required
	*/
		event void Config.writeDone(storage_addr_t addr, void *buf, storage_len_t len, error_t err) {
			// Verify addr and len
			if (err == SUCCESS) {
				if (call Config.commit() != SUCCESS) {
					// Handle failure
				}
			}
			else {
				// Handle failure
			}
		}
		/*
	*Finally when this called data will written in flash 
	*and stay alive!and will survive a node power cycle.
	*/
		event void Config.commitDone(error_t err) {
			
			
			if (err != SUCCESS) {
				// Handle failure
			}
		}
		event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
			//we check if the data that was returned is the same length as what we expected.
			if ( (len == sizeof(logentry_t)) && (buf == &m_entry) ) {
				incomingPacket=(NodeToNodeMsg_t *)( call RadioSend.getPayload(&m_entry.msg,sizeof(NodeToNodeMsg_t))); 
				
				_Counter=incomingPacket->Counter;
				_SourceID=incomingPacket->SourceID;
				if (_Counter >_Seq) {

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
			else {
				/*
	*if not, we assume that either the log is empty or that we have lost synchronization,
	*so the log is erased.
	*erase:allows the flash to be erased, which is required before any writes (appends) can be made.
	*/
				if (call LogWrite.erase() != SUCCESS) {
					// Handle error.
				}
			}
		}
		/* This event returns the details of the write
	*including the source buffer, length of data written, 
	*whether any records were lost (if this is a circular buffer) and any error code.
	*/
		event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t err) {
			//RecordsLost: a boolean value indicating if old data was overwritten if the log was full
			call Leds.led1On(); 
			m_busy = FALSE;
		}
		event void LogWrite.eraseDone(error_t err) {
			if (err == SUCCESS) {
				m_busy = FALSE;
			}
			else {
				// Handle error.
			}
		}
		event void LogRead.seekDone(error_t err) {
		}
		/*The LogWrite.sync() command commits all pending writes to flash,
	*for each append command may not incur a write.
	*Maslan in meghdar hafeze ke ezafe shode be andaze data ke gharare zakhire beshe naboode o matal moonde data
	*/
		event void LogWrite.syncDone(error_t err) {
		}
	}
