-module(sim).
-compile([export_all]).

-include_lib("eunit/include/eunit.hrl").

-include("common.hrl").
-include("game.hrl").
-include("pp.hrl").
-include("schema.hrl").

init() ->
  schema:install(),
  player:create("1000", "pass", "5b635bee55S3", "5Lit5Zu9", 1000), %% Jack
  player:create("1001", "pass", "6LWM56We", "5YyX5Lqs", 1000), %% Tommy 
  player:create("1002", "pass", "6buRSkFDSw==", "6aaZ5riv", 1000), %% Sam 
  player:update_photo(1, <<"def_face_1">>),
  player:update_photo(2, <<"def_face_2">>),
  player:update_photo(3, <<"def_face_3">>),

  server:start().

login() ->
  login:login(<<"1000">>, <<"pass">>, self()),
  login:login(<<"1001">>, <<"pass">>, self()),
  login:login(<<"1002">>, <<"pass">>, self()),
  ok.

socket() -> 
  socket(players()).

socket([]) ->
  ok;

socket([H|T]) ->
  gen_server:cast(H, {'SOCKET', self()}),
  socket(T).

players() ->
  players([1,2,3]).

players(L) ->
  players(L, []).
  
players([], Acc) ->
  Acc;

players([H|T], Acc) ->
  [P] = db:read(tab_player, H),
  players(T, [P#tab_player.process | Acc]).

p(PID) ->
  [P] = db:read(tab_player, PID),
  P#tab_player.process.

g(GID) ->
  [G] = db:read(tab_game_xref, GID),
  G#tab_game_xref.process.

dg(GID) when is_integer(GID) ->
  dg(g(GID));

dg(GID) when is_pid(GID) ->
  gen_server:call(GID, 'DEBUG').

watch(P,G) ->
  gen_server:cast(P,#watch{game=G}).

join(P,G) ->
  gen_server:cast(P, #join{game=G, seat=1, amount=100.0}).

rec() ->
  receive 
    {packet, M} -> M
  end.

flush() ->
    flush(false).

flush(Debug) ->
  receive
    X ->
      if 
        Debug ->
          io:format("Flush: ~p~n", [X]);
        true ->
          ok
      end,
      flush()
  after 0 ->
      ok
  end.