
<?php
for($i=1;$i<4;$i++){

 echo exec("rm  main.ihex.out-".$i);
 echo exec("rm  main.exe.out-".$i);
 echo exec("tos-set-symbols --objcopy msp430-objcopy --objdump msp430-objdump --target ihex main.ihex main.ihex.out-".$i." TOS_NODE_ID=".$i." ActiveMessageAddressC__ad$

 echo exec("tos-bsl -c /dev/ttyUSB".$i." --telosb  -r -e -I -p main.ihex.out-".$i);

}

?>
