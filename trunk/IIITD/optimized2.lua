-- INCLUDES
require "luasql.odbc";

-- TODO: figure out how to get the local path
dofile("/usr/local/freeswitch/scripts/IIITD/paths.lua");
dofile("/usr/local/freeswitch/scripts/IIITD/common.lua");
--dofile("/usr/local/freeswitch/scripts/IIITD/function.lua");

script_name = "project37.lua";
digits = "";
arg = {};

sessid = os.time();
userid = 'nil';
adminforums = {};
line_num = session:getVariable("destination_number");
aosd = basedir .. "/scripts/IIITD/sounds/";		
phonenum = session:getVariable("caller_id_number");
phonenum = phonenum:sub(-10);
input="";
		

--------------------------
--to validate the caller--
--------------------------

function validate_caller()
	


	while (session:ready() == true) do
   		query = "select Phone_no, question from I_Caller where Phone_no = " .. phonenum ;
   		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
   		cur = con:execute(query);
   		row = {};result = cur:fetch(row);
   		cur:close();
   		if (tostring(row[1]) ~= 'nil' and row[2]=='N') then
      			
			role = "guest";
			break;
   		end


		if (tostring(row[1]) == 'nil' or tostring(row[2])=='nil') then
      			
			role="guest";
			query3 = "insert into I_Caller(Phone_no,question) values (" .. phonenum .. ",'N')" ;
      			con:execute(query3);
			break;
			
		end	
		

		if (tostring(row[1]) ~= 'nil' and row[2] == 'Y') then
			
			role="aspirant";		
			break;
		end
	


		query = "select * from Responder where Responder_no = " .. phonenum ;
   		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
   		cur = con:execute(query);
   		row = {};result = cur:fetch(row);
   		cur:close();
		
		if(tostring(row[1])=='nil' or tostring(row[2])=='nil')then
				
			role="guest";
			break;
					
		else
			role="responder";
		end
		


   	

	end
end



--------------------------
-------responder menu---------
--------------------------


function responder_menu()
	
	
	session:answer();
	session:setAutoHangup(false);
	session:set_tts_parms("flite","rms");

	session:speak("welcome responder");
	session:sleep(100);
	
	session:speak("press two for replying any question and nine to quit");
	session:sleep(200);

	
	
	query = "SELECT * FROM R_ques_ans WHERE responder_ans = 'NULL'";
	freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
	cur = con:execute(query);
	row = {};result = cur:fetch(row);
	cur:close();
	
	local x='nil';
	freeswitch.consoleLog("info", script_name .. " : debug ..... ");
	for row in rows(query) do
			freeswitch.consoleLog("info", script_name .. " : SQL answer is = " .. tostring(row[1]) .. "\n");
			if(tostring(row[1])=='nil')then
					session:speak("there are no unanswered questions in database");
					session:sleep(200);
					break;
			else



				read(sd .. "/Q/" .. row[2],0);
				
				read(aosd .. "/Responder/To_record.wav",0);
				read(aosd .. "/Digits/2.wav",500)
		
				digits = session:getDigits(1,"",3000);
				if(digits=="2")then
				
					recordreply(row[1]);
					
				else
					if(digits=="9")then
						
						break;		
					end
				end	
			
			end
	
	end	
		
	session:speak("thank you for your responses");
	session:sleep(100);
	session:speak("have a great day");


end


--------------------------
--recording the response--
--------------------------

function recordreply(Qid)
	local partfilename =  os.time() .. ".mp3";
	local filename = sd .. "/A/" .. partfilename;
	local maxlength = 60000;
	session:speak("Press # When you are done wid your recording");
	repeat
      		read(aosd .. "/Responder/Record_Ans.wav", 1000);
      		local d = use();

      		if (d == GLOBAL_MENU_MAINMENU) then
	 		return d;
      		end
	
	
      		session:execute("playback", "tone_stream://%(500, 0, 620)");
      		freeswitch.consoleLog("info", script_name .. " : Recording " .. filename .. "\n");
      		logfile:write(sessid, "\t",
		    session:getVariable("caller_id_number"), "\t", session:getVariable("destination_number"), "\t", 
		    os.time(), "\t", "Record", "\t", filename, "\n");
      		session:execute("record", filename .. " " .. maxlength .. " 100 5");
      		--sleep(1000);
      		d = use();
      		-----------------------------------------------------------------------
		 if(session:ready() == false) then
			freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>0 >>> User Disconnected");
			hangup();
			break;
		end
		------------------------------------------------------------------
      		if (d == GLOBAL_MENU_MAINMENU) then
		 	os.remove(filename);
		 	return d;
      		end
      
      		local review_cnt = 0;
      		while (d ~= GLOBAL_MENU_MAINMENU and d ~= "1" and d ~= "2" and d ~= "3") do
			read(aosd .. "hererecorded.wav", 1000);
		 	read(filename, 1000);
		 	read(aosd .. "notsatisfied.wav", 2000);
		 	sleep(6000)
		 	d = use();
		 	-----------------------------------------------------------------------
		 	if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>1 >>> User Disconnected");
				hangup();
				break;
			end
			------------------------------------------------------------------
	       		--review_cnt = check_abort(review_cnt, 6)
      		end
      
     		if (d ~= "1" and d ~= "2") then
	 	 	os.remove(filename);
		 	if (d == GLOBAL_MENU_MAINMENU) then
		    		return d;
		 	elseif (d == "3") then
		    		read(aosd .. "messagecancelled.wav", 500);
		    		return use();
		 	end
		 	-----------------------------------------------------------------------
		 	if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>2 >>> User Disconnected");
				hangup();
				done = 1; --Before Sending SMS check	
				break;
			end
			------------------------------------------------------------------
    		end
    		
    		-------------------------------------------
		--if(tostring(d) == 'nil') then
			if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>3 >>> User Disconnected");
				hangup();
				break;
			end
		--end
		-------------------------------------------
    	
	until (d == "1");

