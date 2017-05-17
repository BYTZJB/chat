%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 下午5:00
%%%-------------------------------------------------------------------
-module(mod_group_sup).
-author("bytzjb").
-include("predefine.hrl").
-include_lib("stdlib/include/qlc.hrl").

%% API
-export([get_all_group/0]).

get_all_group() ->
	mod_mnesia:get_group_keys().
