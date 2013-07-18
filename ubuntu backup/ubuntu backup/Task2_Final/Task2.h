#ifndef TASK2_H
#define TASK2_H

// provide definition for radio packets


typedef nx_struct NodeToNodeMsg 

{

	nx_int16_t NodeID; // nx_int16 is the data type in tinyos

	//nx_int16_t Data;
	nx_uint16_t ledToToggle;
	nx_uint16_t Counter;
	nx_uint16_t DestID;


}NodeToNodeMsg_t;


enum

{

	//AM_RADIO=6// AM=active message
	 //AM_TASK2_SERIAL = 0x6,
	AM_NODETONODEMSG = 0x89,
};



#endif /* TASK2_H */
