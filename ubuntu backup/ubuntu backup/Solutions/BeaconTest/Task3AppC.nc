configuration Task3AppC {

}
implementation {
	//General Components
	components MainC;
	components LedsC;
	components Task3C as App;
	components CC2420ActiveMessageC;//component for setting the transmitting power
	components new TimerMilliC() as BeaconTimer;

	
	//Radio Communication	
	components ActiveMessageC;

	components new AMSenderC(AM_BEACONMSG) as BAMSenderC;
	components new AMReceiverC(AM_BEACONMSG) as BAMReceiverC;


	//Serial Communication
	components SerialActiveMessageC;  

	App.Packet -> BAMSenderC;

	// General Wiring	
	App.Boot->MainC;
	App.Leds->LedsC;
	App.CC2420Packet -> CC2420ActiveMessageC;


	//Radio wiring

	App.RadioControl -> ActiveMessageC;
	
	//Serial Wiring
	App.SerialControl-> SerialActiveMessageC;


	//Beacon
	App.BeaconTimer->BeaconTimer;
	App.BeaconSend -> BAMSenderC;
	App.BeaconReceive -> BAMReceiverC;

}
