/*Copyright (c) 2013 Indraprastha Institute of Information Technology Delhi
, and others


   Licensed under the Apache License, Version 2.0 (the "License"); you

   may not use this file except in compliance with the License.  You

   may obtain a copy of the License at


       http://www.apache.org/licenses/LICENSE-2.0


   Unless required by applicable law or agreed to in writing, software

   distributed under the License is distributed on an "AS IS" BASIS,

   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or

   implied.  See the License for the specific language governing

   permissions and limitations under the License.


The Initial Developer of the Original Code is
 * Siddhartha Asthana <siddharthaa@iiitd.ac.in>
 * Portions created by the Initial Developer are Copyright (C)
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * 
 *  Siddhartha Asthana <siddharthaa@iiitd.ac.in>
 *  Pushpendra Singh <psingh@iiitd.ac.in>
 *  Amarjeet Singh <amarjeet@iiitd.ac.in>
 * 
 */


import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.freeswitch.FreeswitchScript;
import org.freeswitch.HangupHook;
import org.freeswitch.swig.JavaSession;
import org.freeswitch.swig.freeswitch;


public class bootstrap implements FreeswitchScript, HangupHook {
   String cmd="";
	@Override
	public void onHangup() {
		// TODO Auto-generated method stub
		
	}
public void call(){
	//created for dialplan invocation
	run("a","b");
}
	@Override
	public void run(String arg0, String arg1) {
		// TODO Auto-generated method stub
		freeswitch.consoleLog("INFO", "Initializing bootstrap class..." );
		JavaSession session = null;
        try
            {
                session = new JavaSession(arg0);
                session.answer();
                session.hangup("NORMAL_CLEARING");
            }
        finally
            {
                if (session != null)
                    session.destroy();
            }
        while(true){
        	cmd=read();
        	
        	if(cmd!=null || cmd.toLowerCase().equals("start")){
        		if(cmd.toLowerCase().equals("end")){
        			freeswitch.consoleLog("info", "<Bootstrap.java>: Got Script termination Instruction\n" );
        			break;
        		}
        		freeswitch.consoleLog("info", "Checking for Communicator Applications\n" );
        		StartApplication();
        		try {
					TimeUnit.SECONDS.sleep(30);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
        	}
        }
	}

	private void StartApplication() {
		// TODO Auto-generated method stub
		Connection con = new DatabaseHandler().getConnection();
		String Query = "Select Distinct(App_id) from Call_schedule where Schedule < Now() and Timeout > Now() and Status=0";
		Debug(Query);
		ResultSet rs;
		try {
			rs = con.createStatement().executeQuery(Query);
			//ThreadGroup tg = new ThreadGroup("Applications")
			//ThreadPoolExecutor th = new ThreadPoolExecutor();
			while(rs.next()){
				Connection cn = new DatabaseHandler().getConnection();
				ResultSet rst = con.createStatement().executeQuery("Select * from Apps_registration where id="+rs.getString("App_id"));
				Debug("Select * from Apps_registration where id="+rs.getString("App_id"));
				if (rst.next()){
			ApplicationHook ah = new ApplicationHook(rst.getString("Name"));
			Debug("Starting Application " + rst.getString("Name"));
			Thread t = new Thread(ah,rst.getString("Name"));
			t.start();
			TimeUnit.SECONDS.sleep(1);
			}
				cn.close();
			}
			
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		finally{try {
			con.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}}
		
	}

	private void Debug(String str) {
		// TODO Auto-generated method stub
		freeswitch.consoleLog("Debug", "<BootStrap>"+str+"\n");
	}

	private String read() {
		// TODO Auto-generated method stub
		cmd="";
		BufferedReader br = null;
		 
		try {
 
			String sCurrentLine;
 
			br = new BufferedReader(new FileReader("/usr/local/freeswitch/scripts/cmd.txt"));
 
			if ((sCurrentLine = br.readLine()) != null) {
				cmd= sCurrentLine;
			}
 
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				if (br != null)br.close();
			} catch (IOException ex) {
				ex.printStackTrace();
			}
		}
		return cmd;
	}

}
