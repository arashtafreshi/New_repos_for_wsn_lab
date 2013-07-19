COMPONENT=NeighborsTableAppC
BUILD_EXTRA_DEPS += NeighborsTable.class
CLEAN_EXTRA = *.class NeighborsTableMsg.java 

//CFLAGS += -DCC2420_DEF_RFPOWER=1
DEFAULT_LOCAL_GROUP = 3

NeighborsTableMsg.java: 
	mig java -target=telosb -java-classname=NeighborsTableMsg NeighborsTable.h NodeToNodeMsg -o $@

NeighborsTable.class: $(wildcard *.java) NeighborsTableMsg.java
	javac *.java

include $(MAKERULES)
