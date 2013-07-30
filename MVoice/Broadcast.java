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
import java.lang.Thread.UncaughtExceptionHandler;
import java.lang.management.GarbageCollectorMXBean;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.concurrent.TimeUnit;

import org.freeswitch.DTMFCallback;
import org.freeswitch.FreeswitchScript;
import org.freeswitch.HangupHook;
import org.freeswitch.swig.JavaSession;
import org.freeswitch.swig.freeswitch;

public class Broadcast implements FreeswitchScript, DTMFCallback, HangupHook {
	JavaSession session = null;
	String SCRIPT_NAME = "Broadcast";
	String sd = "/usr/local/freeswitch/sounds/nrega/";
	static int born = 0;
	static int dead = 0;
	String HangupCause = "";

	public static int getalive() {
		// Number of Broadcast application running
		return born - dead;
	}

	@Override
	public synchronized void onHangup() {
		// TODO Auto-generated method stub
		// HangupHook is buggy because it get called multiple times
	}

	@Override
	public String onDTMF(Object object, int i, String arg) {
		// TODO Auto-generated method stub
		if (object instanceof String) {
			freeswitch.console_log("notice", "DTMF: " + (String) object
					+ " ARG: " + arg + "\n");
			// digits = digits + (String) object;
			String Digit = (String) object;
			if (Digit.equals("0")) {
				return "break";
			}
		} else
			freeswitch.console_log("notice",
					"WOW GOT AN EVENT: " + object.toString());
		return "true";
	}

	@Override
	public void run(String arg0, String arg1) {
		// TODO Auto-generated method stub

	}

	public void call() {

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

						// *****************MP3 File selction********//
						Schedule = Schedule.substring(0, Schedule.length() - 2);
						ResultSet fst = con.createStatement().executeQuery(
								"Select * from Apps_context where Identifier='"
										+ Caller + Schedule + "'");
						Debug("Select * from Apps_context where identifier='"
								+ Caller + Schedule + "'\n");
						String fname = "";
						if (fst.next()) {
							fname = fst.getString(4);
						}
						String dir = "/usr/local/freeswitch/sounds/broadcast/";
						Debug("playing file" + dir + fname);
						session.streamFile(dir + fname, 0);
						HangupCause = session.hangupCause();
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
	}

	private void Debug(String str) {
		// TODO Auto-generated method stub
		freeswitch.consoleLog("DEBUG", "<" + SCRIPT_NAME + ">" + str + "\n");
	}

	public void update(String Query) {
		Connection con = new DatabaseHandler().getConnection();
		try {
			Debug(Query);
			con.createStatement().executeUpdate(Query);
			con.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				con.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

	}

}
