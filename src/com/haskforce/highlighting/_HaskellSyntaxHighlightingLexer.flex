package com.haskforce.highlighting;
import com.intellij.lexer.*;
import com.intellij.psi.tree.IElementType;
import static com.haskforce.psi.HaskellTypes.*;
import com.intellij.util.containers.ContainerUtil;
import com.intellij.util.containers.Stack;

/**
 * Hand-written lexer used for syntax highlighting in IntelliJ.
 *
 * We currently share token names with the grammar-kit generated
 * parser.
 *
 * Derived from the lexer generated by Grammar-Kit at 29 April 2014.
 */


/*
 * To generate sources from this file -
 *   Click Tools->Run JFlex generator.
 *
 * Command-Shift-G should be the keyboard shortcut, but that is the same
 * shortcut as find previous.
 */


%%

%{
  private int commentLevel;
  private int qqLevel;
  private int indent;
  private Stack<Integer> stateStack = ContainerUtil.newStack();
  private int yychar;
  // Shared varsym token to ensure that shebang lex failures return the same
  // token as normal varsyms.
  public static final IElementType SHARED_VARSYM_TOKEN = VARSYMTOK;
  public _HaskellSyntaxHighlightingLexer() {
    this((java.io.Reader)null);
  }
%}

/*
 * Missing lexemes: by, haddock things.
 *
 * Comments: one line too many in dashes-comments.
 */

%public
%class _HaskellSyntaxHighlightingLexer
%implements FlexLexer
%function advance
%type IElementType
%unicode
%char
%eof{  return;
%eof}

EOL=\r|\n|\r\n
LINE_WS=[\ \t\f]
WHITE_SPACE=({LINE_WS}|{EOL})+

