//
//  KATGURLProtocol.m
//  KATG
//
//  Created by Nicolas Rostov on 12.05.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGURLProtocol.h"

@interface KATGURLProtocol() <NSURLConnectionDelegate> {
    NSMutableURLRequest *myRequest;
    NSURLConnection *connection;
}
@end

static NSString* injectedURL = nil;
static NSString* myCookie = nil;
static NSMutableDictionary *urlsWithError = nil;

@implementation KATGURLProtocol
// register the class to intercept all HTTP calls
+ (void) register {
    [NSURLProtocol registerClass:[self class]];
    if(!urlsWithError)
        urlsWithError = [NSMutableDictionary dictionary];
}

// public static function to call when injecting a cookie
+ (void) injectURL:(NSString*) urlString cookie:(NSString*)cookie {
    injectedURL = urlString;
    myCookie = cookie;
}

+ (NSString*) errorForUrlString:(NSString*)urlString {
    NSString *result = [urlsWithError valueForKey:urlString];
    if(result)
        [urlsWithError removeObjectForKey:urlString];
    return result;
}

// decide whether or not the call should be intercepted
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if([[[request allHTTPHeaderFields] objectForKey:@"MOBILE_APP"] isEqualToString:@"KATG"]) {
        return NO;
    }
    return YES || [[[request URL] absoluteString] isEqualToString:injectedURL];
}

// required (don't know what this means)
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

// intercept the request and handle it yourself
- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    
    if (self = [super initWithRequest:request cachedResponse:cachedResponse client:client]) {
        myRequest = request.mutableCopy;
        [myRequest setValue:@"KATG" forHTTPHeaderField:@"MOBILE_APP"]; // add your own signature to the request
    }
    return self;
}

// load the request
- (void)startLoading {
    //  inject your cookie
//    [myRequest setValue:myCookie forHTTPHeaderField:@"Cookie"];
    
    if(![[myRequest.allHTTPHeaderFields allKeys] containsObject:@"Cookie"]) {
        if([[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:myRequest.URL] count] > 0) {
            NSMutableArray *cookiesArray = [NSMutableArray array];
            for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:myRequest.URL]) {
                NSString *cookieString = [NSString stringWithFormat:@"%@=%@", cookie.name, cookie.value];
                if(![cookiesArray containsObject:cookieString])
                    [cookiesArray addObject:cookieString];
            }
            [myRequest setValue:[cookiesArray componentsJoinedByString:@";"] forHTTPHeaderField:@"Cookie"];
            NSLog(@"KATGURLProtocol startLoading: %@ with cookie: %@", [myRequest.URL absoluteString], myCookie);
        }
    }
    [myRequest setValue:[NSString stringWithFormat:@"KATG iOS version %@", APP_VERSION] forHTTPHeaderField:@"User-agent"];
    connection = [[NSURLConnection alloc] initWithRequest:myRequest delegate:self];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    NSLog(@"KATGURLProtocol willSendRequest: %@ with headers: %@", [request.URL absoluteString], [request allHTTPHeaderFields]);
    return request;
}

// overload didReceive data
- (void)connection:(NSURLConnection *)_connection didReceiveData:(NSData *)data {
    NSString *result = [urlsWithError valueForKey:[_connection.currentRequest.URL absoluteString]];
    if(result && [result length] == 0) {
        [urlsWithError setObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                          forKey:[_connection.currentRequest.URL absoluteString]];
        
        NSLog(@"KATGURLProtocol addError: %@ for URL: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], [_connection.currentRequest.URL absoluteString]);
    }
    [[self client] URLProtocol:self didLoadData:data];
}

// overload didReceiveResponse
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    if([response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse*)response statusCode] > 400) {
        [urlsWithError setObject:@"" forKey:[response.URL absoluteString]];
    }
    
    NSLog(@"KATGURLProtocol didReceiveResponse: %i for url: %@", (int)[(NSHTTPURLResponse*)response statusCode], [response.URL absoluteString]);
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:[myRequest cachePolicy]];
}

// overload didFinishLoading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[self client] URLProtocolDidFinishLoading:self];
}

// overload didFail
- (void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error {
    [[self client] URLProtocol:self didFailWithError:error];
    
    NSLog(@"KATGURLProtocol didFailWithError: %@ for url: %@", error, [_connection.currentRequest.URL absoluteString]);
}

// handle load cancelation
- (void)stopLoading {
    [connection cancel];
}

@end
