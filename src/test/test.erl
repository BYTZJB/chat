%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 下午5:23
%%%-------------------------------------------------------------------
-module(test).
-author("bytzjb").
-include("predefine.hrl").
-include_lib("stdlib/include/qlc.hrl").
-record(shop, {id, name}).

%% API
-export([start/0, the_ets/0, mnesia_store_group/0]).

start() ->
	mnesia:start(),
	yes = mnesia:force_load_table(group),
	Fun =
		fun() ->
			List = ["yangwei", "zhongshiting"],
			mnesia:write(group, #group{id = 1, members = List}, write),
			do(qlc:q([E#group.id || E <- mnesia:table(group)]))
		end,
	mnesia:transaction(Fun).

do(Q) ->
	F = fun() -> qlc:e(Q) end,
	{atomic, Val} = mnesia:transaction(F),
	Val.

the_ets() ->
	Opt_Shop = [public, set, named_table, {keypos, #shop.id}],
	ets:new(shop, Opt_Shop),
	Shop = #shop{id = 101, name = "2333"},
	ets:insert(shop, Shop),
	[Reply] = ets:lookup(shop, 101),
	io:format("~p", [Reply#shop.name]).

mnesia_store_group() ->
	Group_List = [
		#group{id = 1, members = [1, 3]},
		#group{id = 2, members = [2, 4]},
		#group{id = 3, members = [5, 9]}
	],
	F =
		fun() ->
			lists:foreach(
				fun(Elem) ->
					mnesia:write(Elem)
				end,
				Group_List)
		end,
	mnesia:transaction(F).
	
