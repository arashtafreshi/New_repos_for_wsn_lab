#ifndef TASK2_H
#define TASK2_H

typedef nx_struct NodeToNodeMsg {

	nx_int16_t NodeID; 	
	nx_uint16_t ledToToggle;
	nx_uint16_t Counter;
	nx_uint16_t DestID;
	
}NodeToNodeMsg_t;

enum {
	AM_NODETONODEMSG = 0x89,
};

#endif /* TASK2_H */
