%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 下午4:53
%%%-------------------------------------------------------------------
-module(mod_mnesia).
-author("bytzjb").
-include("predefine.hrl").

%% API
-export([get_group_keys/0]).

get_group_keys() ->
	do(qlc:q([E#group.id || E <- mnesia:table(group)])).

do(Q) ->
	F = fun() -> qlc:e(Q) end,
	{atomic, Val} = mnesia:transaction(F),
	Val.
