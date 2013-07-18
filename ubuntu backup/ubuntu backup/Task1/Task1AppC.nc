configuration Task1AppC

{

}



implementation

{

	//General Components

	components MainC;

	components LedsC;

	components new TimerMilliC() as Timer0;

	components Task1C as App;

	
	//Radio Communication	

	components ActiveMessageC;

	components new AMSenderC(AM_RADIO);

	components new AMReceiverC(AM_RADIO);  

	
	// Wiring	

	App.Boot->MainC;

	App.Leds->LedsC;

	App.Timer0->Timer0;

	App.Packet -> AMSenderC;

	App.AMPacket -> AMSenderC;

	App.AMSend -> AMSenderC;

	App.AMControl -> ActiveMessageC;

	App.Receive ->AMReceiverC;

}
