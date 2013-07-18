COMPONENT=Task3AppC
BUILD_EXTRA_DEPS += Task3.class
CLEAN_EXTRA = *.class Task3Msg.java 

//CFLAGS += -DCC2420_DEF_RFPOWER=1
DEFAULT_LOCAL_GROUP = 3

Task3Msg.java: 
	mig java -target=telosb -java-classname=Task3Msg Task3.h NodeToNodeMsg -o $@

Task3.class: $(wildcard *.java) Task3Msg.java
	javac *.java

include $(MAKERULES)
