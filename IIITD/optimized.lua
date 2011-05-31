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
rep = "N";		

--------------------------
--to validate the caller--
--------------------------

function validate_caller()
	


	while (session:ready() == true) do
   		query = "select * from I_Caller where Phone_no = " .. phonenum ;
   		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
   		cur = con:execute(query);
   		row = {};result = cur:fetch(row);
   		cur:close();
   		if (tostring(row[1]) ~= 'nil' and tostring(row[2])=="N") then
      			
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
	


		query = "select * from Responder where Responder_no = '" .. phonenum .."'";
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

	
	read(aosd .. "/prompts/welcome.wav",200);
	
	read(aosd .. "/prompts/option.wav",200);

	
	
	query = "SELECT * FROM R_ques_ans WHERE responder_ans is NULL";
	freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
	cur = con:execute(query);
	row = {};result = cur:fetch(row);
	cur:close();
	
	local x='nil';
	freeswitch.consoleLog("info", script_name .. " : debug ..... ");
	
	if(tostring(row[1])=='nil')then
					read(aosd .. "/prompts/noQ.wav",200);
	else				
		
		for row in rows(query) do
				freeswitch.consoleLog("info", script_name .. " : SQL answer is = " .. tostring(row[1]) .. "\n");
				local dir_Q = sd .. "/Q/" .. row[2] .. "";
				
				z = playfile(dir_Q);
		      		if (z=="2") then
		         		recordreply(row[1]);
					
				else
					if(digits=="9")then
						
						break;		
					end
				end	
			
		end
	
	end	

end


--------------------------
--recording the response--
--------------------------

function recordreply(Qid)
	local partfilename =  os.time() .. ".mp3";
	local filename = sd .. "/A/" .. partfilename;
	local maxlength = 60000;
	read(aosd .. "/prompts/hash.wav",200);
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

		query3 = "insert into Replies (reply_text) values ('" .. partfilename .. "')" ;
   		con:execute(query3);
		
		query2 = "update Mapping set reply_id = (select reply_id from Replies where reply_text = '".. partfilename .."') where question_id = (select question_id from Questions where question_text= (select caller_ques from R_ques_ans where responder_ans='".. partfilename .."') ) and reply_id is NULL";
	
		con:execute(query2);		
	
		
	end

end


--------------------------
-------guest menu---------
--------------------------

function guest_menu(index)

	
	session:answer();
	session:setAutoHangup(false);
	session:set_tts_parms("flite","rms");
	local welcome = aosd .. "/menu/0.wav";
	read(welcome,200);
 

	
	while(session:ready()==true)do
		
		
		local flag = Nodes(index);
		
		if(flag == 1)then
			
			read(aosd .. "/prompts/go back.wav",3000);
			
			d=use();
			freeswitch.consoleLog("info", script_name .. " : digit is ----====+++++  = " .. d .. "\n");			
											
			if(d=="0")then
				input = "";
				digits = "";
			else
				if(d=="8")then
					freeswitch.consoleLog("info", script_name .. " : input was ++++++  = " .. input .. "\n");
					local j = string.len(input);
					freeswitch.consoleLog("info", script_name .. " : length of the input is  = " .. j .. "\n");
					--input = string.sub(input,1,tonumber(j-1));
					input = input:sub(1,tonumber(j-1));
					freeswitch.consoleLog("info", script_name .. " : input is ======  = " .. input .. "\n");
					
					
				else
					break;
				end
				
			end
		else
			digits="";
		end
		
	end

end


function Nodes(index)

		local query="";
           	digits="";
		if(index==1)then
			query = "SELECT * FROM Nodes WHERE level_id like '".. input .. "_' and level_id != 6";	
		else
			query = "SELECT * FROM Nodes WHERE level_id like '".. input .. "_'";
		end
		
--		query = "SELECT * FROM Nodes WHERE level_id like '".. input .. "_'";
   		freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
   		cur = con:execute(query);
   		row = {};result = cur:fetch(row);
   		cur:close();
		local i=1;		
			
		if(tostring(row[1])=='nil')then
				read(aosd.."/prompts/invalid_option.wav",200);
		   		freeswitch.consoleLog("info", script_name .. " : input was +++++++++ = " .. input .. "\n");
				
				local j = input.len(input);
				
				input = input:sub(1,tonumber(j-1));

				freeswitch.consoleLog("info", script_name .. " : input is ======== = " .. input .. "\n");
				return 0;
		end





		if(rep == "Y")then
			read(aosd .. "/prompts/no_option.wav",100);
		end

		for row in rows(query) do
			--freeswitch.consoleLog("info", script_name .. " : %$^%&%^&%^&*&^$%^$#%#$" .. "\n\n\n" );
			
			if(tostring(row[1])== input ..'*') then
				
				local flag1=checkfunc(tostring(row[1]),tostring(row[2]),tostring(row[3]));
				
				if(flag1==1)then
					return 1;
				else
					freeswitch.consoleLog("info", script_name .. " : CHECK = " .. tostring(row[2]).."\n");
					
					local filename = aosd .. "menu/".. row[2];

					read(filename,0);
				
					return 1;
				end
				
			else	
				
				
			
					freeswitch.consoleLog("info", script_name .. " : CHECK2 = " .. tostring(row[2]).."\n");
					
					local filename = aosd .. "menu/".. row[2];
					session:sleep(200);
					read(filename,0);
					read(aosd .. "/Digits/" .. i .. ".wav",3000);		
					freeswitch.consoleLog("info", script_name .. " : CHECK2 ===========>>>>>>>>>> " .. "\n")

					--i=i+1;
					local key = "";
					key = use();
