%%%-------------------------------------------------------------------
%%% @author bytzjb
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 五月 2017 上午11:33
%%%-------------------------------------------------------------------
-module(client).
-author("bytzjb").

-behaviour(gen_server).
-include("predefine.hrl").

%% API
-export([
	start_link/0
]).

%% gen_server callbacks
-export([init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {tcp_agent_pid, client_id, client_socket}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
	{ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
	gen_server:start_link(?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
	{ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term()} | ignore).
init([]) ->
	lager:info("success to create a client"),
	{ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
	State :: #state{}) ->
	{reply, Reply :: term(), NewState :: #state{}} |
	{reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
	{noreply, NewState :: #state{}} |
	{noreply, NewState :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
	{stop, Reason :: term(), NewState :: #state{}}).
handle_call(_Request, _From, State) ->
	{reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
	{noreply, NewState :: #state{}} |
	{noreply, NewState :: #state{}, timeout() | hibernate} |
	{stop, Reason :: term(), NewState :: #state{}}).
handle_cast(online, State) ->
	{noreply, State};

%% 处理到来的好友请求
handle_cast(#add_friend{id = Id, to_id = To_Id}, #state{client_id = To_Id = Client_Id, client_socket = Socket} = State) ->
	lager:info("receive add friend request from other client"), %%
	Friends = mod_mnesia:get_friends(Client_Id),
	Friend_Requests = mod_mnesia:get_friend_requests(Client_Id),
	case lists:member(Id, Friends) orelse lists:member(Id, Friend_Requests) of %% 若果对方在自己的好劣列表中，或者在请求列表中
		false ->
			Client = mod_mnesia:get_client(Client_Id),
			New_Client = Client#client{friend_requests = lists:append(Friend_Requests, [Id])},
			mod_mnesia:update_client(Client, New_Client),
			Message = integer_to_list(Id) ++ "said:\nCan I be a friend with you?",
			gen_tcp:send(Socket, Message);
		true ->
			lager:info("已经存在于好友列表或者亲故列表中")
	end,
	{noreply, State};

%% 发起好友请求
handle_cast(#add_friend{id = Id, to_id = To_Id} = Add_Friend, #state{client_id = Id = Client_Id} = State) ->
	lager:info("receive add friend request from other client"), %%
	MyFriends = mod_mnesia:get_friends(Client_Id),
	ToFriends = mod_mnesia:get_friends(To_Id),
	Reply = case lists:member(To_Id, MyFriends) and lists:member(Id, ToFriends) of
		        false ->
			        false;
		        true ->
			        lager:info("你们已经是好友了！"),
			        true
	        end,
	case ets:lookup(client_pid, To_Id) of
		[{_, To_Pid}] when (not Reply) ->
			gen_server:cast(To_Pid, Add_Friend); %% 给对方发送好友请求
		_ ->
			lager:info("对方不在线 或者 你们已经是好友了")
	end,
	{noreply, State};

%% 用于处理用户获得tcp_agent_pid,client_id
handle_cast({get_state, #{tcp_agent_pid := Tcp_Agent_Pid, client_id := Client_Id, client_socket := Socket}}, State) ->
	lager:info("client state: tcp_agent_pid ~p, client_id ~p, client_socket ~p", [Tcp_Agent_Pid, Client_Id, Socket]),
	{noreply, State#state{tcp_agent_pid = Tcp_Agent_Pid, client_id = Client_Id, client_socket = Socket}};

%% 用于接受来自其他客户端的加好友的请求
%% 必须对方在自己的好友请求中
handle_cast(#new_friend{new_friend_id = New_Friend_Id}, #state{client_id = Client_Id} = State) ->
	Client = #client{friends = Friends, friend_requests = Friends_Requests} = mod_mnesia:get_client(Client_Id),
	
	To_Client = #client{friends = To_Friends, friend_requests = To_Friends_Requests} = mod_mnesia:get_client(New_Friend_Id),
	
	case lists:member(New_Friend_Id, Friends) andalso lists:member(Client_Id, To_Friends) of %% 对方在自己的好友列表中 而且 自己在对方好友列表中
		false ->
			New_Friends = lists:append(Friends, [New_Friend_Id]), %% 将对方添加到自己的好友列表中
			New_Friends_Requests = lists:delete(New_Friend_Id, Friends_Requests), %% 将对方从自己的好友列表中删除
			New_Client = Client#client{friends = New_Friends, friend_requests = New_Friends_Requests}, %% 更新自己的信息
			
			New_To_Friends = lists:append(To_Friends, [Client_Id]), %% 将自己添加到对方的好友列表中
			New_To_Friends_Requests = lists:delete(Client_Id, To_Friends_Requests), %% 将对方从自己的好友列表中删除
			New_To_Client = To_Client#client{friends = New_To_Friends, friend_requests = New_To_Friends_Requests}, %% 更新对方的信息
			F =
				fun() ->
					mod_mnesia:update_client(Client, New_Client),
					mod_mnesia:update_client(To_Client, New_To_Client)
				end,
			mnesia:transaction(F)
	end,
	{noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------

handle_info(#add_friend{id = Id, to_id = To_Id} = Add_Friend, #state{client_id = Id} = State) ->
	lager:info("send add friend request to other client"),
	case ets:lookup(client_pid, To_Id) of
		[{_, To_Pid}] ->
			To_Pid ! Add_Friend;
		_ ->
			lager:info("the client not online")
	end,
	{noreply, State};


%%  给群组或者客户端发送聊天信息
handle_info(#client_send_chat{data = Chat}, State) ->
	lager:info("send message to other client"),
	#chat{id = Id, to_type = To_Type, to_id = To_Id, data = Data} = Chat,
	lager:info("~p", [To_Type]),
	{To_Pid, To_Chat} =
		case To_Type of
			1 ->
				%% 判断是不是自己的friend
%%				[{_, Res}] = ets:lookup(client_pid, To_Id),
				Friends = mod_mnesia:get_friends(Id),
				Judge1 = lists:member(To_Id, Friends),
				lager:info("~p ~p", [Friends, Judge1]),
				case ets:lookup(client_pid, To_Id) of
					[{_, Res}] when Judge1 ->
						{Res, #client_receive_client_chat{client_id = Id, data = Data}};
					Err ->
						lager:info("~p", [Err]),
						{error, ""}
				end;
			2 ->
				%% 判断是不是自己的group
%%				[{_, Res}] = ets:lookup(group_pid, To_Id),
				Members = mod_mnesia:get_members(To_Id),
				Judge2 = lists:member(Id, Members),
				lager:info("~p", [Members]),
				lager:info("~p", [Judge2]),
				case ets:lookup(group_pid, To_Id) of
					[{_, Res}] when Judge2 ->
						lager:info("^^^^^^^^^^^^^^^^^^^^^^^"),
						{Res, #group_receive_chat{id = Id, data = Data}};
					_ ->
						{error, ""}
				end;
			_ ->
				lager:info("no correct type"),
				{error, ""}
		end,
	lager:info("~p ~p", [To_Pid, To_Chat]),
	case {To_Pid, To_Chat} of
		{error, _} ->
			lager:info("error occur"),
			error;
		_ ->
			To_Pid ! To_Chat
	end,
	{noreply, State};

%% 接收别人传过来的消息,并发送给客户端
handle_info(#client_receive_client_chat{client_id = Id, data = Data}, #state{client_socket = Socket} = State) ->
	lager:info("receive message from client and send to socket"),
	Message = "client " ++ integer_to_list(Id) ++ " said: \n" ++ Data,
	lager:info("~p", [Socket]),
	lager:info("~p", [Message]),
	gen_tcp:send(Socket, Message),
	lager:info("success send message"),
	{noreply, State};

handle_info(#client_receive_group_chat{group_id = Group_Id, client_id = Client_Id, data = Data}, #state{client_socket = Socket} = State) ->
	lager:info("receive message from group and send to socket"),
	Message = "group " ++ integer_to_list(Group_Id) ++ "\n" ++ "client " ++ integer_to_list(Client_Id) ++ " said:\n" ++ Data,
	gen_tcp:send(Socket, Message),
	{noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
	State :: #state{}) -> term()).
terminate(Reason, _State) ->
	lager:info("~p", [Reason]),
	ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
	Extra :: term()) ->
	{ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
