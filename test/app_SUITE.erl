-module(app_SUITE).

-compile(export_all).

-include_lib("e_message/include/entity.hrl").
-include_lib("e_message/include/request.hrl").
-include_lib("jsonerl/include/jsonerl.hrl").


all()->
	[
		{group,users},
		{group,messages},
		{group,dialogues}].

init_per_suite(Config)->
	Path = ct:get_config(server_conf_path),
	ok=e_message:start(Path),
	Config.

end_per_suite(Config)->
	e_message ! {stop,self()},
	ok.

groups()->
	[
		{users,[sequence],[create_user1,
					create_user2,
					create_user3,
					create_user4,
					
					delete_user1,
					delete_user2,
					delete_user3,
					delete_user4]},
		{messages,[sequence],[get_message1,
								get_message2,
								get_message3,
								get_message4,
								get_message5,
								get_message6,
								get_message7,
								
								get_messages1,
								get_messages2,
								get_messages3,
								get_messages4,
								get_messages5,
								get_messages6]},
		{dialogues,[sequence],[get_dialogues1,
						get_dialogues2,
						get_dialogues3,
						get_dialogues4,
						
						create_dialogue1,
						create_dialogue2,
						create_dialogue3,
						create_dialogue4,
						create_dialogue5,
						create_dialogue6,
						
						quit_dialogue1,
						quit_dialogue2,
						quit_dialogue3,
						quit_dialogue4,
						quit_dialogue5,
						quit_dialogue6]}
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

%normal case
get_message1(_)->
	io:format("TRACE app_SUITE get_message1 enter in test case~n"),
	User = gen_user1(),
	%пользователь является адресантом
	MID = ct:get_config(m1),
	DID = ct:get_config(dial1),
	io:format("TRACE app_SUITE get_message1 try to send req~n"),
	Res = client:get_message(User,MID,DID),
	io:format("TRACE app_SUITE get_message1 req sended~n"),
	true=is_record(Res,message),
	%пользователь является адресатом
	MID2 = ct:get_config(m2),
	Res2 = client:get_message(User,MID2,DID),
	true=is_record(Res2,message).

%invalid nick
get_message2(_)->
	User = gen_user_invalid_nick(),
	MID = ct:get_config(m5),
	DID = ct:get_config(dial2),
	Res = client:get_message(User,MID,DID),
	true=is_record(Res,error).

%invalid pass
get_message3(_)->
	User = gen_user_invalid_pass(),
	MID = ct:get_config(m5),
	DID = ct:get_config(dial2),
	Res = client:get_message(User,MID,DID),
	true=is_record(Res,error).

%user doesn't exist
get_message4(_)->
	User=gen_user_not_exist(),
	MID = ct:get_config(m5),
	DID = ct:get_config(dial2),
	Res = client:get_message(User,MID,DID),
	true=is_record(Res,error).

%диалога не существует
get_message5(_)->
	User = gen_user1(),
	MID = ct:get_config(m5),
	DID = ct:get_config(dial3)+11000,
	Res = client:get_message(User,MID,DID),
	true=is_record(Res,error).

%сообщения не существует
get_message6(_)->
	User = gen_user1(),
	MID = ct:get_config(m5)+14829482,
	DID = ct:get_config(dial3),
	Res = client:get_message(User,MID,DID),
	true=is_record(Res,error).

%пользователь не является адресантом и не является адресатом
get_message7(_)->
	User = gen_user1(),
	MID = ct:get_config(m3),
	DID = ct:get_config(dial3),
	Res = client:get_message(User,MID,DID),
	true=is_record(Res,error).

%normal case
get_messages1(_)->
	User = gen_user1(),
	DID = ct:get_config(dial1),
	Res = client:get_messages(User,DID),
	true=is_list(Res),
	true=(length(Res)=:=2).

%invalid nick
get_messages2(_)->
	User = gen_user_invalid_nick(),
	DID = ct:get_config(dial2),
	Res = client:get_messages(User,DID),
	true=is_record(Res,error).

%invalid pass
get_messages3(_)->
	User = gen_user_invalid_pass(),
	DID = ct:get_config(dial2),
	Res = client:get_messages(User,DID),
	true=is_record(Res,error).

%user doesn't exist
get_messages4(_)->
	User = gen_user_not_exist(),
	DID = ct:get_config(dial2),
	Res = client:get_messages(User,DID),
	true=is_record(Res,error).

%dialogue doesn't exist
get_messages5(_)->
	User = gen_user1(),
	DID = ct:get_config(dial2)+122231231,
	Res = client:get_messages(User,DID),
	true=is_record(Res,error).

%пользователь не состоит в диалоге
get_messages6(_)->
	User = gen_user1(),
	DID = ct:get_config(dial3),
	Res = client:get_messages(User,DID),
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
					users = [ct:get_config(user1_nick)],
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

%users doesn't exists in db
create_dialogue6(_)->
	User = gen_user1(),
	UU = gen_user_not_exist(),
	D = #dialogue{id = ct:get_config(dial3)+1,
					name = <<"TestD4">>,
					users = [UU#user.nick,UU#user.nick],
					messages = []},
	Res = client:create_dialogue(User,D),
	true=is_record(Res,error).

%invalid nick
quit_dialogue1(_)->
	User = gen_user_invalid_nick(),
	DID = ct:get_config(dial3)+1,
	Res = client:quit_dialogue(User,DID),
	true=is_record(Res,error).

%invalid pass
quit_dialogue2(_)->
	User = gen_user_invalid_pass(),
	DID = ct:get_config(dial3)+1,
	Res = client:quit_dialogue(User,DID),
	true=is_record(Res,error).

%выход из диалога в котором кроме user1 есть ещё участники
quit_dialogue3(_)->
	User = gen_user1(),
	DID = ct:get_config(dial1),
	%в списке диалогов пользователя содержится D1
	true = is_user_in_dialogue(DID,User),	
	client:quit_dialogue(User,DID),
	%после выхода в списке диалогов D1 отсутствует
	false = is_user_in_dialogue(DID,User),
	%получить сообщение M1: если сервер его выдаст, значит после выхода пользователя сообщения не чистились
	Res = client:get_message(User,ct:get_config(m1),DID),
	true=is_record(Res,message).

%выход из диалогов в которых остался только user1
quit_dialogue4(_)->
	User = gen_user1(),
	DID4 = ct:get_config(dial3)+1,

	%---РАБОТА С D4----
	%в списке диалогов пользователя содержится D4
	true=is_user_in_dialogue(DID4,User),	
	client:quit_dialogue(User,DID4),
	%после выхода в списке диалогов D4 отсутствует
	false = is_user_in_dialogue(DID4,User),
	%---РАБОТА С D4----

	%---РАБОТА С D2----
	%в списке диалогов пользователя содержится D2
	true = is_user_in_dialogue(ct:get_config(dial2),User),
	client:quit_dialogue(User,ct:get_config(dial2)),
	false = is_user_in_dialogue(ct:get_config(dial2),User),
	%проверить, что сообщение было удалено
	Res = client:get_message(User,ct:get_config(m5),ct:get_config(dial2)),
	true=is_record(Res,error).
	%---РАБОТА С D2----

%выход из диалога, в котором user1 не состоит
quit_dialogue5(_)->
	User = gen_user1(),
	DID3 = ct:get_config(dial3),
	Res = client:quit_dialogue(User,DID3),
	true=is_record(Res,error).

%выход из несуществующего диалога
quit_dialogue6(_)->
	User = gen_user1(),
	DID3 = -656565656,
	Res = client:quit_dialogue(User,DID3),
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

is_user_in_dialogue(DID,User)->
	io:format("DID:~p User:~p~n",[DID,User]),
	D_List = client:get_dialogues(User),
	case D_List of
		#error{msg= <<"not_found">>}->
			false;
		L when is_list(L)->
			case lists:filter(fun(#dialogue{id=ELEM_ID})-> 
							ELEM_ID =:= DID 
						end, 
						D_List) of
				[]->
					false;
				[#dialogue{id = DID}|_]->
					true;
				_ ->
					false
			end;
		_->
			{error,unknown_server_error}
	end.