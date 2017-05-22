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
	Opt_client_pid= [public, set, named_table, {keypos, 1}],
	ets:new(client_pid, Opt_client_pid),
	
	Opt_group_pid = [public, set, named_table, {keypos, 1}],
	ets:new(group_pid, Opt_group_pid),
	
	mod_mnesia:do_this_once(),
	Reply = mnesia:wait_for_tables([client, group, ids], 2000),
	mod_mnesia:init_client(), %% 初始化一些客户端
	mod_mnesia:init_group(), %% 初始化一些群组
	lager:info("load tables:~p ", [Reply]).
