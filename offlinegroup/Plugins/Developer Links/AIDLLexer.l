%{
unsigned int AIDLStringOffset;
int AIDLValidShift = 0;
#include "AIDLLexer.h"
%}

%option noyywrap nounput 8bit caseless never-interactive prefix="AIDL"

%%

r[0-9]+     {AIDLStringOffset += AIDLleng;
             return AIDL_REVISION;}
			 
\[[0-9]+\]  {AIDLStringOffset += AIDLleng;
             return AIDL_CHANGESET;}

\#[0-9]+    {AIDLStringOffset += AIDLleng;
             return AIDL_TICKET;}

.           return AIDL_URL_INVALID;
%%