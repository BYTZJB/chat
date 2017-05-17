%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 上午11:30
%%%-------------------------------------------------------------------
-module(id_generator).
-behavior(gen_server).

-export([start_link/0, get_new_id/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("predefine.hrl").
-record(state, {}).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
%%	lager:info("start"),
%%	mnesia:create_schema([node()]),
%%	Param = [{type, ordered_set}, {attributes, record_info(fields, ids)}, {disc_copies, []}],
%%	lager:info(""),
%%	case mnesia:create_table(ids,Param) of
%%		{atomic, ok} -> ok;
%%		{error, _Reason} ->
%%			lager:info("create table_error occur")
%%	end,
	lager:info("########### id_generator"),
	{ok, #state{}}.

get_new_id(IdType) ->
	%%  将表加载到数据库中
	mnesia:force_load_table(ids),
	gen_server:call(?MODULE, {get_id, IdType}).

%% 根据相应的Type返回对应的id
handle_call({get_id, IdType}, _From, State) ->
	F = fun() ->
		Result = mnesia:read(ids, IdType, write),
		case Result of
			[Ids] ->
				Id = Ids#ids.ids,
				NewId = Ids#ids{ids = Id + 1},
				mnesia:write(ids, NewId, write),
				Id;
			[] ->
				NewId= #ids{id_type = IdType, ids = 2},
				mnesia:write(ids, NewId, write),
				1
		end
	    end,
	case mnesia:transaction(F) of
		{atomic, Id} ->
			{atomic, Id};
		{aborted, Reason} ->
			lager:info("run transaction error ~1000.p ~n", [Reason]),
			Id = 0;
		_Else ->
			Id = -1
	end,
	{reply, Id, State}.

handle_cast(_From, _State) ->
	{noreply, ok}.

handle_info(_Request, _State) ->
	{noreply, ok}.

terminate(_From, _State) ->
	ok.

code_change(_OldVer, State, _Ext) ->
	{ok, State}.

