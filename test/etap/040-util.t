#!/usr/bin/env escript
%% -*- erlang -*-

% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

main(_) ->
    code:add_pathz("src/couchdb"),
    application:start(crypto),

    % Changed to 9 till we figure out the buildbot freeze.
    %etap:plan(10),
    etap:plan(9),
    case (catch test()) of
        ok ->
            etap:end_tests();
        Other ->
            etap:diag(io_lib:format("Test died abnormally: ~p", [Other])),
            etap:bail(Other)
    end,
    ok.

test() ->
    % to_existing_atom
    etap:is(true, couch_util:to_existing_atom(true), "An atom is an atom."),
    etap:is(foo, couch_util:to_existing_atom(<<"foo">>),
        "A binary foo is the atom foo."),
    etap:is(foobarbaz, couch_util:to_existing_atom("foobarbaz"),
        "A list of atoms is one munged atom."),

    % terminate_linked
    Self = self(),
    
    % This is causing halts on the buildbot make coverage runner.
    % Im disabling until we get build bot running but we need to
    % revisit this.
    %spawn(fun() ->
    %    ChildPid = spawn_link(fun() -> receive shutdown -> ok end end),
    %    couch_util:terminate_linked(normal),
    %    Self ! {pid, ChildPid}
    %end),
    %receive
    %    {pid, Pid} ->
    %        etap:ok(not is_process_alive(Pid), "why wont this work?")
    %end,

    % implode
    etap:is([1, 38, 2, 38, 3], couch_util:implode([1,2,3],"&"),
        "use & as separator in list."),

    % trim
    Strings = [" foo", "foo ", "\tfoo", " foo ", "foo\t", "foo\n", "\nfoo"],
    etap:ok(lists:all(fun(S) -> couch_util:trim(S) == "foo" end, Strings),
        "everything here trimmed should be foo."),

    % abs_pathname
    {ok, Cwd} = file:get_cwd(),
    etap:is(Cwd ++ "/foo", couch_util:abs_pathname("./foo"),
        "foo is in this directory."),

    % should_flush
    etap:ok(not couch_util:should_flush(),
        "Not using enough memory to flush."),
    AcquireMem = fun() ->
        IntsToAGazillion = lists:seq(1, 200000),
        LotsOfData = lists:map(
            fun(Int) -> {Int, <<"foobar">>} end,
        lists:seq(1, 200000)),
        etap:ok(couch_util:should_flush(),
            "Allocation 200K tuples puts us above the memory threshold.")
    end,
    AcquireMem(),

    etap:ok(not couch_util:should_flush(),
        "Checking to flush invokes GC."),

    ok.
