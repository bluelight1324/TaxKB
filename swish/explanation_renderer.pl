:- module(_, [term_rendering//3]). % +Term, +Vars, +Options

:- use_module(library(http/html_write)).
:- use_module(library(http/term_html)).
:- use_module(library(http/js_write)).
:- use_module(swish(lib/render)).

:- register_renderer(explanation_renderer, "An explanation tree").

:- use_module('../reasoner.pl').

term_rendering(Explanation, _Vars, _Options) --> 
	{Explanation=taxlogExplanation(Trees), is_list(Trees)}, % validate...
    !,
    {
        explanationHTML(Trees,HTML)
    },
	html( 
		div([ 'data-render'('As taxlog explanation')],[
            div([],HTML)
		]) 
	).

:- multifile user:extra_swish_resource/1. % declare a link or script resource to include in the SWISH page's head
user:extra_swish_resource(script("
    function myPlayFile(filename,line){
    console.log(filename+' '+line);
	var available = $('body').find('.storage').storage('match', {file:filename});
	if (available) {
		var message = null;
		$('body').find('.storage').storage('match', {file:filename}) . storage('expose',null);
		$('.active').find('.prolog-editor').prologEditor('gotoLine', line, null).focus();  
	} else $('body').swish('playFile', { file:filename, line:line }); 
}
")).

% explanationHTML(ExpandedExplanationTree,TermerizedHTMLlist)
% works ok but not inside SWISH because of its style clobbering ways:
explanationHTML(s(G,Ref,C),[li(title="Rule inference step",["~w"-[G],Navigator]),ul(CH)]) :- 
    clauseNavigator(Ref,Navigator), explanationHTML(C,CH).
explanationHTML(u(G,Ref,[]),[li(title="Unknown",["~w ?"-[G],Navigator])]) :-
    clauseNavigator(Ref,Navigator).
%explanationHTML(unknown(at(G,K)),[li([style="color:blue",title="Unknown"],a(href=K,"~w"-[G]))]).
% explanationHTML(unknown(at(G,K)),[li([p("UNKNOWN: ~w"-[G]),p(i(K))])]).
explanationHTML(f(G,C),[li(title="Failed goal",[span(style="color:red","FALSE: ~w"-[G]),ul(CH)])]) :- explanationHTML(C,CH).
%explanationHTML(at(G,K),[li(style="color:green",a(href=K,"~w"-[G]))]).
%explanationHTML(at(G,K),[li([p("~w"-[G]),p(i(K))])]).
explanationHTML([C1|Cn],CH) :- explanationHTML(C1,CH1), explanationHTML(Cn,CHn), append(CH1,CHn,CH).
explanationHTML([],[]).

% clauseNavigator(+ClauseRef,-HTML)
% clauseNavigator(Ref,a([onclick="myPlayFile('cgt_affiliates.pl',26);"],"SOURCE")).
clauseNavigator(Ref,a([onclick=Handler],"SOURCE")) :- 
    blob(Ref,clause), clause_property(Ref,file(F_)), clause_property(Ref,line_count(L)),
    !,
    % strip swish "file" header:
    ((sub_atom(F_,0,_,R,'swish://'), sub_atom(F_,R,_,0,F)) -> true ; F=F_),
    % could probably use https://www.swi-prolog.org/pldoc/doc_for?object=js_call//1 , but having trouble embedding that as attribute above:
    format(string(Handler),"myPlayFile('~a',~w);",[F,L]).
clauseNavigator(Ref,"No source: ~w"-[Ref]).