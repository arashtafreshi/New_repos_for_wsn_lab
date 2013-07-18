COMPONENT=Task4AppC
BUILD_EXTRA_DEPS += Task4.class
CLEAN_EXTRA = *.class Task4Msg.java 
CFLAGS += -I$(TOSDIR)/lib/printf
#CFLAGS += -DNEW_PRINTF_SEMANTICS

//CFLAGS += -DCC2420_DEF_RFPOWER=1
DEFAULT_LOCAL_GROUP = 3

Task4Msg.java: 
	mig java -target=telosb -java-classname=Task4Msg Task4.h NodeToNodeMsg -o $@

Task4.class: $(wildcard *.java) Task4Msg.java
	javac *.java

include $(MAKERULES)
