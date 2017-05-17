%% Author: Administrator
%% Created: 2012-2-27
%% Description: TODO: 
%% format json data to message
-module(util_MessageParas).

%%
%% Include files
%%
%%-include("json.hrl").
-include("message.hrl").
-include("time.hrl").
%%
%% Exported Functions
%%<<"{\"content\":\"aaa\",\"creationDate\":{\"date\":27,\"day\":1,\"hours\":18,\"minutes\":8,\"month\":1,\"seconds\":26,\"time\":1330337306984,\"timezoneOffset\":-480,\"year\":112},\"from\":\"client1\",\"id\":\"289n-2\",\"subject\":\"chat\",\"to\":\"\",\"type\":\"msg\"}">>
%%<<"{\"id\":\"mDvk-2\",\"type\":\"msg\",\"from\":\"client1\",\"to\":\"\",\"subject\":\"chat\",\"content\":\"fffff\",\"creationDate\":{\"date\":28,\"day\":2,\"hours\":21,\"minutes\":56,\"month\":1,\"seconds\":17,\"time\":1330437377609,\"timezoneOffset\":-480,\"year\":112}}">>
-export([paraseDecode/1,paraseEncode/1,paraElements/1]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
%paras json data to message
paraseDecode(Bin)->
	Ret=try rfc4627:decode(Bin)
	%case rfc4627:decode(Bin) of
	%{ok,Obj,_Re}->
	%		io:format("Obj is:~p~n",[Obj]),
	%		paraElements(Obj);
	%	{error,Reason}->
	%		{error,Reason,[]}
	 % end
	catch
		{error,Reasons}->
			io:format("decode error  is:~p~n",[Reasons]),
			{error,Reasons,[]}
	end,
	case Ret of
	{ok,Obj,_Re}->
			io:format("Obj is:~p~n",[Obj]),
			paraElements(Obj);
		{error,Reason}->
			{error,Reason,[]}
	 end
.

%we get elements from decoded json,
%it has to be 7 elements

paraElements(Obj)->
	{obj,List}=Obj,
	Data =#message{},
	%catch exception here
	io:format("data list is:~p~n",[List]),
	try paraEle(List,Data)		
	catch
		{error,Reason,NewData}->
			{error,Reason,NewData}
	end
.

paraEle([Ele|Els],Data)->
	io:format("ele is:~p~n",[Ele]),
	NewData=para(Ele,Data),
	paraEle(Els,NewData)
;
paraEle([],Data)->
	Data
.

%length of content should not more than 1000
%para({"content",Val},Data) when is_binary(Val)->
%	io:format("para content:~p~n",[Data]),
%	Content=binary_to_list(Val),
%	if length(Content)<1000 ->
%			   NewData=Data#message{content=Content},
%			   io:format("paraed content:~p~n",[NewData]),
%			   NewData;
%	   true ->			   
%               throw({error,"illegal Content value",Data})				
%	end
para({"content",Val},Data)->
	io:format("para content:~p~n",[Data]),	
	NewData=Data#message{content=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"to",Val},Data) when is_binary(Val)->
	io:format("para to:~p~n",[Data]),
	To =binary_to_list(Val),
	NewData=Data#message{to=To}
;
para({"id",Val},Data) when is_binary(Val)->
	io:format("para id:~p~n",[Data]),
	Id=binary_to_list(Val),
	NewData=Data#message{id=Id}
;
%para({"subject",Val},Data) when is_binary(Val)->
%	io:format("para subject:~p~n",[Data]),
%	Sub=binary_to_list(Val),
%	%we should validate subject here 
%   if Sub=:="chat" ->
%		   NewData=Data#message{subject=Sub};
%	   true ->
%		 %throw exception
%		 throw({error,"illegal subject value",Data})
%	end
%;
para({"subject",Val},Data) when is_binary(Val)->
	io:format("para subject:~p~n",[Data]),
	Sub=binary_to_list(Val),
	%we should validate subject here 
	NewData=Data#message{subject=Sub}
;
%para({"type",Val},Data) when is_binary(Val)->
%	io:format("para type:~p~n",[Data]),
%	Type = binary_to_list(Val),
%	if Type=:="msg"->
%		   NewData=Data#message{type=Type};
%	   true ->
%		 %throw exception
%		 throw({error,"illegal type value",Data})
%	end
%;
para({"type",Val},Data) when is_binary(Val)->
	io:format("para type:~p~n",[Data]),
	Type = binary_to_list(Val),	
	NewData=Data#message{type=Type}
;
para({"from",Val},Data) when is_binary(Val)->
	io:format("para from:~p~n",[Data]),
	From=binary_to_list(Val),
	NewData=Data#message{from=From}
;
para({"creationDate",Val},Data)->
	{obj,List}=Val,
	Time=#time{},
	NewData1=Data#message{time=Time},
	NewData=paraEle(List,NewData1)
;
para({"date",Val},Data) when is_integer(Val)->
	io:format("para date:~p~n",[Data]),
	#message{time=Time}=Data,
	NewTime=Time#time{date=Val},
	NewData=Data#message{time=NewTime}	
;
para({"day",Val},Data) when is_integer(Val)->
	io:format("para day:~p~n",[Data]),
	#message{time=Time}=Data,
	NewTime=Time#time{day=Val},
	NewData=Data#message{time=NewTime}	
;
para({"hours",Val},Data) when is_integer(Val)->
	#message{time=Time}=Data,
	NewTime=Time#time{hours=Val},
	NewData=Data#message{time=NewTime}	
;
para({"minutes",Val},Data) when is_integer(Val)->
	#message{time=Time}=Data,
	NewTime=Time#time{minutes=Val},
	NewData=Data#message{time=NewTime}	
;
para({"month",Val},Data) when is_integer(Val)->
	#message{time=Time}=Data,
	NewTime=Time#time{month=Val},
	NewData=Data#message{time=NewTime}	
;
para({"seconds",Val},Data) when is_integer(Val)->
	#message{time=Time}=Data,
	NewTime=Time#time{seconds=Val},
	NewData=Data#message{time=NewTime}	
;
para({"time",Val},Data) when is_integer(Val)->
	#message{time=Time}=Data,
	NewTime=Time#time{thetime=Val},
	NewData=Data#message{time=NewTime}	
;
para({"timezoneOffset",Val},Data) when is_integer(Val)->
	#message{time=Time}=Data,
	NewTime=Time#time{offset=Val},
	NewData=Data#message{time=NewTime}	
;
para({"year",Val},Data) when is_integer(Val)->
	#message{time=Time}=Data,
	NewTime=Time#time{year=Val},
	NewData=Data#message{time=NewTime}	
;
para({Key,Val},Data)->
	io:format("decode key is:~p~n",[Key]),
	io:format("decode Val is:~p~n",[Val]),
	%no mache
    %throw exception
	throw({error,"unkown element",Data})
.

%parase message to json
paraseEncode(Message)->
	io:format("Encoding Message:~p~n",[Message]),
	{message,Id,Type,From,To,Subject,Content,Time}=Message,
	{time,Date,Day,Hours,Minutes,Month,Seconds,TheTime,Offset,Year}=Time,
	%Data={obj,[{"content",list_to_binary(Content)},
     TheContent= encodeContent(Message),
	
	TheFrom=if 
			  is_integer(From)->
		   		integer_to_list(From);
			  true->
				  From
			end,					
     Data={obj,[{"content",TheContent},
		  	  {"from",list_to_binary(TheFrom)},
		  	  {"to",list_to_binary(To)},
		  	  {"subject",list_to_binary(Subject)},
		  	  {"id",list_to_binary(Id)},
		      {"type",list_to_binary(Type)},
		 	  {"creationDate",{obj,[{"date",Date},
							   {"day",Day},
							   {"hours",Hours},
						       {"minutes",Minutes},
							   {"month",Month},
							   {"seconds",Seconds},
							   {"time",TheTime},
							   {"timezoneOffset",Offset},
							   {"year",Year}
								]
							  }
			  }]
		  },
   io:format("Data to Encode:~p~n",[Data]),
   rfc4627:encode(Data)
.

encodeContent(Message)->
	{message,_,Type,_,_,Subject,Content,_}=Message,
	case Type of
		"msg"->
			case Subject of
				"chat"->
					if 
						is_binary(Content)->
					%list_to_binary(Content);
						Content;
						true->
							list_to_binary(Content)
					end;
				Els->
					Content
			end;
		Els->
			Content
	end
.
