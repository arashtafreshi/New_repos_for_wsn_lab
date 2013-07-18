COMPONENT=Task5AppC
BUILD_EXTRA_DEPS += Task5.class
CLEAN_EXTRA = *.class Task5Msg.java 
CFLAGS += -I$(TOSDIR)/lib/printf
#CFLAGS += -DNEW_PRINTF_SEMANTICS

//CFLAGS += -DCC2420_DEF_RFPOWER=1
DEFAULT_LOCAL_GROUP = 3

Task5Msg.java: 
	mig java -target=telosb -java-classname=Task5Msg Task5.h NodeToNodeMsg -o $@

Task5.class: $(wildcard *.java) Task5Msg.java
	javac *.java

include $(MAKERULES)
