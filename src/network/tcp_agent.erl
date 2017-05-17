%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 五月 2017 上午11:32
%%%-------------------------------------------------------------------
-module(tcp_agent).
-author("bytzjb").

-behaviour(gen_fsm).

%% API
-export([
	start_link/0
]).

%% gen_fsm callbacks
-export([init/1,
	wait_socket/2,
	wait_data/2,
	wait_auth/2,
	handle_event/3,
	handle_sync_event/4,
	handle_info/3,
	terminate/3,
	code_change/4]).

-define(SERVER, ?MODULE).
-include("predefine.hrl").

-record(state, {socket, client_pid}).
-record(register, {username, password}).
-record(login, {id, password}).
-record(chat, {id, username, to_type, to_id, data}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Creates a gen_fsm process which calls Module:init/1 to
%% initialize. To ensure a synchronized start-up procedure, this
%% function does not return until Module:init/1 has returned.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() -> {ok, pid()} | ignore | {error, Reason :: term()}).
start_link() ->
	gen_fsm:start_link(?MODULE, [], []).

%%%===================================================================
%%% gen_fsm callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a gen_fsm is started using gen_fsm:start/[3,4] or
%% gen_fsm:start_link/[3,4], this function is called by the new
%% process to initialize.
%%
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
	{ok, StateName :: atom(), StateData :: #state{}} |
	{ok, StateName :: atom(), StateData :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term()} | ignore).
