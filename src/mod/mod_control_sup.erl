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
%%	Reply = mnesia:create_schema([node()]),
%%	lager:info("node: ~p", [node()]),
%%	lager:info("reply: ~p", [Reply]),
	
	Param_ids = [{type, set}, {attributes, record_info(fields, ids)}],
	case mnesia:force_load_table(ids) of
		yes ->
			ok;
		_ ->
			mnesia:create_table(client, Param_ids),
			case mnesia:force_load_table(ids) of
				yes -> ok;
				_ ->
					lager:info("error")
			end
	end,
	Param_client = [{type, set}, {attributes, record_info(fields, client)}],
	case mnesia:force_load_table(client) of
		yes ->
			ok;
		_ ->
			mnesia:create_table(client , Param_client),
			case mnesia:force_load_table(client) of
				yes -> ok;
				_ ->
					lager:info("error")
			end
	end,
	Param_group = [{type, set}, {attributes, record_info(fields, group)}],
	case mnesia:force_load_table(group) of
		yes ->
			ok;
		_ ->
			mnesia:create_table(group, Param_group),
			case mnesia:force_load_table(group) of
				yes -> ok;
				_ ->
					lager:info("error")
			end
	end.
