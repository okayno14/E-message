-module(app_SUITE).

-compile(export_all).

-include_lib("e_message/include/entity.hrl").
-include_lib("e_message/include/request.hrl").
-include_lib("jsonerl/include/jsonerl.hrl").


all()->
	[
		{group,users},
		{group,dialogues}].

init_per_suite(Config)->
	Path = ct:get_config(server_conf_path),
	e_message:start(Path),
	Config.

end_per_suite(Config)->
	e_message ! {stop,self()},
	ok.

groups()->
	[
		{users,[],[create_user1,
					create_user2,
					create_user3,
					create_user4]},
		{dialogues,[],[get_dialogues1,
						get_dialogues2,
						get_dialogues3,
						get_dialogues4]}
	].

%normal data
create_user1(_)->
	Nick = ct:get_config(user4_nick),
	Pass = ct:get_config(user4_pass),
	User = #user{nick=Nick,pass=Pass},
	User = client:create_user(User).

%same user as create_user1
create_user2(_C)->
	Nick = ct:get_config(user4_nick),
	Pass = ct:get_config(user4_pass),
	User = #user{nick=Nick,pass=Pass},
	Res = client:create_user(User),
	true=is_record(Res,error).

%invalid nick
create_user3(_)->
	Res=client:create_user(gen_user_invalid_nick()),
	true=is_record(Res,error).

%invalid pass
create_user4(_)->
	Res=client:create_user(gen_user_invalid_pass()),
	true=is_record(Res,error).

%user exists
%valid data
get_dialogues1(_)->
	Nick=ct:get_config(user1_nick),
	Pass=ct:get_config(user1_pass),
	Res=client:get_dialogues(#user{nick=Nick, pass=Pass}),
	false=is_record(Res,error).

%invalid nick
get_dialogues2(_)->
	Res=client:get_dialogues(gen_user_invalid_nick()),
	true=is_record(Res,error).

%invalid pass
get_dialogues3(_)->
	Res=client:get_dialogues(gen_user_invalid_pass()),
	true=is_record(Res,error).

%user doesn't exist
get_dialogues4(_)->
	User = #user{nick = <<"QErtot22">>,pass = <<"qfWf!ffffrt1">>},
	true = is_record(client:get_dialogues(User),error). 

%----------------------------------------
gen_user_invalid_pass()->
	Buf=binary_to_list(ct:get_config(user1_pass)),
	Pass = list_to_binary(["abrrakadabra "|Buf]),
	Nick=ct:get_config(user1_nick),
	#user{nick=Nick, pass=Pass}.

gen_user_invalid_nick()->
	Buf=binary_to_list(ct:get_config(user1_nick)),
	Nick = list_to_binary(["abrrakadabra "|Buf]),
	Pass=ct:get_config(user1_pass),
	#user{nick=Nick, pass=Pass}.