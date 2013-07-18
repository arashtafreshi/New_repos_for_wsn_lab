configuration Task2AppC

{

}



implementation

{

	//General Components

	components MainC;

	components LedsC;

	components Task2C as App;

	components CC2420ActiveMessageC;//component for setting the transmitting power

	
	//Radio Communication	

	components ActiveMessageC;

	components new AMSenderC(AM_NODETONODEMSG);

	components new AMReceiverC(AM_NODETONODEMSG); 
	
	
	//Serial Communication

	components SerialActiveMessageC;  

	
	// General Wiring	

	App.Boot->MainC;

	App.Leds->LedsC;
	
	App.CC2420Packet -> CC2420ActiveMessageC;
	
	
	//Radio wiring


	App.AMSend -> AMSenderC;

	App.RadioControl -> ActiveMessageC;

	App.RadioReceive ->AMReceiverC;
	
	
	//Serial Wiring


	App.SerialControl-> SerialActiveMessageC;

	App.SerialReceive -> SerialActiveMessageC.Receive[AM_NODETONODEMSG];
	
 

}
