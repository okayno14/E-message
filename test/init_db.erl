-module(init_db).

-include_lib("e_message/include/entity.hrl").
-include_lib("jsonerl/include/jsonerl.hrl").

-export([init_db/0]).


init_db()->
	
	U1 = #user{nick = <<"Vasya">>, pass = <<"qfWf!ffffrt1">>},
	U2 = #user{nick = <<"Tolya">>, pass = <<"qfWf!ffffrt1">>},
	U3 = #user{nick = <<"Petya">>, pass = <<"qfWf!ffffrt1">>},

	D1_t = #dialogue{name = <<"test">>, 
				users = [U1#user.nick,
						U2#user.nick,
						U3#user.nick]},
	D2_t = #dialogue{name = <<"test">>,
				users = [U1#user.nick]},
	D3_t = #dialogue{name = <<"test">>,
				users = [U2#user.nick,
						U3#user.nick]},

	client:create_user(U1),
	client:create_user(U2),
	client:create_user(U3),

	D1=client:create_dialogue(U1,D1_t),
	D2=client:create_dialogue(U1,D2_t),
	D3=client:create_dialogue(U1,D3_t),

	M1_t = client:send_message(U1,#message{text = <<"jgfierjigjiojsdssssifdj">>},D1),
	M1 = client:read_message(U1,M1_t#message.id,D1#dialogue.id),
	M2 = client:send_message(U2,#message{text = <<"jfdisfjiosdjfiods">>},D1),
	M3_t = client:send_message(U2,#message{text = <<"dfsjifioeieiieieieie">>},D3),
	M3 = client:read_message(U2,M3_t#message.id,D3#dialogue.id),
	M5 = client:send_message(U1,#message{text = <<"fjdfqqqqqqqqq">>},D2).