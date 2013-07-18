#ifndef TASK3_H
#define TASK3_H

typedef nx_struct NodeToNodeMsg {
	nx_uint16_t Counter;
	nx_uint16_t DestID;
	nx_uint16_t Temperature;
	nx_uint16_t SourceID;	
}NodeToNodeMsg_t;

typedef nx_struct BeaconMsg {
	nx_uint16_t BeaconSenderID;
}BeaconMsg_t;

typedef nx_struct AckMsg {
	nx_uint16_t AckSenderID;
}AckMsg_t;

enum {
	AM_NODETONODEMSG = 0x89, 
	AM_BEACONMSG=2 ,
	AM_ACKMSG=5 ,	
};
#endif /* TASK3_H */
