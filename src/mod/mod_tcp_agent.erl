%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 下午6:08
%%%-------------------------------------------------------------------
-module(mod_tcp_agent).
-author("bytzjb").
-include("predefine.hrl").

%% API
-export([add_new_client/1]).


add_new_client(#client{id = Id}) ->
	Restart = permanent,
	Shutdown = 2000,
	Type = worker,
	
	AChild = {Id, {client, start_link, [Id]},
		Restart, Shutdown, Type, [client]},
	{ok, _Child} = supervisor:start_child(tcp_agent_sup, [AChild]).