VARIDREGEXP=([a-z_][a-zA-Z_0-9']+(\.[a-zA-Z_0-9']*)*)|[a-z]|[A-Z][a-zA-Z_0-9']*(\.[A-Z][a-zA-Z_0-9']*)*\.[a-z][a-zA-Z_0-9']*
// Unlike HaskellParsingLexer, we don't lex the unit type () as a CONID.
// The reason is that brace matching breaks.  The HaskellAnnotator takes care
// of the appropriate highlighting for unit type ().
CONID=[A-Z][a-zA-Z_0-9']*(\.[A-Z][a-zA-Z_0-9']*)*
INFIXVARID=`[a-zA-Z_0-9][a-zA-Z_0-9']*`
CHARTOKEN='(\\.|[^'])'
INTEGERTOKEN=(0(o|O)[0-7]+|0(x|X)[0-9a-fA-F]+|[0-9]+)
FLOATTOKEN=([0-9]+\.[0-9]+((e|E)(\+|\-)?[0-9]+)?|[0-9]+((e|E)(\+|\-)?[0-9]+))
COMMENT=--([^\^\r\n][^\r\n]*\n|[\r\n])
HADDOCK=--\^[^\r\n]*
CPPIF=#if ([^\r\n]*)
ASCSYMBOL=[\!\#\$\%\&\*\+\.\/\<\=\>\?\@\\\^\|\-\~\:]

STRINGGAP=\\[ \t\n\x0B\f\r]*\n[ \t\n\x0B\f\r]*\\
MAYBEQVARID=({CONID}\.)*{VARIDREGEXP}

// Avoid "COMMENT" since that collides with the token definition above.
%state INCOMMENT, INSTRING, INPRAGMA, INQUASIQUOTE, INQUASIQUOTEHEAD, INSHEBANG

%%
<YYINITIAL> {
  "#!"                {
                        if (yychar == 0) {
                            yybegin(INSHEBANG);
                            return SHEBANGSTART;
                        }
                        return SHARED_VARSYM_TOKEN;
                      }
  {WHITE_SPACE}       { return com.intellij.psi.TokenType.WHITE_SPACE; }

  "class"             { return CLASSTOKEN; }
  "data"              { return DATA; }
  "default"           { return DEFAULT; }
  "deriving"          { return DERIVING; }
  "export"            { return EXPORTTOKEN; }
  "foreign"           { return FOREIGN; }
  "instance"          { return INSTANCE; }
  "family"            { return FAMILYTOKEN; }
  "module"            { return MODULETOKEN; }
  "newtype"           { return NEWTYPE; }
  "type"              { return TYPE; }
  "where"             { return WHERE; }
  "as"                { return AS; }
  "import"            { return IMPORT; }
  "infix"             { return INFIX; }
  "infixl"            { return INFIXL; }
  "infixr"            { return INFIXR; }
  "qualified"         { return QUALIFIED; }
  "hiding"            { return HIDING; }
  "case"              { return CASE; }
  "mdo"               { return MDOTOK; }
  "do"                { return DO; }
  "rec"               { return RECTOK; }
  "else"              { return ELSE; }
  "#else"             { return CPPELSE; }
  "#endif"            { return CPPENDIF; }
  "if"                { return IF; }
  "in"                { return IN; }
  "let"               { return LET; }
  "of"                { return OF; }
  "then"              { return THEN; }
  "forall"            { return FORALLTOKEN; }

  "\\&"               { return NULLCHARACTER; }
  "(#"                { return LUNBOXPAREN; }
  "#)"                { return RUNBOXPAREN; }
  "("                 { return LPAREN; }
  ")"                 { return RPAREN; }
  "|"                 { return PIPE; }
  ","                 { return COMMA; }
  ";"                 { return SEMICOLON; }
  "[|"                { return LTHOPEN; }
  ("["{MAYBEQVARID}"|") {
                            yypushback(yytext().length() - 1);
                            qqLevel++;
                            stateStack.push(YYINITIAL);
                            yybegin(INQUASIQUOTEHEAD);
                            return QQOPEN;
                        }
  "|]"                { return RTHCLOSE; }
  "["                 { return LBRACKET; }
  "]"                 { return RBRACKET; }
  "''"                { return THQUOTE; }
  "`"                 { return BACKTICK; }
  "\""                {
                        yybegin(INSTRING);
                        return DOUBLEQUOTE;
                      }
  "{-#"               {
                        yybegin(INPRAGMA);
                        return OPENPRAGMA;
                      }
  "{-"                {
                        commentLevel = 1;
                        yybegin(INCOMMENT);
                        return OPENCOM;
                      }
  "{"                 { return LBRACE; }
  "}"                 { return RBRACE; }
  "'"                 { return SINGLEQUOTE; }
  "$("                { return PARENSPLICE; }
  ("$"{VARIDREGEXP})  { return IDSPLICE; }
  "_"                 { return UNDERSCORE; }
  ".."                { return DOUBLEPERIOD; }
  ":"                 { return COLON; }
  "::"                { return DOUBLECOLON; }
  "="                 { return EQUALS; }
  "\\"                { return BACKSLASH; }
  "|"                 { return PIPE; }
  "<-"                { return LEFTARROW; }
  "->"                { return RIGHTARROW; }
  "@"                 { return AMPERSAT; }
  "~"                 { return TILDE; }
  "=>"                { return DOUBLEARROW; }
  (":"{ASCSYMBOL}+)   { return CONSYMTOK; }
  ({ASCSYMBOL}+)      { return SHARED_VARSYM_TOKEN; }

  {VARIDREGEXP}       { return VARIDREGEXP; }
  {CONID}             { return CONIDREGEXP; }
  {INFIXVARID}        { return INFIXVARID; }
  {CHARTOKEN}         { return CHARTOKEN; }
  {INTEGERTOKEN}      { return INTEGERTOKEN; }
  {FLOATTOKEN}        { return FLOATTOKEN; }
  {COMMENT}           { return COMMENT; }
  {HADDOCK}           { return HADDOCK; }
  {CPPIF}             { return CPPIF; }

  [^] { return com.intellij.psi.TokenType.BAD_CHARACTER; }
}

<INSHEBANG> {
  [^\n\r]+  { yybegin(YYINITIAL); return SHEBANGPATH; }
  [\n\r]    { yybegin(YYINITIAL); return com.intellij.psi.TokenType.WHITE_SPACE; }
}

<INCOMMENT> {
    "-}"              {
                        commentLevel--;
                        if (commentLevel == 0) {
                            yybegin(YYINITIAL);
                            return CLOSECOM;
                        }
                        return COMMENTTEXT;
                      }

    "{-"              {
                        commentLevel++;
                        return COMMENTTEXT;
                      }

    [^-{}]+           { return COMMENTTEXT; }
    [^]               { return COMMENTTEXT; }
}

<INSTRING> {
    \"                              {
                                        yybegin(YYINITIAL);
                                        return DOUBLEQUOTE;
                                    }
    (\\)+                           { return STRINGTOKEN; }
    ({STRINGGAP}|\\\"|[^\"\\\n])+   { return STRINGTOKEN; }

    [^]                             { return BADSTRINGTOKEN; }
}

<INPRAGMA> {
    "#-}"           {
                        yybegin(YYINITIAL);
                        return CLOSEPRAGMA;
                    }
    [^-}#]+         { return PRAGMA; }
    [^]             { return PRAGMA; }
}

<INQUASIQUOTE> {
    "|]"                    {
                                qqLevel--;
                                yybegin(stateStack.pop());
                                if (qqLevel == 0) {
                                    return RTHCLOSE;
                                }
                                return QQTEXT;
                            }

    ("["{MAYBEQVARID}"|")   {
                                yypushback(yytext().length() - 1);
                                qqLevel++;
                                stateStack.push(INQUASIQUOTE);
                                yybegin(INQUASIQUOTEHEAD);
                                return QQTEXT;
                            }
    [^|\]\[]+               { return QQTEXT; }
    [^]                     { return QQTEXT; }
}

<INQUASIQUOTEHEAD> {
  "|"                       {
                                yybegin(INQUASIQUOTE);
                                return PIPE;
                            }
  {VARIDREGEXP}             { return VARIDREGEXP; }
  {CONID}                   { return CONIDREGEXP; }
  "."                       { return PERIOD;}
  {EOL}+                    {
                                indent = 0;
                                return com.intellij.psi.TokenType.WHITE_SPACE;
                            }
  [\ \f\t]+                 { return com.intellij.psi.TokenType.WHITE_SPACE; }
  [^]                       { return com.intellij.psi.TokenType.BAD_CHARACTER; }
}
