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
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.freeswitch.*;
import org.freeswitch.swig.API;
import org.freeswitch.swig.JavaSession;
import org.freeswitch.swig.freeswitch;

public class incoming implements FreeswitchScript, HangupHook{
	String scriptName = "incoming";
	String Caller, App, GSMinterface, Callid, Appid, Gatewayid;
	boolean debug = true;
	JavaSession session;
	@Override
	public void run(String arg0, String arg1) {
		// TODO Auto-generated method stub
		session = new JavaSession(arg0);
		session.setHangupHook(this);
		Caller = session.getVariable("caller_id_number");
		
		Connection con = new DatabaseHandler().getConnection();
		// Check for App registration
		String Query = "Select t.Name , App_id, Gateway_id from Apps_registration as t, Gateway_registration, Apps_gatewayassociation where App_id = ";
		Query += " t.id and Gateway_id = Gateway_registration.id and Call_Type='IN' and Interface_name = '"
				+ arg1 + "'";
		Debug(Query);
		try {
			ResultSet rs = con.createStatement().executeQuery(Query);
			if (rs.next()) {
				App = rs.getString(1);
				Appid = rs.getString(2);
				Gatewayid = rs.getString(3);
			}
			if (App != null && App.length() > 0) {
				Query = "insert into Call_history(Caller,Call_Type, Gateway_id, Hangup_Cause, Time_stamp, Date_stamp, App_id) ";
				Query += " value('" + Caller + "','IN'," + Gatewayid
						+ ",'', NOW(), NOW()," + Appid + ")";
				Debug(Query);
				con.createStatement().executeUpdate(Query);
				ResultSet li = con.createStatement().executeQuery(
						"Select LAST_INSERT_ID()");
				if (li.next()) {
					Callid = li.getString(1);
				}
				Class IVRApp = Class.forName(App);
				Method m = IVRApp.getDeclaredMethod("start", new Class[] {
						JavaSession.class, String.class });
				Object obj = IVRApp.newInstance();
				Object r = m.invoke(obj, new Object[] { session, Callid });
				// obj.getClass().getDeclaredMethod(start);
			} else {
				Query = "Select id from Gateway_registration where Interface_name='"
						+ arg1 + "'";
                Debug(Query);
				ResultSet ts = con.createStatement().executeQuery(Query);
				if (ts.next()) {
					Gatewayid = ts.getString(1);
				}
				Query = "insert into Call_history(Caller,Call_Type, Gateway_id, Hangup_Cause, Time_stamp, Date_stamp) ";
				Query += " value('" + Caller + "','IN'," + Gatewayid
						+ ",'No App' ,NOW(), NOW())";
				Debug(Query);
				con.createStatement().executeUpdate(Query);
                session.destroy();
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		// update Call table
		catch (ClassNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InstantiationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalArgumentException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InvocationTargetException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (SecurityException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NoSuchMethodException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		finally{
			try {
				con.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

	}

	public void Debug(String str) {
		if (debug) {
			freeswitch.consoleLog("DEBUG", "<Incoming>"+str);
		}
	}

	@Override
	public void onHangup() {
		// TODO Auto-generated method stub
		freeswitch.console_log("notice", "incoming java destroying session\n");
		session.destroy();
	}

}
