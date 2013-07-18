#ifndef TASK1_H
#define TASK1_H
// provide definition for radio packets

typedef nx_struct NodeToNodeMsg // what is it exactly?????
{
	
	nx_int16_t NodeID; // nx_int16 is the data type in tinyos
	nx_int16_t Data;
	nx_uint16_t Counter;
	
	
}NodeToNodeMsg_t;


enum// what???!!!
{
	AM_RADIO=6// AM=active message
}

#endif /* TASK1_H */