--					digits = session:getDigits(1,"",3000);
					freeswitch.consoleLog("info", script_name .. " : Got Digit value is: " .. tostring(key) .. "\n");
				
					if(tostring(key) ~= "")then
						freeswitch.consoleLog("info", script_name .. " : debug..." .. "\n");
						rep="N";
						if(key == "9")then
							return 1;
						
						else
							
							freeswitch.consoleLog("info", script_name .. " : Got Digit value is: " .. tostring(key) .. "\n");
							i=i+1;
							input = input .. tostring(key);
						        digits = "";	
							return 0;							
						end	
						
					else
						i=i+1;	
						rep="Y";
						
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
	
	read(aosd .. "/prompts/hash.wav",200);
	repeat
      		read(aosd .. "/prompts/eecord_ques.wav", 1000);
		      		
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
			read(aosd .. "/prompts/recording_check.wav", 1000);
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

		query2 = "insert into Questions (Keywords, question_text, asked_by) values (NULL,'" .. partfilename .. "','" .. phonenum .. "')";
 		con:execute(query2);
		freeswitch.consoleLog("info", script_name .. "debuggggggggg.......");
		query3 = "insert into Mapping values((select question_id from Questions where question_text='" .. partfilename .. "'),NULL)";
   		con:execute(query3);
	
		query4 = "update I_Caller set question='Y' where Phone_no='" .. phonenum .. "'";
   		con:execute(query4);

	end

end

----------------------------------------------------------------------------------------------------
------------play responses of the caller...
----------------------------------------------------------------------------------------------------

function play_my_response()

	query = "select responder_ans from R_ques_ans where Phone_no = '" .. phonenum .. "' and responder_ans is not NULL";
   	freeswitch.consoleLog("info", script_name .. " : SQL Querry = " .. query .. "\n");
	cur = con:execute(query);
   	row = {};result = cur:fetch(row);
   	cur:close();			
		
	
	read(aosd .. "/prompts/exitmain.wav",200);
	for row in rows (query) do
		
		
		read(aosd .. "/prompts/response.wav",200);
	
		if(tostring(row[1])=='nil')then
			
			read(aosd .. "/prompts/noresponse.wav",200);
			break;	
		end

		local dir = sd.. "/A/" .. tostring(row[1]);
		read(dir,1000);
		digits=use();
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
	
	read(aosd .. "/prompts/replyongoing.wav",200);


        for row in rows (query) do
		
		session:sleep(300);
      		i = i + 1;
      		Questionid[i] = row[1];
      		file[i] = row[3];
      		local dir_Q = sd .. "/Q/" .. file[i];
		
			
      		z = playfile(dir_Q);
		
      		if (z=="2") then
         		get_reply(row[1]);
      		else
			read(aosd .. "/prompts/nextQ.wav",200);
		end
   	end
	if (i==0) then
		read(aosd .. "/nomessages.wav",500);
	end
end
------------------------------------------------------------------------------------------------------
-----playfile
------------------------------------------------------------------------------------------------------

function playfile(file_name)
	arg[1] = file_name;
	freeswitch.consoleLog("info", script_name .. " : playing " .. file_name .. "\n");
	read(file_name,100);
	local x = 'nil';
	repeat 
		if (role == "responder") then
			read(aosd .. "/Responder/To_record.wav",0);
			read(aosd .. "/Digits/2.wav",500)
		end
		if (role == "guest" or role == "aspirant") then
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
      		dir_A = sd .. "/A/" .. file[i];
      		arg[1] = dir_A;
		freeswitch.consoleLog("info", script_name .. " : playing " .. dir_A .. "\n");
      		read(dir_A,100);
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
		guest_menu(1);
--		responder_menu();
	end
	if (role == "aspirant") then
		guest_menu(2);		
--		responder_menu();
	end
	
	
	read(aosd .. "/prompts/thanx.wav",200);	
	break;
end
session:hangup();
