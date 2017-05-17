%% Author: Administrator
%% Created: 2012-3-12
%% Description: TODO: Add description to util_RoomInfoParas
-module(util_RoomInfoParas).

%%
%% Include files
%%
-include("roominfo.hrl").
%%
%% Exported Functions
%%
-export([paraElements/1,deparaElement/1]).

%%
%% API Functions
%%
paraElements(Obj)->
	{obj,List}=Obj,
	Data =#roominfo{},
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

para({"type",Val},Data)->
	io:format("para type:~p~n",[Data]),	
	NewData=Data#roominfo{type=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"name",Val},Data)->
	io:format("para name:~p~n",[Data]),	
	NewData=Data#roominfo{name=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"type",Val},Data)->
	io:format("para type:~p~n",[Data]),	
	NewData=Data#roominfo{type=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({Key,Val},Data)->
	io:format("decode key is:~p~n",[Key]),
	io:format("decode Val is:~p~n",[Val]),
	%no mache
    %throw exception
	throw({error,"unkown element",Data})
.

%%
%% Local Functions
%%
deparaElement(Record)->
	#roominfo{id=Id,
			  name=Name,
			  type=Type,
			  unum=Unum,
			  tablename=TableName,
			  status=Status,
			  creationDate=CreationDate}=Record,
	try
	JSon={obj,[
			 {"id",setDef(Id,"i")},			
			 {"name",list_to_binary(setDef(Name,"s"))},
			 {"type",list_to_binary(setDef(Type,"s"))},
			 {"unum",setDef(Unum,"i")},
			 {"status",setDef(Status,"i")}
			 ]}
	catch
	    throw:Any ->
			io:format("Exception is:~p~n",[Any]);
		exit:Any ->
 			io:format("Exit is:~p~n",[Any]);
		error:Any ->
			io:format("error is:~p~n",[Any])
    end
.

setDef(Val,Type)->
	Defv=case Type of
		      "s"->
				"";
		 	  "i"->
				0;
			  "l"->
				[]
		end,
			
	case Val of
		undefined->
			Defv;
		Els->
			Val
	end
.