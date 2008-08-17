/*
Copyright (C) 2007 Stig Brautaset. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

  Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

  Neither the name of the author nor the names of its contributors may be used
  to endorse or promote products derived from this software without specific
  prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSString+SBJSON.h"
#import "SBJSON.h"


@implementation NSString (NSString_SBJSON)

- (id)JSONFragmentValueWithOptions:(NSDictionary *)opts
{
    SBJSON *json = [SBJSON new];
    
    if (opts) {
        id opt = [opts objectForKey:@"MaxDepth"];
        if (opt)
            [json setMaxDepth:[opt intValue]];
    }
    
    NSError *error;
    id o = [json fragmentWithString:self error:&error];
    [json release];

    if (!o)
        NSLog(@"%@", error);
    return o;
}


- (id)JSONValueWithOptions:(NSDictionary *)opts
{
    SBJSON *json = [SBJSON new];
    
    if (opts) {
        id opt = [opts objectForKey:@"MaxDepth"];
        if (opt)
            [json setMaxDepth:[opt intValue]];
    }
    
    NSError *error;
    id o = [json objectWithString:self error:&error];

    if (!o)
        NSLog(@"%@", error);
	[json release];
    return o;
}

- (id)JSONFragmentValue
{
    return [self JSONFragmentValueWithOptions:nil];
}

- (id)JSONValue
{
    return [self JSONValueWithOptions:nil];
}

@end
