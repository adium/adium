%{
/*
 * The AutoHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AutoHyperlinks Framework nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 *	Options used:	noyywrap            : act as if yywrap always returns 1
 *					8bit                : always force 8-bit chars.
 *					caseless            : case insensitive lexer
 *					never-interactive   : prevents flex from including some calls to gettty() and such
 *										  -- gives a slight performace gain.
 *					prefix=...          : replace YY_whatever with prefix - avoids symbol collisions
 *					debug               : turns on debugging output (string + accepting rule)
 *										  -- only use while editing rules, and don't commit with this on
 *										     (it generates a lot of unnecessary output and kills performace.)
 *
 *	Variables used:		uint AHStringOffset : the position of the pointer, relative to the parent string
 *											  incremented by yyleng at each yylex() call.
 *	               		 int AHValidShift	: Used only in CANONICAL start state
 *											  ensures that yyleng reports whole length of the string,
 *											  without a costly call to yymore().
 */
#include "AHLinkLexer.h"
%}

ccTLD           (ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)
sTLD            (com|edu|gov|int|mil|net|org|biz|info|name|pro)
uTLD            (aero|coop|museum|mobi|cat|jobs|travel)

TLDs            ({ccTLD}|{sTLD}|{uTLD}|arpa|local)

%{
/*The Unicode standard, version 4.1, table 3-6, says that the highest byte that will occur in a valid UTF-8 sequence is 0xF4.*/
%}
userAndPass     [^:@[:space:]]+(:[^:@[:space:]]+)?
singleDomain    [_[:alnum:]\x80-\xf4-]+

urlPath         \/[^[:space:]]*
urlQuery        \?.*
urlSpec         ({singleDomain}\.)+{TLDs}(:[0-9]+)?({urlPath}|{urlQuery})?
urlCSpec        {singleDomain}(\.{singleDomain})*(:[0-9]+)?({urlPath}|{urlQuery})?

ipv4address     ([0-9]{1,3}\.){3}([0-9]{1,3})
ipURL           {ipv4address}(:[0-9]+)?{urlPath}?

hex4            [0-9A-Fa-f]{1,4}
ipv6HexSeq      {hex4}?(::?{hex4}){1,7}
ipv6HexPart     ({ipv6HexSeq})|(::{ipv6HexSeq})
ipv6Address     {ipv6HexPart}({ipv4address})?
ipv6URL         \[{ipv6Address}](:[0-9]+)?{urlPath}?

userAtDomain	[^:@\/[:space:]]+\@{singleDomain}(\.{singleDomain})*
mailSpec        {userAtDomain}\.{TLDs}

%option noyywrap nounput noinput 8bit caseless align never-interactive reentrant warn prefix="AH"

%x CANONICAL TENTATIVE
%%

<CANONICAL>({userAndPass}@)?{urlCSpec}|{ipURL}|{ipv6URL} {yyleng += yyextra.urlLength;
                                                          BEGIN INITIAL;
                                                          return AH_URL_VALID;}

<CANONICAL>.*                                            {BEGIN INITIAL;
                                                          return AH_URL_INVALID;}

<TENTATIVE>[^[:space:]]+                                 {yyleng += yyextra.urlLength;
                                                          BEGIN INITIAL;
                                                          return AH_URL_TENTATIVE;}

<TENTATIVE>.*                                            {BEGIN INITIAL;
                                                          return AH_URL_INVALID;}

file:\/\/\/.*           {return AH_FILE_VALID;}


telnet:\/\/             |
daap:\/\/               |
itms:\/\/               |
smb:\/\/                |
afp:\/\/                |
s?ftp:\/\/              |
vnc:\/\/                |
webcal:\/\/             |
feeds?:\/\/             |
cifs:\/\/               |
help:\/\/               |
rtsp:\/\/               |
ssh:\/\/                |
https?:\/\/             {yyextra.urlLength = yyleng; yyextra.schemeLength = yyleng - 3; BEGIN CANONICAL;}

[[:alnum:]\-_]+:\/\/    {yyextra.urlLength = yyleng; yyextra.schemeLength = yyleng - 3; BEGIN TENTATIVE;}

mailto:{mailSpec}       {return AH_MAILTO_VALID;}
{mailSpec}              {return AH_MAILTO_DEGENERATE;}

[[:alnum:]\-_]+:        {yyextra.urlLength = yyleng; yyextra.schemeLength = yyleng - 1; BEGIN TENTATIVE;}

{urlSpec}               {return AH_URL_DEGENERATE;}

.                       {return AH_URL_INVALID;}
%%
