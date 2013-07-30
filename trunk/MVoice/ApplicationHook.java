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

import org.freeswitch.swig.JavaSession;



public class ApplicationHook implements Runnable {
  private String App;

  ApplicationHook(String Appname) {
    this.App = Appname;
  }

  @Override
  public void run() {
		try {
			Class IVRApp = Class.forName(App);
			Object obj = IVRApp.newInstance();
			IVRApp.getDeclaredMethod("call").invoke(obj);
		} catch (ClassNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (SecurityException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NoSuchMethodException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalArgumentException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InvocationTargetException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InstantiationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
//		Object obj = IVRApp.newInstance();
	//	Object r = m.invoke(obj, new Object[] { session, Callid });

  }
} 