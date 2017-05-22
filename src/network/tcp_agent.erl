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
	inet:setopts(Socket, [binary, {packet, 0}, {active, true}, {exit_on_close, true}]),
	lager:info("the gen_tcp fsm next_state is wait_auth"),
	{next_state, wait_auth, State#state{socket = Socket}}.

wait_auth(#register{username = UserName, password = PassWord} = Register, State) ->
	lager:info("~p",[Register] ),
	Client_Id = id_generator:get_new_id(client),
	lager:info("~p", [Client_Id]),
	Client = #client{
		id = Client_Id,
		username = UserName,
		password = PassWord,
		friends = [],
		groups = [],
		friend_requests = []
	},
	%% 往数据库添加新的用户
	mod_mnesia:add_client(Client),
	%% 给用户生成对应的处理进程
	%% 并与当前进程相结合
	{ok, Client_Pid} = mod_tcp_agent:add_new_client(Client_Id),
	%% 将用户放到在线列表中去
	ets:insert(client_pid, {Client_Id, Client_Pid}),
	gen_server:cast(Client_Pid, {get_state, #{tcp_agent_pid => self(), client_id => Client_Id, client_socket => State#state.socket}}),
	lager:info("success register!"),
	{next_state, wait_data, State#state{client_pid = Client_Pid}};

wait_auth(#login{id = Id, password = PassWord}, State) ->
	PassWords=  mod_mnesia:get_client_password(Id),
	case PassWords of
		[PassWord] ->
			%% 将用户放到在线列表中去
			%% 给mod_tcp_agent添加新的子进程
			%% 并与当前进程相结合
			{ok, Client_Pid} = mod_tcp_agent:add_new_client(Id),
			gen_server:cast(Client_Pid, {get_state, #{tcp_agent_pid => self(), client_id => Id, client_socket => State#state.socket}}),
			ets:insert(client_pid, {Id, Client_Pid}),
			lager:info("success login"),
			{next_state, wait_data, State#state{client_pid = Client_Pid}};
		_ ->
			{stop, normale, State#client{}}
	end;

wait_auth(_, State) ->
	{stop, normale, State}.

wait_data(#chat{} = Chat, #state{client_pid = Client_Pid} = State) ->
	lager:info("chat begin, client send chat"),
	Client_Pid ! #client_send_chat{data = Chat},
%%	To_Pid =
%%		case Chat#chat.to_type of
%%			1 ->
%%				ets:lookup(client_pid, To_Id);
%%			2 ->
%%				ets:lookup(group_pid, To_Id);
%%			_ ->
%%				{stop, normale, State}
%%		end,
%%	case Chat#chat.to_type of
%%		1 ->
%%			Client = #client_receive_chat{id = Chat#chat.to_id, data = Chat#chat.data},
%%			To_Pid ! Client;
%%		2 ->
%%			Group = #group_receive_chat{id = Chat#chat.to_id, data = Chat#chat.data},
%%			To_Pid ! Group;
%%		_ ->
%%			ok
%%	end,
	{next_state, wait_data, State};

wait_data(#add_friend{} = Add_Friend, #state{client_pid = Client_Pid} = State) ->
	lager:info("i want add a friend ! begin...."),
	gen_server:cast(Client_Pid, Add_Friend),
	{next_state, wait_data, State};

wait_data(#new_friend{} = New_Friend, #state{client_pid = Client_Pid} = State) ->
	lager:info("i will get a new friend"),
	gen_server:cast(Client_Pid, New_Friend),
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
	lager:info("***************** receive request from socket ****************"),
	try
		Message = jiffy:decode(BinData, [return_maps]),
		lager:info("~p", [Message]),
		Cmd = maps:get(<<"cmd">>, Message),
		case Cmd of
			<<"1">> -> %% 注册新用户
				UserName = binary_to_list(maps:get(<<"username">>, Message)),
				PassWord = binary_to_list(maps:get(<<"password">>, Message)),
				Register = #register{username = UserName, password = PassWord},
				
				lager:info("call wait_auth to handle register"),
				tcp_agent:wait_auth(Register, State);
			
			<<"2">> -> %% 登录
				Id = binary_to_integer(maps:get(<<"id">>, Message)),
				PassWord = binary_to_list(maps:get(<<"password">>, Message)),
				Login = #login{id = Id, password = PassWord},
				
				lager:info("call wait_auth to handle login"),
				tcp_agent:wait_auth(Login, State);
			
			<<"3">> -> %% 聊天
				Id = binary_to_integer(maps:get(<<"id">>, Message)),
				To_Type = binary_to_integer(maps:get(<<"to_type">>, Message)),
				To_Id = binary_to_integer(maps:get(<<"to_id">>, Message)),
				Data = binary_to_list(maps:get(<<"data">>, Message)),
				
				Chat = #chat{id = Id,
					to_type = To_Type,
					to_id = To_Id,
					data = Data},
				
				lager:info("call wait_data to handle chat"),
				tcp_agent:wait_data(Chat, State);
			
			<<"4">> -> %% 接受好友请求
				New_Friend_Id = binary_to_integer(maps:get(<<"new_friend_id">>, Message)),
				tcp_agent:wait_data(#new_friend{new_friend_id = New_Friend_Id},State);
			
			<<"5">> -> %% 发起好友请求
				Id = binary_to_integer(maps:get(<<"id">>, Message)),
				To_Id = binary_to_integer(maps:get(<<"to_id">>, Message)),
				tcp_agent:wait_data(#add_friend{id = Id, to_id = To_Id}, State);
			
			_ ->
				lager:info("error cmd"),
				{stop, "error cmd", State}
		end
	catch
		X:Y ->
			lager:info("~p ~p", [X, Y])
	end;

handle_info(#tcp_agent_receive_chat{data = Data}, _StateName, #state{socket = Socket} = State) ->
	gen_tcp:send(Socket, Data),
	{next_state, wait_data, State};

handle_info({tcp_closed, Socket}, StateName, #state{socket = Socket} = State) ->
	lager:info("tcp closed, stateName: ~p", [StateName]),
	{stop, normal, State};

handle_info({tcp_error, Socket}, StateName, #state{socket = Socket} = State) ->
	lager:info("tcp error, stateName: ~p", [StateName]),
	{stop, normal, State};

%%接受到不认识的消息,立刻断开.原因是unexpected_info
handle_info(Info, _StateName, State) ->
	lager:info("tcp_agent receive unexpected info: ~p", [Info]),
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
terminate(_Reason, _StateName, #state{client_pid = Client_Pid} = _State) ->
	Reply = supervisor:terminate_child(client_sup, Client_Pid),
	lager:info("call suervisor to terminate_child: ~p", [Reply]),
	lager:info("tcp_agent process is termianted"),
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
