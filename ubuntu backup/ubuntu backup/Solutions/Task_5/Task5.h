#ifndef Task5_H
#define Task5_H
#include <stdlib.h>
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

typedef nx_struct logentry_t {
    nx_uint16_t len;
    message_t msg;
  } logentry_t;

//keeping track of the volume version.
typedef struct config_t {
  uint16_t version;
  uint16_t Data;
} config_t;



enum {
	AM_NODETONODEMSG = 0x89, 
	AM_BEACONMSG=2 ,
	VERY_LARGE_EETX_VALUE = 40,
	RSSI_THRESHOLD = 10,
};

//enum for Config
enum {
    CONFIG_ADDR = 0,
    CONFIG_VERSION = 1,
    DEFAULT_TEMPERATURE = 1000,
    //MIN_PERIOD     = 128,
    //MAX_PERIOD     = 1024
  };

#endif /* Task5_H */
