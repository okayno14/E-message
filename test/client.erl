-module(client).

-include_lib("jsonerl/include/jsonerl.hrl").
-include_lib("e_message/include/entity.hrl").
-include_lib("e_message/include/request.hrl").

-compile(export_all).

create_user(User)->
	Req = "create_user\n\n"++?record_to_json(user,User),
	Ans = send_req(Req),
	parse_ans(Ans,fun(X)-> ?json_to_record(user,X) end).

delete_user(User)->
	Req = "delete_user\n\n"++?record_to_json(user,User),
	Ans = send_req(Req),
	parse_ans(Ans,fun(X)-> list_to_atom(X) end).

create_dialogue(U,D)->
	Data = #create_dialogue{nick=U#user.nick,
							pass=U#user.pass,
							name=D#dialogue.name,
							userNicks=D#dialogue.users},
	Req = "create_dialogue\n\n"++?record_to_json(create_dialogue,Data),
	Ans = send_req(Req),
	parse_ans(Ans,fun(X)->?json_to_record(dialogue,X) end).

get_dialogues(#user{nick=Nick,pass=Pass})->
	Data = #get_dialogues{nick=Nick,pass=Pass},
	Req = "get_dialogues\n\n"++?record_to_json(get_dialogues,Data),
	Ans = send_req(Req),
	parse_ans(Ans,fun(X)->?json_array_to_record_array(dialogue,X) end).
	
quit_dialogue(#user{nick=Nick,pass=Pass},DID)->
	Data = #quit_dialogue{nick=Nick,pass=Pass,id=DID},
	Req = "quit_dialogue\n\n"++?record_to_json(quit_dialogue,Data),
	Ans = send_req(Req),
	parse_ans(Ans,fun(X)-> list_to_atom(X) end).

send_message(U,M,D)->
	Data = #send_message{nick=U#user.nick,
						pass=U#user.pass,
						text=M#message.text,
						dialogueID=D#dialogue.id},
	
	Req  = "send_message\n\n"++?record_to_json(send_message,Data),
	Ans = send_req(Req),
	parse_ans(Ans,fun(X)->?json_to_record(message, X) end).

get_message(#user{nick=Nick,pass=Pass},MID,DID)->
	Data = #get_message{nick=Nick,
							pass=Pass,
							messageID=MID,
							dialogueID=DID},
	
	
	Req = "get_message\n\n"++?record_to_json(get_message,Data),
	Ans = send_req(Req),
	parse_ans(Ans,fun(X)->?json_to_record(message,X) end).

%--------------------------------------------
connect()->
	{ok,Socket} = gen_tcp:connect("localhost",5560,[{active,false}]),
	Socket.

close(Socket)->
	gen_tcp:close(Socket).

send_req(Req)->
	Socket = connect(),
	gen_tcp:send(Socket,Req),
	{ok,Answer} = gen_tcp:recv(Socket,0),
	close(Socket),
	Answer.

parse_ans(Ans,HappyParse)->
	io:format("TRACE client:parse_ans/2 Client got response:~p~n",[Ans]),
	[Status, ArgsJSON]=string:split(Ans,"\n\n"),
	case list_to_atom(Status) of
		ok->
			HappyParse(ArgsJSON);
		error->
			?json_to_record(error,ArgsJSON)
	end.