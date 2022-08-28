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
					create_user4,
					
					delete_user1,
					delete_user2,
					delete_user3,
					delete_user4]},
		{dialogues,[],[get_dialogues1,
						get_dialogues2,
						get_dialogues3,
						get_dialogues4,
						
						create_dialogue1,
						create_dialogue2,
						create_dialogue3,
						create_dialogue4,
						create_dialogue5,
						create_dialogue6]}
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

%normal case
delete_user1(_)->
	Nick = ct:get_config(user4_nick),
	Pass = ct:get_config(user4_pass),
	User = #user{nick=Nick,pass=Pass},
	ok = client:delete_user(User).

%repeat delete
delete_user2(_C)->
	delete_user1(_C).

%invalid Nick
delete_user3(_)->
	User = gen_user_invalid_nick(),
	Res = client:delete_user(User),
	true=is_record(Res,error).

%invalid Pass
delete_user4(_)->
	User = gen_user_invalid_pass(),
	Res = client:delete_user(User),
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

%normal case
create_dialogue1(_)->
	User = gen_user1(),
	D = #dialogue{id = ct:get_config(dial3)+1,
					name = <<"TestD4">>,
					users = [ct:get_config(user1_nick),
								ct:get_config(user3_nick)],
					messages = []},
	D = client:create_dialogue(User,D).

%invalid nick
create_dialogue2(_)->
	User = gen_user_invalid_nick(),
	D = #dialogue{id = ct:get_config(dial3)+1,
					name = <<"TestD4">>,
					users = [ct:get_config(user1_nick),
								ct:get_config(user3_nick)],
					messages = []},
	Res = client:create_dialogue(User,D),
	true=is_record(Res,error).

%invalid pass
create_dialogue3(_)->
	User = gen_user_invalid_pass(),
	D = #dialogue{id = ct:get_config(dial3)+1,
					name = <<"TestD4">>,
					users = [ct:get_config(user1_nick),
								ct:get_config(user3_nick)],
					messages = []},
	Res = client:create_dialogue(User,D),
	true=is_record(Res,error).

%user doesn't exist
create_dialogue4(_)->
	User = gen_user_not_exist(),
	D = #dialogue{id = ct:get_config(dial3)+1,
					name = <<"TestD4">>,
					users = [ct:get_config(user1_nick),
								ct:get_config(user3_nick)],
					messages = []},
	Res = client:create_dialogue(User,D),
	true=is_record(Res,error).

%dialogue_name is invalid
create_dialogue5(_)->
	User = gen_user1(),
	D = #dialogue{id = ct:get_config(dial3)+1,
					name = <<"Te/*st D4">>,
					users = [ct:get_config(user1_nick),
								ct:get_config(user3_nick)],
					messages = []},
	Res = client:create_dialogue(User,D),
	true=is_record(Res,error).

create_dialogue6(_)->
	User = gen_user1(),
	UU = gen_user_not_exist(),
	D = #dialogue{id = ct:get_config(dial3)+1,
					name = <<"TestD4">>,
					users = [UU#user.nick,UU#user.nick],
					messages = []},
	Res = client:create_dialogue(User,D),
	true=is_record(Res,error).

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

gen_user1()->
	Nick=ct:get_config(user1_nick),
	Pass=ct:get_config(user1_pass),
	#user{nick=Nick,pass=Pass}.

gen_user_not_exist()->
	#user{nick = <<"QErtot22">>,pass = <<"qfWf!ffffrt1">>}.