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
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.Thread.UncaughtExceptionHandler;
import java.lang.management.GarbageCollectorMXBean;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Date;
import java.util.concurrent.TimeUnit;

import org.freeswitch.DTMFCallback;
import org.freeswitch.FreeswitchScript;
import org.freeswitch.HangupHook;
import org.freeswitch.swig.JavaSession;
import org.freeswitch.swig.freeswitch;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.concurrent.ConcurrentHashMap;

import org.freeswitch.*;
import org.freeswitch.swig.*;

public class SchoolMonitoring implements FreeswitchScript, DTMFCallback, HangupHook{
	JavaSession session = null;
	String SCRIPT_NAME="SchoolMonitoring";
	String sd = "/usr/local/freeswitch/sounds/nrega/school/";
	static int born = 0;
	static int dead = 0;

	@Override
	public void onHangup() {
		// TODO Auto-generated method stub
		if (session !=null){
			session.destroy();
		}
	}
//1.mp welcome
	//2.mp3 is teacher absent prompt
	//3.mp3 fro food
	//4.mp3 thankyou messga
	//22.mp 3 letter school code
	
	
	
	@Override
	public String onDTMF(Object object, int i, String arg) {
		// TODO Auto-generated method stub
		if (object instanceof String) {
			freeswitch.console_log("notice", "DTMF: " + (String) object
					+ " ARG: " + arg + "\n");
				//digits = digits + (String) object;
			String Digit = 	(String) object;
			if(Digit.equals("0")){
				return "break";
			}
		}else
			freeswitch.console_log("notice", "WOW GOT AN EVENT: "
					+ object.toString());
		return "true";
	}

	@Override
	public void run(String arg0, String arg1) {
		// TODO Auto-generated method stub
		
	}
	
    public void start(JavaSession ss, String cid){
    	Date dt = new Date();
    	this.session = ss;
    	session.setDTMFCallback(this, "TEST");
        session.setHangupHook(this);
        session.execute("set", "ring_ready=true");
		session.execute("set", "instant_ringback=true");
		String Caller = session.getVariable("caller_id_number");
		while(session.ready()==true){
			session.execute("sleep","3000");
		}
		  Date st = new Date();
          String Query = "Update Call_history set Ring_Duration ='"+ ((st.getTime()-dt.getTime())/1000)+"' where id="+cid;
          update(Query);
          Query = "Update Call_history set Hangup_Cause='"+session.hangupCause()+"' where id="+cid;
          update(Query);
          Query = "Update Call_history set Call_Duration='"+(((new Date()).getTime()-st.getTime())/1000)+"' where id="+cid;
          update(Query);
          
          
          String Appid = "";
          Connection con = new DatabaseHandler().getConnection();
         try {
          		 ResultSet rs = con.createStatement().executeQuery("Select * from Apps_registration where Name='"+SCRIPT_NAME+"'");
				if (rs.next()) {
					Appid = rs.getString(1);
				}
				con.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}		
         if(Checkforregistration(Caller)){
          Query = "Insert into Call_schedule (Caller, Schedule, Timeout, App_id, Status) values('"+Caller+"',Now(), date_add(NOW(), INTERVAL 2 DAY),"+Appid+",0)";
          update(Query);}
          session.hangup("NORMAL_CLEARING");
          
        if(session!=null){
            session.destroy();
}
    
    }
    private boolean IS_Voulenteer(String clr) {
		// TODO Auto-generated method stub
    	String Query= " Select * from Subscriber_subscriber where phone ='"+clr.substring(clr.length()-10)+"'" ;
    	Connection con = new DatabaseHandler().getConnection();
    	ResultSet Gateways;
    	try {
    		Gateways = con.createStatement().executeQuery(Query);
    		int i =0;
    		while(Gateways.next()){
    			i++;
    		}
    		
    		if (i>1){
    			return true; // number of gateways retrieved from database;
    		}else{
    		//code =
    			return false;
    		}

    	} catch (SQLException e) {
    		// TODO Auto-generated catch block
    		e.printStackTrace();
    	}
    	return false;
	}
	String Absent="",Meal="",code="";	String HangupCause = "";
    private void collectinfo() {
		// TODO Auto-generated method stub
    	while(session.ready()){
    	Absent = session.read(1, 1, sd + "2.mp3", 1400, "#", 0);
    	if((Absent.length()>0)&(Absent.equals("1")|Absent.equals("2"))){
    		break;
    	}
    	}
    	while(session.ready()){
    		Meal = session.read(1, 1, sd + "3.mp3", 1400, "#", 0);
        	if((Meal.length()>0)&(Meal.equals("1")|Meal.equals("2"))){
        		break;
        	}
        	}
    	//update(meal,Absent)
    	
	}

