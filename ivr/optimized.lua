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
-------------------
-- Function to store SMS
-------------------
function send_sms(message,number)
	query1 = "insert into sms_sent(request_time,phone,message,sent_time,sent) values(now(),'"..number.."','"..message.."',NULL,'n')";
	con:execute(query1); 
	freeswitch.consoleLog("info"," : SQL Querry = " .. query1 .. "\n");
end

-----------------
--Speak
-----------------
function speak(message)
  session:execute("set_audio_level", "write 4");
  session:speak(message);
  session:execute("set_audio_level", "write -1");
end
-----------------
--responder menu
-----------------

function responder_menu()
	query = "Select I_question.QuestionID, file_name from I_question, I_assignment where I_question.QuestionID = I_assignment.questionid  AND I_assignment.assignedto =" .. userid .. " AND I_assignment.replied = 'n'";
	reply_Q(query);
end
-----------------
-- reply Q
-----------------
function reply_Q(query)
	local z = "0";
	local i = 0;
	local Questionid = {};
	local file = {};
	for row in rows (query) do
		i = i + 1;
      		Questionid[i] = row[1];
      		file[i] = row[2];
      		dir_Q = sd .. "/Q/" .. file[i];
      		z = playfile(dir_Q);
      		freeswitch.consoleLog("info", script_name .. " : Reply Dtmf " .. z .. "\n");
      		if (z=="2") then
        		recordreply(Questionid[i]);
      		end
   	end

	if (i==0) then
		read(aosd .. "/nomessages.wav",0);
	end
end
-----------------
--record reply
-----------------
function recordreply(Qid)
	local partfilename =  os.time() .. ".mp3";
	local filename = sd .. "/A/" .. partfilename;
	local maxlength = 60000;
	speak("Press # When you are done wid your recording");
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
--------------
--database updation
--------------
	if(session:ready() == true) then
		query1 = "insert into I_answer (questionid ,posting_date , repliedby, file_name) values (" .. Qid .. ",curdate()," .. userid .. ",'" .. partfilename .. "')";
   		con:execute(query1); 
		query2 = "update I_assignment set replied = 'y' where questionid = " .. Qid;
   		con:execute(query2);
		query3 = "select phone from I_students where studentID = (select Askedby from I_question where QuestionID = "..Qid..")"
		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query3 .. "\n");
		cur = con:execute(query3)
		row = {};
		result = cur:fetch(row);
		cur:close();
		if (tostring(row[1]) ~= 'nil') then
			numbertosendsms = tostring(row[1]);
			freeswitch.consoleLog("info", "Number to be SMS sent to be is -->>"..numbertosendsms.."\n");
			send_sms("Your Query has been Answered --Message From IVR IIITD",numbertosendsms);
		end
	end
end
--------------
--student menu
--------------
function student_menu()

	session:read(0, 0, aosd .. "/voiceprompt/Select_subj.wav", 1000, "#");
	local i = 0;
	local subjects = {};
	local subjectid = {};
	query = "select I_course_registered.subjectID, Title from I_course_registered, I_subjects ";
	query = query .. "where I_course_registered.subjectID = I_subjects.subjectID and I_course_registered.studentID = " .. userid ;
	freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
	repeat
   		i = 0;
        	for row in rows (query) do
      	    		i = i + 1;
      	    		subjectid[i] = row[1];
      	    		subjects[i] = row[2];
            		dir_Forum = aosd .. "Forum/";
            		read(aosd .. "listento_pre.wav", 0);
            		read(dir_Forum .. subjects[i] .. ".wav",0);
    			--read(aosd .. "listento_post.wav", 0);
            		read(aosd .. "/Digits/" .. i .. ".wav", 2000);
        	end
        	d = tonumber(use());
		chk_session();
		-------------------------------------------
		--if(tostring(d) == 'nil') then
			if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from student_menu >>> User Disconnected");
				hangup();
				break;
			end
		--end
		-------------------------------------------

	until (tostring(tonumber(d)) ~= 'nil');
	local z = -1 ;
	z = tonumber(d);
	if ((z > 0) and z < (i+1)) then
   		freeswitch.consoleLog("info", script_name .. " : The user is = " .. userid .. " and have pressed " .. tostring(d) .. "\n");
   		freeswitch.consoleLog("info", script_name .. " : The user is = " .. userid .. " and have chosen subject " .. subjects[z] .. "\n");
   		subject_handler(subjectid[z]);
	else
		speak("Invalid key has been pressed!!");
	end