-------------------------
--database updation------
-------------------------
	if(session:ready() == true) then
		
		query1 = "update R_ques_ans set responder_ans='" .. partfilename .. "' where user_id = " .. Qid .. "";
   		con:execute(query1); 		
	
	end

end


--------------------------
-------guest menu---------
--------------------------

function guest_menu()

	
	session:answer();
	session:setAutoHangup(false);
	session:set_tts_parms("flite","rms");
	session:speak("welcome to the admission ivr system");
	
	while(session:ready()==true)do
		
		
		local flag = Nodes();
		
		if(flag == 1)then
			break;
		end
		
	end

end


function Nodes()

		
		query = "SELECT * FROM Nodes WHERE level_id like '".. input .. "_'";
   		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
   		cur = con:execute(query);
   		row = {};result = cur:fetch(row);
   		cur:close();
		local i=1;		

		for row in rows(query) do
			
			

			if(tostring(row[1])== input ..'*') then
				
				local flag1=checkfunc(tostring(row[1]),tostring(row[2]),tostring(row[3]));
				
				if(flag1==1)then
					session:sleep(100);
					session:speak("now you will be routed back to main menu");
					input = "";					
				
				else
	
					session:speak(tostring(row[2]));
					return 1;
				end
				
			else	
				session:speak(tostring(row[2]) .. " press " .. i);
				session:sleep(100);
				i=i+1;
				digits=session:getDigits(1,"",1000);

				
				if(tostring(digits)~='')then

					if(digits == "9")then
						return 1;					
					else
					
					
						freeswitch.consoleLog("info", script_name .. " : Got Digit value is: " .. tostring(digits) .. "\n");
						input = input .. tostring(digits);

						return 0;
					end	
				else
					
				end
			end			
						
  		end

end


-------------------------


function checkfunc(id,func,tag)

	if(func=="get_ques()") then
		freeswitch.consoleLog("info", script_name .. " : Debug 1 " .. "\n");
		get_ques(id,tag);
		return 1;
	end
		
	if(func=="record_my_question()") then
		record_my_question();
		return 1;
	end	

	if(func=="play_my_response()") then
		play_my_response();
		return 1;
	else


		return 0;
	end
		

end
----------------------------------------------------------------------------------------------
----caller recording the questions
----------------------------------------------------------------------------------------------



function record_my_question()

	local partfilename =  os.time() .. ".mp3";
	local filename = sd .. "/Q/" .. partfilename;
	local maxlength = 60000;
	session:speak("Press # When you are done wid your recording");
	repeat
      		read(aosd .. "/voiceprompt/Record_Q.wav", 1000);
      		local d = use();

      		if (d == GLOBAL_MENU_MAINMENU) then
	 		return d;
      		end
	
	
      		session:execute("playback", "tone_stream://%(500, 0, 620)");
      		freeswitch.consoleLog("info", script_name .. " : Recording " .. filename .. "\n");
      		logfile:write(sessid, "\t",
		    session:getVariable("caller_id_number"), "\t", session:getVariable("destination_number"), "\t", 
		    os.time(), "\t", "Record", "\t", filename, "\n");
      		session:execute("record", filename .. " " .. maxlength .. " 100 5");
      		--sleep(1000);
      		d = use();
      		-----------------------------------------------------------------------
		 if(session:ready() == false) then
			freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>0 >>> User Disconnected");
			hangup();
			break;
		end
		------------------------------------------------------------------
      		if (d == GLOBAL_MENU_MAINMENU) then
		 	os.remove(filename);
		 	return d;
      		end
      
      		local review_cnt = 0;
      		while (d ~= GLOBAL_MENU_MAINMENU and d ~= "1" and d ~= "2" and d ~= "3") do
			read(aosd .. "hererecorded.wav", 1000);
		 	read(filename, 1000);
		 	read(aosd .. "notsatisfied.wav", 2000);
		 	sleep(6000)
		 	d = use();
		 	-----------------------------------------------------------------------
		 	if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>1 >>> User Disconnected");
				hangup();
				break;
			end
			------------------------------------------------------------------
	       		--review_cnt = check_abort(review_cnt, 6)
      		end
      
     		if (d ~= "1" and d ~= "2") then
	 	 	os.remove(filename);
		 	if (d == GLOBAL_MENU_MAINMENU) then
		    		return d;
		 	elseif (d == "3") then
		    		read(aosd .. "messagecancelled.wav", 500);
		    		return use();
		 	end
		 	-----------------------------------------------------------------------
		 	if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>2 >>> User Disconnected");
				hangup();
				done = 1; --Before Sending SMS check	
				break;
			end
			------------------------------------------------------------------
    		end
    		
    		-------------------------------------------
		--if(tostring(d) == 'nil') then
			if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from recordreply>>>3 >>> User Disconnected");
				hangup();
				break;
			end
		--end
		-------------------------------------------
    	
	until (d == "1");

