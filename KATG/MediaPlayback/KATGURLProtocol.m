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
static NSMutableDictionary *urlsWithError;

@implementation KATGURLProtocol
// register the class to intercept all HTTP calls
+ (void) register {
    [NSURLProtocol registerClass:[self class]];
}

// public static function to call when injecting a cookie
+ (void) injectURL:(NSString*) urlString cookie:(NSString*)cookie {
    injectedURL = urlString;
    myCookie = cookie;
    urlsWithError = [NSMutableDictionary dictionary];
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
    return [[[request URL] absoluteString] isEqualToString:injectedURL];
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
    [myRequest setValue:myCookie forHTTPHeaderField:@"Cookie"];
    connection = [[NSURLConnection alloc] initWithRequest:myRequest delegate:self];
}

// overload didReceive data
- (void)connection:(NSURLConnection *)_connection didReceiveData:(NSData *)data {
    NSString *result = [urlsWithError valueForKey:[_connection.currentRequest.URL absoluteString]];
    if(result && [result length] == 0)
        [urlsWithError setObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                          forKey:[_connection.currentRequest.URL absoluteString]];
    [[self client] URLProtocol:self didLoadData:data];
}

// overload didReceiveResponse
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    if([response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse*)response statusCode] > 400) {
        [urlsWithError setObject:@"" forKey:[response.URL absoluteString]];
    }
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:[myRequest cachePolicy]];
}

// overload didFinishLoading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[self client] URLProtocolDidFinishLoading:self];
}

// overload didFail
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[self client] URLProtocol:self didFailWithError:error];
}

// handle load cancelation
- (void)stopLoading {
    [connection cancel];
}

@end