end
---------------------------
--Subject Handler
---------------------------
function subject_handler(subj_id)
	repeat
   		read(aosd .. "/voiceprompt/Own_Q_A.wav",0);
   		read(aosd .. "/Digits/1.wav", 1000);
   		read(aosd .. "/voiceprompt/Another_Q_A.wav",0);
   		read(aosd .. "/Digits/2.wav", 1000);
   		sleep(500);
   		d = tonumber(use());
   		freeswitch.consoleLog("info", script_name .. " : The user is = " .. userid .. " and pressed " .. tostring(d) .. "\n");
		if (d==1) then
   			repeat
   				read(aosd .. "/voiceprompt/Question.wav",0);
   				read(aosd .. "/Digits/1.wav",1000);
   				read(aosd .. "/voiceprompt/Answer.wav",0);
   				read(aosd .. "/Digits/2.wav",100);
   				d = tonumber(use());
   				freeswitch.consoleLog("info", script_name .. " : The user is = " .. userid .. " and pressed " .. tostring(d) .. "\n");
   				if (d==1) then
					recordQ(subj_id,userid,60000);
   				elseif (d==2) then
        				---Select Question
      					query = "select QuestionID, file_name from I_question where Askedby = " .. userid .. " AND subject_id = " .. subj_id;
      					select_Q(query);
   				end
   				
   				-------------------------------------------
				--if(tostring(d) == 'nil') then
					if(session:ready() == false) then
						freeswitch.consoleLog("info", script_name .. "Message from subject_handler>>>1 >>> User Disconnected");
						hangup();
						break;
					end
				--end
				-------------------------------------------
   				
   			until (d ~=nil);
		elseif (d==2) then
   			read(aosd .. "/voiceprompt/next_Q.wav",0);
   			query = "select QuestionID, file_name from I_question where Askedby != " .. userid .. " AND subject_id = " .. subj_id;
   			select_Q(query);
		end
		
		-------------------------------------------
		--if(tostring(d) == 'nil') then
			if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from subject_handler>>>2 >>> User Disconnected");
				hangup();
				break;
			end
		--end
		-------------------------------------------
		
	until (d ~= nil);
