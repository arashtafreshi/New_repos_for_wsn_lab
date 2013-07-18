#ifndef TASK4_H
#define TASK4_H

typedef nx_struct NodeToNodeMsg {
	nx_uint16_t Counter;
	nx_uint16_t DestID;
	nx_uint16_t Temperature;
	nx_uint16_t SourceID;	
}NodeToNodeMsg_t;

typedef nx_struct BeaconMsg {
	nx_uint16_t BeaconSenderID;
	nx_uint16_t Eetx;
	nx_uint16_t Parent;
}BeaconMsg_t;

//typedef nx_struct AckMsg {
	//nx_uint16_t AckSenderID;
//}AckMsg_t;

enum {
	AM_NODETONODEMSG = 0x89, 
	AM_BEACONMSG=2 ,
	VERY_LARGE_EETX_VALUE = 40,
	RSSI_THRESHOLD = 10,
};
#endif /* TASK4_H */
