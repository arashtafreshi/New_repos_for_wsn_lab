#define NEW_PRINTF_SEMANTICS
#include "printf.h"
configuration Task4AppC {

}
implementation {
	//General Components
	components MainC;
	components LedsC;
	components Task4C as App;
	components CC2420ActiveMessageC;//component for setting the transmitting power
	components new TimerMilliC() as BeaconTimer;
	components new TimerMilliC() as eachSec;
	components new TimerMilliC() as RunningTimer;
	
	//Radio Communication	
	components ActiveMessageC;
	components new AMSenderC(AM_NODETONODEMSG) as RAMSenderC;
	components new AMReceiverC(AM_NODETONODEMSG) as RAMReceiverC; 
	
	components new AMSenderC(AM_BEACONMSG) as BAMSenderC;
	components new AMReceiverC(AM_BEACONMSG) as BAMReceiverC;

	//components new AMSenderC(AM_ACKMSG) as AckAMSenderC;	
	//components new AMReceiverC(AM_ACKMSG) as AckAMReceiverC;
	
	//App.Packet -> RAMSenderC;

	//Serial Communication
	components SerialActiveMessageC;  

	//Sense Component
	components new DemoSensorC() as Temperature;

	//Printf
	components PrintfC;
	components SerialStartC;

	// General Wiring	
	App.Boot->MainC;
	App.Leds->LedsC;
	App.CC2420Packet -> CC2420ActiveMessageC;
	App.RunningTimer->RunningTimer;
	App.eachSec->eachSec;

	//Radio wiring
	App.RadioSend -> RAMSenderC;
	App.RadioControl -> ActiveMessageC;
	App.RadioReceive ->RAMReceiverC;

	//Ack
	//App.AckSend -> AckAMSenderC;
	//App.AckReceive ->AckAMReceiverC;
	
	//Serial Wiring
	App.SerialControl-> SerialActiveMessageC;
	App.SerialReceive -> SerialActiveMessageC.Receive[AM_NODETONODEMSG];
	App.SerialSend -> SerialActiveMessageC.AMSend[AM_NODETONODEMSG];

	//Beacon
	App.BeaconTimer->BeaconTimer;
	App.BeaconSend -> BAMSenderC;
	App.BeaconReceive -> BAMReceiverC;

	//Sense
	App.Read->Temperature;
	
	//Ack
	App.PacketAcknowledgements -> ActiveMessageC;

	
}