end
--------------------------
-- Record Message
-------------------------
function recordQ (subj_id, askedby, maxlength)
	local partfilename =  os.time() .. ".mp3";
	local filename = sd .. "/Q/" .. partfilename;
	speak("Press # When you are done with your recording");
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
      		---------------------------------------------------------
      		if(session:ready() == false) then
			freeswitch.consoleLog("info", script_name .. "Message from recordQ>>>0 >>> User Disconnected");
			hangup();
			break;
		end
		--------------------------------------------------------
      		--sleep(1000);
      		d = use();
      		
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
	       		--review_cnt = check_abort(review_cnt, 6)
	       		-------------------------------------------
			--if(tostring(d) == 'nil') then
				if(session:ready() == false) then
					freeswitch.consoleLog("info", script_name .. "Message from recordQ>>>2 >>> User Disconnected");
					hangup();
					break;
				end
			--end
			-------------------------------------------
      		end
      		
      		      
     		if (d ~= "1" and d ~= "2") then
	 	 	os.remove(filename);
		 	if (d == GLOBAL_MENU_MAINMENU) then
		    		return d;
		 	elseif (d == "3") then
		    		read(aosd .. "messagecancelled.wav", 500);
		    		return use();
		 	end

     		end
     		
     		
   	until (d == "1");
	freeswitch.consoleLog("info", script_name .. " : Database Updation taking place " .. "\n");

   	query1 = "insert into I_question (Askedby , subject_id ,posting_date, file_name) values (" .. askedby .. "," .. subj_id .. ",curdate(),'" .. partfilename .. "')";
   	con:execute(query1); 
   	freeswitch.consoleLog("info", script_name .. " : SQL Querry " .. query1 .. "\n");

   	cur = con:execute("SELECT LAST_INSERT_ID()");
   	Qid = tostring(cur:fetch());
   	cur:close();
	freeswitch.consoleLog("info", script_name .. " : Database Generated Qid " .. Qid .. "\n");

   	query2 = "select Responder_id from I_Responder where subject =" .. subj_id;
   	local Responderid = {};
   	local i = 0;
   	for row in rows (query2) do
      		i = i + 1;
      		Responderid[i] = row[1];
      		query3 = "insert into I_assignment(questionid,posting_date , assignedto , replied ) values (" .. Qid .. ", curdate()," .. Responderid[i] .. ", 'n')" ;
      		con:execute(query3); 
		freeswitch.consoleLog("info", script_name .. " : SQL Querry " .. query3 .. "\n")

		--Send SMS now to all Responders
		query4 = "select phone from I_Responder where Responder_id = "..Responderid[i]
		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query4 .. "\n");
		cur = con:execute(query4)
		rowsms = {};
		resultsms = cur:fetch(rowsms);
		cur:close();
	
		if (tostring(rowsms[1]) ~= 'nil') then
			numbertosendsms = tostring(rowsms[1]);
			freeswitch.consoleLog("info", "Number to be SMS sent to be is -->>"..numbertosendsms.."\n");
			send_sms("You have a question for you --Message From IVR IIITD",numbertosendsms);
		end
   	end
 
   return use();

end
-----------------------
-- Select_Q
----------------------
function select_Q(query)
	local z = "0";
	local i = 0;
	local Questionid = {};
	local file = {};
   	for row in rows (query) do
      		i = i + 1;
      		Questionid[i] = row[1];
      		file[i] = row[2];
      		dir_Q = sd .. "/Q/" .. file[i];
      		z = playfile(dir_Q);
      		if (z=="2") then
         		playreply(row[1]);
      		end
   	end
	if (i==0) then
		read(aosd .. "/nomessages.wav",500);
	end
end
----------------------
--Playfile
----------------------
function playfile(file_name)
	arg[1] = file_name;
	speak("You can press 5 anytime to pause the current audio stream and press any key to resume the paused audio stream");
	sleep(600);
	speak("You can Press 6 to play next audio in sequence");
	freeswitch.consoleLog("info", script_name .. " : playing " .. file_name .. "\n");
	session:streamFile(file_name);
	local x = 'nil';
	repeat 
		if (role == "responder") then
			read(aosd .. "/Responder/To_record.wav",0);
			read(aosd .. "/Digits/2.wav",500)
		end
		if (role == "student") then
			read(aosd .. "/voiceprompt/Answer.wav",0);
			read(aosd .. "/Digits/2.wav",500)
			sleep(800);
			
		end
		read (aosd .. "/voiceprompt/next_Q.wav",0);
		read (aosd .. "/Digits/6.wav",500);
		x = use();
		-------------------------------------------
		--if(tostring(x) == 'nil') then
			if(session:ready() == false) then
				freeswitch.consoleLog("info", script_name .. "Message from playfile>>>2 >>> User Disconnected");
				hangup();
				break;
			end
		--end
		-------------------------------------------
	until(x ~= "");
	return x;
end
----------------------
--Playreply
---------------------
function playreply(Q_id)
	query="select file_name from I_answer where questionid = " .. Q_id;
	freeswitch.consoleLog("info", script_name .. " : playing " .. query .. "\n");
	local i = 0;
	local file = {};
   	for row in rows (query) do
      		i = i + 1;
      		file[i] = row[1];
      		dir_A = sd .. "/A/" .. file[i];
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

-----------
-- my_cb
-----------

