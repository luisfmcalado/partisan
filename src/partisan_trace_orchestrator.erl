%% -------------------------------------------------------------------
%%
%% Copyright (c) 2018 Christopher S. Meiklejohn.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(partisan_trace_orchestrator).
-author("Christopher Meiklejohn <christopher.meiklejohn@gmail.com>").

-behaviour(gen_server).

-include("partisan.hrl").

%% API
-export([start_link/0,
         start_link/1,
         trace/2,
         reset/0,
         identify/1,
         print/0]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {trace=[], identifier=undefined}).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Same as start_link([]).
-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    start_link([]).

%% @doc Start and link to calling process.
-spec start_link(list())-> {ok, pid()} | ignore | {error, term()}.
start_link(Opts) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Opts, []).

%% @doc Record trace message.
trace(Type, Message) ->
    gen_server:call(?MODULE, {trace, Type, Message}, infinity).

%% @doc Reset trace.
reset() ->
    gen_server:call(?MODULE, reset, infinity).

%% @doc Print trace.
print() ->
    gen_server:call(?MODULE, print, infinity).

%% @doc Identify trace.
identify(Identifier) ->
    gen_server:call(?MODULE, {identify, Identifier}, infinity).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%% @private
-spec init([]) -> {ok, #state{}}.
init([]) ->
    lager:info("Test orchestrator started on node: ~p", [node()]),
    {ok, #state{trace=[]}}.

%% @private
-spec handle_call(term(), {pid(), term()}, #state{}) ->
    {reply, term(), #state{}}.
handle_call({trace, Type, Message}, _From, #state{trace=Trace0}=State) ->
    %% lager:info("~p: recording trace type: ~p message: ~p", [?MODULE, Type, Message]),
    {reply, ok, State#state{trace=Trace0++[{Type, Message}]}};
handle_call(reset, _From, State) ->
    lager:info("~p: resetting trace.", [?MODULE]),
    {reply, ok, State#state{trace=[], identifier=undefined}};
handle_call({identify, Identifier}, _From, State) ->
    lager:info("~p: identifying trace: ~p", [?MODULE, Identifier]),
    {reply, ok, State#state{identifier=Identifier}};
handle_call(print, _From, #state{trace=Trace}=State) ->
    lager:info("~p: printing trace", [?MODULE]),

    lists:foreach(fun({Type, Message}) ->
        case Type of
            interposition_fun ->
                %% Destructure message.
                {SourceNode, DestinationNode, InterpositionType, MessagePayload} = Message,

                %% Format trace accordingly.
                case InterpositionType of
                    receive_message ->
                        lager:info("~p: ~p <- ~p: ~p", [?MODULE, DestinationNode, SourceNode, MessagePayload]);
                    forward_message ->
                        lager:info("~p: ~p => ~p: ~p", [?MODULE, SourceNode, DestinationNode, MessagePayload])
                end;
            _ ->
                lager:info("~p: unknown message type: ~p, message: ~p", [?MODULE, Type, Message])
        end
    end, Trace),

    {reply, ok, State};
handle_call(Msg, _From, State) ->
    lager:warning("Unhandled call messages at module ~p: ~p", [?MODULE, Msg]),
    {reply, ok, State}.

%% @private
-spec handle_cast(term(), #state{}) -> {noreply, #state{}}.
handle_cast(Msg, State) ->
    lager:warning("Unhandled cast messages at module ~p: ~p", [?MODULE, Msg]),
    {noreply, State}.

%% @private
-spec handle_info(term(), #state{}) -> {noreply, #state{}}.
handle_info(Msg, State) ->
    lager:warning("Unhandled info messages at module ~p: ~p", [?MODULE, Msg]),
    {noreply, State}.

%% @private
-spec terminate(term(), #state{}) -> term().
terminate(_Reason, _State) ->
    ok.

%% @private
-spec code_change(term() | {down, term()}, #state{}, term()) -> {ok, #state{}}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================