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
	Shutdown = brutal_kill,
	Type = worker,
	
	AChild = {Id, {client, start_link, []},
		Restart, Shutdown, Type, [client]},
	supervisor:start_child(client_sup, AChild).