function my_cb(s, type, obj, arg)
	freeswitch.console_log("info", "\ncallback: [" .. obj['digit'] .. "]\n")
   
   	if (type == "dtmf") then
      
      		logfile:write(sessid, "\t",
      		session:getVariable("caller_id_number"), "\t", session:getVariable("destination_number"), "\t", os.time(), "\t",
      "dtmf", "\t", arg[1], "\t", obj['digit'], "\n");
      
      		freeswitch.console_log("info", "\ndigit: [" .. obj['digit']
			     .. "]\nduration: [" .. obj['duration'] .. "]\n");
      
      		if (obj['digit'] == GLOBAL_MENU_MAINMENU) then
	 		digits = GLOBAL_MENU_MAINMENU;
	 		return "break";
      		end

      		-- This is tricky.  Note we are checking if the playback is
      		-- *already* paused, not whether the user pressed Pause.
      		if (digits == GLOBAL_MENU_PAUSE) then
	 	 	digits = "";
		 	session:execute("playback", "tone_stream://%(500, 0, 620)");
		 	return "pause";
      		end
      
      		if (obj['digit'] == GLOBAL_MENU_NEXT or obj['digit'] == "#") then
	 		digits = GLOBAL_MENU_NEXT;
	 		return "break";
      		end
      
      		if (obj['digit'] == GLOBAL_MENU_RESPOND) then	
	 		digits = GLOBAL_MENU_RESPOND;
	 		return "break";
      		end
      
      		if (obj['digit'] == GLOBAL_MENU_INSTRUCTIONS) then
	 	 	read(aosd .. "okinstructions.wav", 500);
		 	read(anssd .. "instructions_full.wav", 500);
		 	digits = use();
		 	return "break";
      		end
      
      		if (obj['digit'] == GLOBAL_MENU_SKIP_BACK) then
	 		digits = GLOBAL_MENU_SKIP_BACK;
	 		freeswitch.consoleLog("info", script_name .. ".callback() : digits = " .. digits .. "\n");
	 		return "break";
      		end

      		if (obj['digit'] == GLOBAL_MENU_PAUSE) then
	 		read(aosd .. "paused.wav", 500);
	    		digits = use();
	    		if (digits == "") then
	       			digits = GLOBAL_MENU_PAUSE;
	       		return "pause";
	    	else
	       		digits = "";
	       		session:execute("playback", "tone_stream://%(500, 0, 620)");
	    	end
      	end

      	if (obj['digit'] == GLOBAL_MENU_SKIP_FWD) then
	 	digits = GLOBAL_MENU_SKIP_FWD;
	 	return "break";
      	end

      	if (obj['digit'] == GLOBAL_MENU_SEEK_BACK) then
	 	return "seek:-10";
      	end

      	if (obj['digit'] == GLOBAL_MENU_REPLAY) then
     		digits = GLOBAL_MENU_REPLAY;
     		return "break";
      	end
              
      	if (obj['digit'] == GLOBAL_MENU_SEEK_FWD) then
	 	return "seek:+10";
      	end
      
   else
      	freeswitch.console_log("info", obj:serialize("xml"));
   end
end

--------------------------
function validate_caller()
	local cnt = 1;
	local cnt2 = 1;
	while (session:ready() == true) do
   		query = "select studentID from I_students where phone = " .. phonenum ;
   		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
   		cur = con:execute(query);
   		row = {};result = cur:fetch(row);
   		cur:close();
   		if (tostring(row[1]) ~= 'nil') then
      			freeswitch.consoleLog("info", script_name .. " : Database registered with Phone = " .. phonenum .. " and has userid = " .. tostring(row[1]) .. "\n");
      			if (cnt == 1) then
         			userid = tostring(row[1]);
         			cnt = 2;
      			end
      			if (userid ~= 'nil') then
         			if (userid == tostring(row[1])) then
            				freeswitch.consoleLog("info", script_name .. " : IT has matched userid = " .. userid .. "\n");
            				role = "student";
           			 	break ;
         			else
            			--you have supplied wrong credentials.
            				session:read(0, 0, aosd .. "/System/Auth_fail.wav", 2000, "#");
