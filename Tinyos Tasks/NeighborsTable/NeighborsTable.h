#ifndef NEIGHBORSTABLE_H
#define NEIGHBORSTABLE_H

typedef nx_struct NodeToNodeMsg {
	nx_uint16_t Counter;
	nx_uint16_t DestID;
	nx_uint16_t Neighbors;
	nx_uint16_t SourceID;	
}NodeToNodeMsg_t;

typedef nx_struct BeaconMsg {
	nx_uint16_t BeaconSenderID;
}BeaconMsg_t;



enum {
	AM_NODETONODEMSG = 0x89, 
	AM_BEACONMSG=2 ,
};
#endif /* NEIGHBORSTABLE_H */