	private boolean Checkforregistration(String clr) {
		// TODO Auto-generated method stub
	String Query= " Select * from Subscriber_subscriber where phone ='"+clr.substring(clr.length()-10)+"'" ;
	Connection con = new DatabaseHandler().getConnection();
	ResultSet Gateways;
	try {
		Gateways = con.createStatement().executeQuery(Query);
		if (Gateways.next()){
			return true; // number of gateways retrieved from database;
		}else{
		//code =
			return false;
		}

	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	return false;
	}

	public void call(){
		born++;
		String qry =  "Select count(distinct(Gateway_id)) from Apps_gatewayassociation where Call_Type='OUT'  and App_id=( select id from Apps_registration where NAME='";
		qry+= SCRIPT_NAME+"')";
		Connection con = new DatabaseHandler().getConnection();
		
		int gateways = 1; // hardcoded but to be retrieved by database
		try {
			ResultSet Gateways = con.createStatement().executeQuery(qry);
			if (Gateways.next()){
				gateways = Gateways.getInt(1); // number of gateways retrieved from database;
			}
		} catch (SQLException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		if (getalive() > gateways) {
			Debug(SCRIPT_NAME + ": waiting for gateway to be released");
			Debug("Born :" + born + " Dead :" + dead + "\n");
			born--;
			return;
		}
		String Query = "Select * from Call_schedule";
		String Appid = "";
		try {

			ResultSet rs = con.createStatement().executeQuery(
					"Select * from Apps_registration where Name='"
							+ SCRIPT_NAME + "'");
			if (rs.next()) {
				Appid = rs.getString(1);

				Query = "Select * from Call_schedule where Schedule < Now() and Timeout > Now() and Status=0 and App_id="
						+ Appid;
				// Connection cn = new DatabaseHandler().getConnection();
				Debug(Query);
				String CachedQry = Query;
				ResultSet rst = con.createStatement().executeQuery(Query);
				while (rst.next()) {
					String Caller = rst.getString(2);
					String Schedule = rst.getString(3);
					Query = CachedQry;
                    Query+= " and id=" + rst.getString(1);
                    Debug(Query);
    				ResultSet chkvalid = con.createStatement().executeQuery(Query);
					if(!chkvalid.next()){
    				continue;
					}
					
					session = new outgoing()
							.call(rst.getString(2), SCRIPT_NAME);

					if (session != null) {
						Query = "Update Call_schedule set Status=1 where id="
								+ rst.getString(1);
						update(Query);
						String cid = session.getVariable("Cid");
						session.answer();
						Date st = new Date();
				      	session.streamFile(sd + "1.mp3", 0);
				          boolean registered = Checkforregistration(Caller);
				          
				          if(registered){
				        	  boolean voulenteer = IS_Voulenteer(Caller);
				        	if(voulenteer){
				        		while(session.ready()){
				        		 code = session.read(3, 3, sd + "22.mp3", 1400, "#", 0);
				        		if(code.length()==3){
				        			break;
				        		}
				        		}
				        		}
				                  collectinfo();
				                  session.streamFile(sd + "4.mp3", 0);
				                  java.util.Date date= new java.util.Date();
				                  write("Callerid:"+Caller+", Time:"+new Timestamp(date.getTime())+", Absent: "+Absent+", Meal: "+ Meal +", Code:"+code);
				          Caller=""; Absent=""; Meal="";
				          }else{

				          }
if (session.ready()) {
	HangupCause = session.hangupCause();
} else {
	HangupCause = "USER_DISCONNECTED";
}
session.hangup("");
session.destroy();
Query = "Update Call_history set Hangup_Cause='"
		+ HangupCause + "' where id=" + cid;
String Qury = "Update Call_history set Call_Duration='"
		+ (((new Date()).getTime() - st.getTime()) / 1000)
		+ "' where id=" + cid;
//	try {
//	TimeUnit.SECONDS.sleep(2);
//} catch (InterruptedException e) {
	// TODO Auto-generated catch block
//	e.printStackTrace();
//}
update(Query);
update(Qury);

}
//try {
//TimeUnit.SECONDS.sleep(10);
//} catch (InterruptedException e) {
// TODO Auto-generated catch block
//	e.printStackTrace();
//}

}
}
} catch (SQLException e) {

e.printStackTrace();
} catch (Exception e) {
e.printStackTrace();
}finally{
try {
con.close();
} catch (SQLException e) {
// TODO Auto-generated catch block
e.printStackTrace();
}
}
dead++;

//****************************************************************

	}
	
	public static int getalive() {
		// Number of Broadcast application running
		return born - dead;
	}

//	private void code() {
//		// TODO Auto-generated method stub
//		if(true){
//	      	session.streamFile(sd + "1.mp3", 0);
//	          boolean registered = Checkforregistration(Caller);
//	          
//	          if(registered){
//	        	  boolean voulenteer = IS_Voulenteer(Caller);
//	        	if(voulenteer){
//	        		while(session.ready()){
//	        		 code = session.read(3, 3, sd + "22.mp3", 1400, "#", 0);
//	        		if(code.length()==3){
//	        			break;
//	        		}
//	        		}
//	        		}
//	                  collectinfo();
//	                  session.streamFile(sd + "4.mp3", 0);
//	                  java.util.Date date= new java.util.Date();
//	                  write("Callerid:"+Caller+", Time:"+new Timestamp(date.getTime())+", Absent: "+Absent+", Meal: "+ Meal +", Code:"+code);
//	          }else{
//
//	          }
//	          
//	          session.hangup("NORMAL_CLEARING");
//	          Query = "Update Call_history set Hangup_Cause='"+session.hangupCause()+"' where id="+cid;
//	          update(Query);
//	          Query = "Update Call_history set Call_Duration='"+(((new Date()).getTime()-st.getTime())/1000)+"' where id="+cid;
//	          update(Query);
//	        if(session!=null){
//	            session.destroy();
//	}
//	
//	}



	public void update(String Query){
    	Connection con = new DatabaseHandler().getConnection();
    	try {
			System.out.println(Query);
    		con.createStatement().executeUpdate(Query);
			con.close();
    	} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    }
    
	private void Debug(String str) {
		// TODO Auto-generated method stub
		freeswitch.consoleLog("DEBUG", "<" + SCRIPT_NAME + ">" + str + "\n");
	}

    public void write(String str){
    	try {
    		 
			String content = "This is the content to write into file";
 
			File file = new File("/usr/local/freeswitch/data/sm.txt");
 
			// if file doesnt exists, then create it
			if (!file.exists()) {
				file.createNewFile();
			}
 
			FileWriter fw = new FileWriter(file.getAbsoluteFile(),true);
			BufferedWriter bw = new BufferedWriter(fw);
			bw.write(str);
			bw.write("\n");
			bw.close();
 
			System.out.println("Done");
 
		} catch (IOException e) {
			e.printStackTrace();
		}
    	
    }

}