-------------------------
--database updation------
-------------------------
	if(session:ready() == true) then
		
		query1 = "insert into R_ques_ans (caller_ques, Phone_no) values('" .. partfilename .. "','" .. phonenum .. "')";
   		con:execute(query1); 		
	
	end

end
----------------------------------------------------------------------------------------------------
------------play responses of the caller...
----------------------------------------------------------------------------------------------------
function play_my_response()

	query = "select responder_ans from R_ques_ans where Phone_no = '" .. phonenum .. "'";
   	freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
	cur = con:execute(query);
   	row = {};result = cur:fetch(row);
   	cur:close();			
	
	for row in rows (query) do
		
		if(tostring(row[1])=='nil')then
			session:speak("there are no responses ");
			session:sleep(100);
			break;	
		end

		local dir = sd.. "/A/" .. tostring(row[1]);
		session:streamFile(dir);
		digits=session:getDigits(1,"",1000);
		if(digits=="9")then
			break;
		end	 
		
	end	




end


-----------------------------------------------------------------------------------------------------
function get_ques(id,tag)
	local z = "0";
	local i = 0;
	local Questionid = {};
	local file = {};
   	query = "SELECT * FROM Questions WHERE Keywords like '%" .. tag .. "%'";
   	freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
	cur = con:execute(query);
   	row = {};result = cur:fetch(row);
   	cur:close();   	
	session:speak("you can press 2 any time to listen the reply of ongoing question");
	session:sleep(200);

        for row in rows (query) do
      		i = i + 1;
      		Questionid[i] = row[1];
      		file[i] = row[3];
      		dir_Q = sd .. "/Pre_def_Q/" .. file[i];
      		z = playfile(dir_Q);
      		if (z=="2") then
         		get_reply(row[1]);
      		end
   	end
	if (i==0) then
		read(aosd .. "/nomessages.wav",500);
	end
end
------------------------------------------------------------------------------------------------------

----------------------
--Playfile
----------------------
function playfile(file_name)
	arg[1] = file_name;
	
	freeswitch.consoleLog("info", script_name .. " : playing " .. file_name .. "\n");
	session:streamFile(file_name);
	session:sleep(500);
	
	
	digits = session:getDigits(1,"",3000);
	return tostring(digits);


end
---------------------------------------------------------------------------------------


----------------------
--Playreply
---------------------
function get_reply(Q_id)
	query="select reply_text FROM Replies WHERE reply_id = (SELECT reply_id FROM Mapping WHERE question_id ='" .. Q_id .. "')";
	freeswitch.consoleLog("info", script_name .. " : playing " .. query .. "\n");
	cur = con:execute(query);
   	row = {};result = cur:fetch(row);
   	cur:close();	
	
	local i = 0;
	local file = {};
   	for row in rows (query) do
      		i = i + 1;
      		file[i] = row[1];
      		dir_A = sd .. "/Pre_def_A/" .. file[i];
      		arg[1] = dir_A;
		freeswitch.consoleLog("info", script_name .. " : playing " .. dir_A .. "\n");
      		session:streamFile(dir_A);
      		d = use();
      		if (d == GLOBAL_MENU_MAINMENU or d == GLOBAL_MENU_SKIP_BACK or d == GLOBAL_MENU_SKIP_FWD) then
       			return d ;
      		end
   	end
	if (i==0) then
		read(aosd .. "/voiceprompt/no_ans.wav");
	end
end

--------------------------

--------------------------


session:answer();
session:setVariable("playback_terminators", "#");
session:setHangupHook("hangup");
session:setInputCallback("my_cb", "arg");
freeswitch.consoleLog("info", script_name .. " : debug " .. "\n");
validate_caller();
freeswitch.consoleLog("info", script_name .. " : actual caller_id " .. phonenum .. "\n");
session:setVariable("phonenum", phonenum);
--generate a menu
session:set_tts_parms("flite", "rms");
while (session:ready() == true) do
	if (role == "responder") then
		responder_menu();
	end
	if (role == "guest") then
		responder_menu();
	end
	if (role == "aspirant") then
		responder_menu();
	end
	
	
	session:speak("Thank you for calling and have a good day");	
	break;
end
session:hangup();
