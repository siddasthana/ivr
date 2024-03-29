--[[

  Copyright (c) 2009 Regents of the University of California, Stanford
  University, and others

   Licensed under the Apache License, Version 2.0 (the "License"); you
   may not use this file except in compliance with the License.  You
   may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
   implied.  See the License for the specific language governing
   permissions and limitations under the License.
   
--]]

-- GLOBALS
MESSAGE_STATUS_PENDING = 0;
MESSAGE_STATUS_APPROVED = 1;
MESSAGE_STATUS_REJECTED = 2;

FILTER_CODE_ALL_ONLY = 0;
FILTER_CODE_ALL_FIRST = 1;
FILTER_CODE_NO_ALL = 2;
FILTER_CODE_ALL_LAST = 3;

GLOBAL_JUMP_MESSAGE=9;

GLOBAL_MENU_MAINMENU = "0";
GLOBAL_MENU_NEXT = "1";
GLOBAL_MENU_RESPOND = "2";
GLOBAL_MENU_INSTRUCTIONS = "3";
GLOBAL_MENU_SKIP_BACK = "4";
GLOBAL_MENU_PAUSE = "5";
GLOBAL_MENU_SKIP_FWD = "6";
GLOBAL_MENU_SEEK_BACK = "7";
GLOBAL_MENU_REPLAY = "8";
GLOBAL_MENU_SEEK_FWD = "9";

basedir = "/usr/local/freeswitch";
bsd = basedir .. "/sounds/en/us/callie/";

sd = "/home/siddhartha/media/IIITD";
logfilename = "/home/siddhartha/Documents/Log/IIITD/IIITD.log";

--[[
aosd = basedir .. "/scripts/AO/sounds/eng/";
sd = basedir .. "/storage/otalo/";
logfilename = sd .. "ao.log";
      --]]

env = assert (luasql.odbc());
con = assert (env:connect("ivr","ivr","ivr","localhost"));

logfile = io.open(logfilename, "a");
logfile:setvbuf("line");

-- UTILITY FUNCTIONS
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

