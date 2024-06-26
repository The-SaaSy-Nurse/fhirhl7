/**
 * Define a grammar called FhirMapper
 */
 grammar mapping;

// starting point for parsing a mapping file
// in case we need nested ConceptMaps, we need to have this rule:
// structureMap : mapId conceptMap* structure* imports* group+

structureMap
    : mapId structure* imports* const* group+ EOF
    ;

mapId
	: 'map' url '=' identifier
	;

url
    : DELIMITEDIDENTIFIER
    ;

identifier
    : IDENTIFIER
    | DELIMITEDIDENTIFIER
    ;

structure
	: 'uses' url structureAlias? 'as'  modelMode
	;

structureAlias
    : 'alias' identifier
    ;

imports
	: 'imports' url
	;

const 
    : 'let' id '=' fhirPath ';' // which might just be a literal

group
	: 'group' id parameters extends? typeMode? rules
	;

rules
    : '{' rule* '}'
    ;

typeMode
    : '<<' groupTypeMode '>>'
    ;

extends
    : 'extends' id
    ;

parameters
    : '(' parameter (',' parameter)+ ')'
    ;

parameter
    : inputMode id type?
	;

type
    : ':' identifier
    ;

rule
 	: ruleSources ('->' ruleTargets)? dependent? ruleName? ';'
 	;

ruleName
    : id
    ;

ruleSources
    : ruleSource (',' ruleSource)*
    ;

ruleSource
    :  ruleContext sourceType? sourceCardinality? sourceDefault? sourceListMode? alias? whereClause? checkClause? log?
    ;

ruleTargets
    : ruleTarget (',' ruleTarget)*
    ;

sourceType
    : ':' identifier
    ;

sourceCardinality
    : INTEGER '..' upperBound
    ;

upperBound
    : INTEGER
    | '*'
    ;

ruleContext
	: identifier ('.' identifier)*
	;

sourceDefault
    : 'default' '(' fhirPath ')'
    ;

alias
	: 'as' identifier
	;

whereClause
    : 'where' '(' fhirPath ')'
    ;

checkClause
    : 'check' '(' fhirPath ')'
    ;

log
    : 'log' '(' fhirPath ')'
    ;

dependent
    : 'then' (invocation (',' invocation)* rules? | rules)
    ;

ruleTarget
    : ruleContext ('=' transform)? alias? targetListMode?
    | invocation alias?     // alias is not required when simply invoking a group
    ;

transform
    : literal           // trivial constant transform
    | ruleContext       // 'copy' transform
    | invocation        // other named transforms
    ;

invocation
    : identifier '(' paramList? ')'
    ;

paramList
    : param (',' param)*
    ;

param
    : literal
    | id
    ;

fhirPath
    : literal       // insert reference to FhirPath grammar here
    ;

literal
    : INTEGER
    | NUMBER
    | STRING
    | DATETIME
    | DATE
    | TIME
    | BOOL
    ;

groupTypeMode
    : 'types' | 'type+'
    ;

sourceListMode
    : 'first' | 'not_first' | 'last' | 'not_last' | 'only_one'
    ;

targetListMode
   : 'first' | 'share' | 'last' | 'single'
   ;

inputMode
   : 'source' | 'target'
   ;

modelMode           // StructureMapModelMode binding
    : 'source' | 'queried' | 'target' | 'produced'
    ;



    /*
     * Syntax for embedded ConceptMaps excluded for now
     *
    conceptMap
        : 'conceptMap' '"#'	IDENTIFIER '{' (prefix)+ conceptMapping '}'
        ;

    prefix
    	: 'prefix' conceptMappingVar '=' URL
    	;

    conceptMappingVar
    	:  IDENTIFIER
    	;
    conceptMapping
    	:  conceptMappingVar ':' field
    	   (('<=' | '=' | '==' | '!=' '>=' '>-' | '<-' | '~') conceptMappingVar ':' field) | '--'
    	;
    */




/****************************************************************
    Lexical rules from FhirPath
*****************************************************************/

BOOL
        : 'true'
        | 'false'
        ;

DATE
        : '@' DATEFORMAT
        ;

DATETIME
        : '@' DATEFORMAT 'T' (TIMEFORMAT TIMEZONEOFFSETFORMAT?)?
        ;

TIME
        : '@' 'T' TIMEFORMAT
        ;

fragment DATEFORMAT
        : [0-9][0-9][0-9][0-9] ('-'[0-9][0-9] ('-'[0-9][0-9])?)?
        ;

fragment TIMEFORMAT
        : [0-9][0-9] (':'[0-9][0-9] (':'[0-9][0-9] ('.'[0-9]+)?)?)?
        ;

fragment TIMEZONEOFFSETFORMAT
        : ('Z' | ('+' | '-') [0-9][0-9]':'[0-9][0-9])
        ;

id
        : ([A-Za-z] )([A-Za-z0-9])*            
        ;

IDENTIFIER
        : ([A-Za-z] | '_')([A-Za-z0-9] | '_')*            // Added _ to support CQL (FHIR could constrain it out)
        ;

DELIMITEDIDENTIFIER
        '`' (ESC | .)*? '`'
        ;

STRING
        : '\'' (ESC | .)*? '\''
        ;

INTEGER
    : [0-9]+
    ;

// Also allows leading zeroes now (just like CQL and XSD)
NUMBER
    : INTEGER ('.' [0-9]+)?
    ;

// Pipe whitespace to the HIDDEN channel to support retrieving source text through the parser.
WS
    : [ \r\n\t]+ -> channel(HIDDEN)
    ;

COMMENT
        : '/*' .*? '*/' -> channel(HIDDEN)
        ;

LINE_COMMENT
        : '//' ~[\r\n]* -> channel(HIDDEN)
        ;

fragment ESC
        : '\\' (["'\\/fnrt] | UNICODE)    // allow \", \', \\, \/, \f, etc. and \uXXX
        ;

fragment UNICODE
        : 'u' HEX HEX HEX HEX
        ;

fragment HEX
        : [0-9a-fA-F]
        ;