--            				hangup();
         			end
      			else
         			userid = tostring(row[1]);
      			end
   		end
   		query = "select Responder_id from I_Responder where phone = " .. phonenum ;
   		cur = con:execute(query);
   		row = {};
   		result = cur:fetch(row);
   		cur:close();
   		if (tostring(row[1]) ~= 'nil') then
      			if (cnt2 == 1) then
         			userid = tostring(row[1]);
         			cnt2 = 2;
      			end
      			if (userid ~= 'nil') then
         			if (userid == tostring(row[1])) then
            				freeswitch.consoleLog("info", script_name .. " : IT has matched userid = " .. userid .. "\n");
            				role = "responder";
            				break ;
         			else
            				--you have supplied wrong credentials.
            				session:read(0, 0, aosd .. "/System/Auth_fail.wav", 2000, "#");
            				--hangup();
         			end
      			else
         			userid = tostring(row[1]);
      			end
   		end
      
		--Your phonenum didnt match the database...please enter your phonenum and userid
		--read(aosd .. "/Rang Rang.mp3", 500);
		demand_credentials();
   		freeswitch.consoleLog("info", script_name .. " : phonenum = " .. phonenum .. "\n");
   		freeswitch.consoleLog("info", script_name .. " : userid = " .. userid .. "\n");
   		---------------------------------------------------------------------------------------------------------
     		if (session:ready() == true) then
			freeswitch.consoleLog("info", "Message from Validate Caller >>> Session is still active \n");
		else
			freeswitch.consoleLog("info", "Message from Validate Caller >>> User Disconnected the call \n");
			hangup();
			break;
		end   
 		chk_session();
 		---------------------------------------------------------------------------------------------------------
	end
end
-----------------------
function chk_session()
	if (session:ready() == true) then
		freeswitch.consoleLog("info", "Message from chk_session >>> Session is still active \n");
	else
		freeswitch.consoleLog("info", "Message from chk_session >>> User Disconnected the call \n");
		hangup();
	end
end
-----------------------
function demand_credentials()
	repeat
   		phonenum = session:read(10, 10, aosd .. "/System/Mobile_number.wav", 4000, "#");
   		freeswitch.consoleLog("info", script_name .. " : demand_credential got phonenum = " .. tostring(phonenum) .. "\n");
   		chk_session();
		-------------------------------------------
		--if(tostring(phonenum) == 'nil') then
			if(session:ready() == false) then
				hangup();
				freeswitch.consoleLog("info", "Message from demand_crendentials>>>1 >>> User Disconnected the call \n");
				break;
			end
		--end
		-------------------------------------------

   	until (tostring(tonumber(phonenum))~='nil');
   	repeat
   		
   		userid = session:read(1, 10, aosd .. "/System/userid.wav", 1500, "#");
   		chk_session();
   		if (session:ready() == true) then
   			freeswitch.consoleLog("info", "Session is still active \n");
   		else
   			hangup();
   			freeswitch.consoleLog("info", "Message from demand_crendentials>>>3 >> User Disconnected the call \n");
   			break;
   		end

   	until (tostring(tonumber(userid)) ~= 'nil');
end
-----------------------

session:answer();
session:setVariable("playback_terminators", "#");
session:setHangupHook("hangup");
session:setInputCallback("my_cb", "arg");
session:set_tts_parms("flite", "rms");
session:execute("set_audio_level", "write -1");
session:execute("set_audio_level", "read 4");
--speak("hi testing for volume");
validate_caller();
freeswitch.consoleLog("info", script_name .. " : actual caller_id " .. phonenum .. "\n");
session:setVariable("phonenum", phonenum);
--generate a menu

while (session:ready() == true) do
	if (role == "responder") then
		responder_menu();
	end
	if (role == "student") then
		student_menu();
	end
	speak("press 9 to exit");
	ans = session:read(1,1,"",3000,"#");
	if (tostring(tonumber(ans))=='9') then
		break;
	end
end
hangup();