init([]) ->
	process_flag(trap_exit, true),
	{ok, wait_socket, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% There should be one instance of this function for each possible
%% state name. Whenever a gen_fsm receives an event sent using
%% gen_fsm:send_event/2, the instance of this function with the same
%% name as the current state name StateName is called to handle
%% the event. It is also called if a timeout occurs.
%%
%% @end
%%--------------------------------------------------------------------
-spec(wait_socket(Event :: term(), State :: #state{}) ->
	{next_state, NextStateName :: atom(), NextState :: #state{}} |
	{next_state, NextStateName :: atom(), NextState :: #state{},
		timeout() | hibernate} |
	{stop, Reason :: term(), NewState :: #state{}}).
wait_socket({go, Socket}, State) ->
	inet:setopts(Socket, [binary, {packet, 4}, {active, true}, {exit_on_close, true}]),
	{next_state, wait_auth, State#state{socket = Socket}}.

wait_auth(#register{username = UserName, password = PassWord}, State) ->
	Client_Id = id_generator:get_new_id(client),
	Client = #client{
			id = Client_Id,
			username = UserName,
			password = PassWord,
			friends = [],
			groups = []
		},
	%% 将用户放到在线列表中去
	ets:insert(client_pid, {Client_Id, self()}),
	%% 往数据库添加新的用户
	mod_mnesia:add_new_client(Client),
	%% 给mod_tcp_agent添加新的子进程
	%% 并与当前进程相结合
	Client_Pid = mod_tcp_agent:add_new_client(Client),
	ets:insert(client_pid, {Client_Id, self()}),
	{next_state, wait_data, State#state{client_pid = Client_Pid}};

wait_auth(#login{id = Id, password = PassWord1}, State) ->
	PassWord2 = mod_mnesia:get_client_password(Id),
	case PassWord1 of
		PassWord2 ->
			%% 将用户放到在线列表中去
			ets:insert(client_pid, {Id, self()}),
			%% 给mod_tcp_agent添加新的子进程
			%% 并与当前进程相结合
			Client_Pid = mod_tcp_agent:add_new_client(#client{id = Id}),
			{next_state, wait_data, State#state{client_pid = Client_Pid}};
		_ ->
			{stop, normale, State#client{}}
	end;

wait_auth(_, Reason) ->
	{stop, normale, Reason}.

wait_data(#chat{to_id = To_Id} = Chat, State) ->
	To_Pid =
		case Chat#chat.to_type of
			1 ->
				ets:lookup(client_pid, To_Id);
			2 ->
				ets:lookup(group_pid, To_Id);
			_ ->
				{stop, normale, State}
		end,
	case Chat#chat.to_type of
		1 ->
			Client = #client_receive_chat{id = Chat#chat.to_id, username = Chat#chat.username, data = Chat#chat.data},
			To_Pid ! Client;
		2 ->
			Group = #group_receive_chat{id = Chat#chat.to_id, username = Chat#chat.username, data = Chat#chat.data},
			To_Pid ! Group;
		_ ->
			ok
	end,
	{next_state, wait_data, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a gen_fsm receives an event sent using
%% gen_fsm:send_all_state_event/2, this function is called to handle
%% the event.
%%
%% @end
%%--------------------------------------------------------------------
	-spec(handle_event(Event :: term(), StateName :: atom(),
StateData :: #state{}) ->
{next_state, NextStateName :: atom(), NewStateData :: #state{}} |
{next_state, NextStateName :: atom(), NewStateData :: #state{},
timeout() | hibernate} |
{stop, Reason :: term(), NewStateData :: #state{}}).
handle_event(_Event, StateName, State) ->
	{next_state, StateName, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a gen_fsm receives an event sent using
%% gen_fsm:sync_send_all_state_event/[2,3], this function is called
%% to handle the event.
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_sync_event(Event :: term(), From :: {pid(), Tag :: term()},
	StateName :: atom(), StateData :: term()) ->
	{reply, Reply :: term(), NextStateName :: atom(), NewStateData :: term()} |
	{reply, Reply :: term(), NextStateName :: atom(), NewStateData :: term(),
		timeout() | hibernate} |
	{next_state, NextStateName :: atom(), NewStateData :: term()} |
	{next_state, NextStateName :: atom(), NewStateData :: term(),
		timeout() | hibernate} |
	{stop, Reason :: term(), Reply :: term(), NewStateData :: term()} |
	{stop, Reason :: term(), NewStateData :: term()}).
handle_sync_event(_Event, _From, StateName, State) ->
	Reply = ok,
	{reply, Reply, StateName, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_fsm when it receives any
%% message other than a synchronous or asynchronous event
%% (or a system message).
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: term(), StateName :: atom(),
	StateData :: term()) ->
	{next_state, NextStateName :: atom(), NewStateData :: term()} |
	{next_state, NextStateName :: atom(), NewStateData :: term(),
		timeout() | hibernate} |
	{stop, Reason :: normal | term(), NewStateData :: term()}).
handle_info({tcp, Socket, BinData}, _StateName, #state{socket = Socket} = State) ->
	Message = #message{cmd = Cmd} = jiffy:encode(BinData),
	case Cmd of
		1 ->
			Register = #register{username = Message#message.username, password = Message#message.password},
			tcp_agent:wait_auth(Register, State);
		2 ->
			Login = #login{id = Message#message.id, password = Message#message.password},
			tcp_agent:wait_auth(Login, State);
		3 ->
			Chat = #chat{id = Message#message.id, username = Message#message.username,
				to_type = Message#message.to_type,
				to_id = Message#message.to_id,
				data = Message#message.data},
			tcp_agent:wait_data(Chat, State);
		_ ->
			lager:info("error"),
			{stop, "error cmd", State}
	end;

handle_info(#tcp_agent_receive_chat{data = Data}, _StateName, #state{socket = Socket} = State) ->
	gen_tcp:send(Socket, Data),
	{next_state, wait_data, State};

handle_info({tcp_closed, Socket}, StateName, #state{socket = Socket} = State) ->
	lager:info("tcp closed, uid: ~p, state: ~p", [get(uid), StateName]),
	{stop, normal, State};

handle_info({tcp_error, Socket}, StateName, #state{socket = Socket} = State) ->
	lager:info("tcp error, uid: ~p, state: ~p", [get(uid), StateName]),
	{stop, normal, State};

%%接受到不认识的消息,立刻断开.原因是unexpected_info
handle_info(Info, _StateName, State) ->
	lager:info("tcp_agent receive unexpected info: ~p, uid: ~p", [Info, get(uid)]),
	{stop, "error tcp message", State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_fsm when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_fsm terminates with
%% Reason. The return value is ignored.
%%
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: normal | shutdown | {shutdown, term()}
| term(), StateName :: atom(), StateData :: term()) -> term()).
terminate(_Reason, _StateName, _State) ->
	ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, StateName :: atom(),
	StateData :: #state{}, Extra :: term()) ->
	{ok, NextStateName :: atom(), NewStateData :: #state{}}).
code_change(_OldVsn, StateName, State, _Extra) ->
	{ok, StateName, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
