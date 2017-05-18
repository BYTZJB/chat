%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 下午4:08
%%%-------------------------------------------------------------------
-module(mod_control_sup).
-author("bytzjb").
-include("predefine.hrl").

%% API
-export([init/0]).

init() ->
	Opt_client_pid= [public, set, named_table, {keypos, #client_pid.id}],
	ets:new(client_pid, Opt_client_pid),
	
	Opt_group_pid = [public, set, named_table, {keypos, #group_pid.id}],
	ets:new(group_pid, Opt_group_pid),
	
	mnesia:start(),
	mnesia:wait_for_tables([client, group, ids], 2000).
