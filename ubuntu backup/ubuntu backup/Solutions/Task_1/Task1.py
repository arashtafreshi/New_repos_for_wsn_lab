# This file is an example Python script from the TOSSIM tutorial.
# It is intended to be used with the RadioCountToLeds application.

import sys
from TOSSIM import * 
from RadioCountMsg import *
import random

t = Tossim([]) #creat an object of Tossim           
#m = t.mac();
r = t.radio();

#t.addChannel("RadioCountToLedsC", sys.stdout);
#t.addChannel("LedsC", sys.stdout);


f = open("topo.txt", "r")# we creat a file and put in if
lines = f.readlines()
for line in lines:
  s = line.split() # we split lines 
  if (len(s) > 0):#when lines have content
     print " ", s[0], " ", s[1], " ", s[2];
     r.add(int(s[0]), int(s[1]), float(s[2]))
    

 # Create random noise stream
  for j in range (500):
    m.addNoiseTraceReading(int(random.random() * 20) - 70)
    m.createNoiseModel()

for i in range (19):
  t.getNode(i).bootAtTime(1)# i * 2351217 + 23542399

for i in range(0, 100000):
  t.runNextEvent(); #in order to run the Tossim Silumation



