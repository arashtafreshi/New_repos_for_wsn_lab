COMPONENT=Task2AppC
BUILD_EXTRA_DEPS += Task2.class 
CLEAN_EXTRA = *.class Task2Msg.java 

//CFLAGS += -DCC2420_DEF_RFPOWER=1
DEFAULT_LOCAL_GROUP = 3

Task2.class: $(wildcard *.java) Task2Msg.java
	javac *.java

Task2Msg.java: 
	mig java -target=null -java-classname=Task2Msg Task2.h NodeToNodeMsg -o $@

include $(MAKERULES)
