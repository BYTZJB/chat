%% Author: Administrator
%% Created: 2012-3-1
%% Description: TODO: Add description to util_SetInfoParas
-module(util_SetInfoParas).

%%
%% Include files
%%
-include("clientinfo.hrl").
%%
%% Exported Functions
%%
-export([paraElements/1,deparaElement/1]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
paraElements(Obj)->
	{obj,List}=Obj,
	Data =#clientinfo{},
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

para({"age",Val},Data)->
	io:format("para age:~p~n",[Data]),	
	NewData=Data#clientinfo{age=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"city",Val},Data)->
	io:format("para city:~p~n",[Data]),	
	NewData=Data#clientinfo{city=binary_to_list(Val)},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"nick",Val},Data)->
	io:format("para nick:~p~n",[Data]),	
	NewData=Data#clientinfo{nick=binary_to_list(Val)},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"posx",Val},Data)->
	io:format("para posx:~p~n",[Data]),	
	NewData=Data#clientinfo{posx=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"posy",Val},Data)->
	io:format("para posy:~p~n",[Data]),	
	NewData=Data#clientinfo{posy=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"province",Val},Data)->
	io:format("para province:~p~n",[Data]),	
	NewData=Data#clientinfo{province=binary_to_list(Val)},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"sex",Val},Data)->
	io:format("para sex:~p~n",[Data]),	
	NewData=Data#clientinfo{sex=Val},
	io:format("paraed content:~p~n",[NewData]),
	NewData
;
para({"id",Val},Data)->
	%we do not use client's id
	Data	
;
para({Key,Val},Data)->
	io:format("decode key is:~p~n",[Key]),
	io:format("decode Val is:~p~n",[Val]),
	%no mache
    %throw exception
	throw({error,"unkown element",Data})
.

%paras #clientinfo to json string
deparaElement(Record)->
	#clientinfo{id =Id,
				nick=Nick,
				sex=Sex,
				age=Age,
				province=Province,
				city=City,
				posx=Px,
				posy=Py}=Record,
	{obj,[
		  	 {"id",setDef(Id,"i")},
			 {"nick",list_to_binary(setDef(Nick,"s"))},			
			 {"sex",setDef(Sex,"i")},
			 {"age",setDef(Age,"i")},
			 {"province",list_to_binary(setDef(Province,"s"))},
			 {"city",list_to_binary(setDef(City,"s"))},
			 {"posx",setDef(Px,"i")},
			 {"posy",setDef(Py,"i")}
			 ]}	
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
