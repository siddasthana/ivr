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
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.concurrent.TimeUnit;

import org.freeswitch.swig.JavaSession;
import org.freeswitch.swig.freeswitch;
import java.util.concurrent.TimeUnit;

public class outgoing {
	boolean debug = true;
	private String Appid;
	private String Gatewayid;
	private JavaSession session = null;
	private String Callid;

	public JavaSession call(String Caller, String App) {
		Connection con = new DatabaseHandler().getConnection();
		String Query = "Select t.Name , App_id, Gateway_id from Apps_registration as t, Gateway_registration, Apps_gatewayassociation where App_id = ";
		Query += " t.id and Gateway_id = Gateway_registration.id and Call_Type='OUT' and t.Name = '"
				+ App + "'";
		Debug(Query);

		ResultSet rs;
		try {
			rs = con.createStatement().executeQuery(Query);
			if (rs.next()) {

				// App = rs.getString(1);
				Appid = rs.getString(2);
				Gatewayid = rs.getString(3);
			}
			if (Appid != null) {
				Query = "insert into Call_history(Caller,Call_Type, Gateway_id, Hangup_Cause, Time_stamp, Date_stamp, App_id) ";
				Query += " value('" + Caller + "','OUT'," + Gatewayid
						+ ",'', NOW(), NOW()," + Appid + ")";

				Debug(Query);
				con.createStatement().executeUpdate(Query);
				ResultSet li = con.createStatement().executeQuery(
						"Select LAST_INSERT_ID()");
				if (li.next()) {
					Callid = li.getString(1);
					if (Caller.startsWith("0091")) {

						Caller = Caller.substring(4);
						System.out.println("Trimmed 4 digits:" + Caller);
					}
					// 9493761722
					Query = "select t.* from Gateway_registration t, Apps_gatewayassociation ";
					Query += "where t.id = Apps_gatewayassociation.Gateway_id and Apps_gatewayassociation.App_id ="
							+ Appid;
					Query += " and  Apps_gatewayassociation.Call_Type=\"OUT\"";
					ArrayList<String> Gateways = Gateway(Query);
					for (String gateway : Gateways) {
						String dialstring = "";
						String dialsuffix = "";
						if (!gateway.split(",")[0].equals(null)) {
							Gatewayid = gateway.split(",")[0];
						}
						if (!gateway.split(",")[1].equals(null)) {
							dialstring = gateway.split(",")[1];
						}

						if (gateway.split(",").length > 2) {
							dialsuffix = gateway.split(",")[2];
						}

						session = new JavaSession(
								"{ignore_early_media=true, Cid=" + Callid + "}"
										+ dialstring + Caller + dialsuffix);
						if (session.ready()) {
							Query = "Update Call_history set Gateway_id="
									+ Gatewayid + " where id=" + Callid;
							Debug(Query);
							con.createStatement().executeUpdate(Query);
							break;
						}
					}
					// session = new
					// JavaSession("{ignore_early_media=true, Cid="+Callid
					// +"}gsmopen/gsm03/"+Caller);
					// session = new
					// JavaSession("{ignore_early_media=true, Cid="+Callid
					// +"}sofia/internal/0"+Caller+"@192.168.0.197:5060");
					System.out.println("After making calls:" + Caller);
					if (session.ready()) {
						return session;
					} else {
						String obCause = session.hangupCause();

						freeswitch.consoleLog("info",
								"obSession:hangupCause() = " + obCause);
						Query = "Update Call_history set Hangup_Cause='"
								+ obCause + "' where id =" + Callid;
						Debug(Query);
						con.createStatement().executeUpdate(Query);
						if (obCause.equals("NORMAL_CIRCUIT_CONGESTION")) {
							Debug("NORMAL_CIRCUIT_CONGESTION \n");

							return null;

						}
						if (obCause.equals("DESTINATION_OUT_OF_ORDER")) {
							Debug("DESTINATION_OUT_OF_ORDER \n");
							return null;

						}

						if (session != null)
							session = null;
						return session;
					}

				}
			}
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

		return session;
	}

	private ArrayList<String> Gateway(String query) {
		Connection con = null;
		ArrayList<String> Gateways = new ArrayList<String>();
		// TODO Auto-generated method stub
		try {
			con = new DatabaseHandler().getConnection();
			ResultSet li = con.createStatement().executeQuery(query);
			while (li.next()) {
				String gateway = "";
				if (!li.getString(1).equals(null))
					gateway = li.getString(1) + ",";
				else {
					gateway = ",";
				}
				if (!li.getString(6).equals(null))
					gateway += li.getString(6) + ",";
				else {
					gateway += ",";
				}
				if (!li.getString(7).equals(null))
					gateway += li.getString(7);
				else {
					gateway += "";
				}
				Gateways.add(gateway);
			}
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
		return Gateways;
	}

	public void Debug(String str) {
		if (debug) {
			freeswitch.consoleLog("Debug", "<Outgoing>" + str+"\n");
		}
	}
}
