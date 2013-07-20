/*									tab:4
 * Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * Java-side application for testing serial port communication.
 * 
 *
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @date August 12 2005
 */


import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class NeighborsTable implements MessageListener {

  private MoteIF moteIF;
  
  public NeighborsTable(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new NeighborsTableMsg(), this);
  }

  public void sendPackets() {
    
  }

  public void messageReceived(int to, Message message) {
    NeighborsTableMsg tempmsg = (NeighborsTableMsg)message;
		try {
			Connection con;
			PreparedStatement pst;

			String url = "jdbc:mysql://localhost/wsn_lab";
			String user = "root";
			String password = "";
			con = (Connection) DriverManager.getConnection(url, user, password);
			String n = Integer.toString(tempmsg.get_Neighbors());
			for (int i=0 ; i<n.length() ; i++){
				char destChar = n.charAt(i);
				int destInt = Character.getNumericValue(destChar);
				pst = (PreparedStatement) con.prepareStatement("INSERT INTO neighbor(GroupID,SourceID,DestID) VALUES(1,2,"+destInt+")");
				pst.executeUpdate();
			}

		} 
		catch (SQLException ex) {
		    //Logger.getLogger(NewJFrame.class.getName()).log(Level.SEVERE, null, ex);
		}
  }
  
  private static void usage() {
    System.err.println("usage: NeighborsTable [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception {
    String source = null;
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }

    MoteIF mif = new MoteIF(phoenix);
    NeighborsTable serial = new NeighborsTable(mif);
    serial.sendPackets();
  }


}
