//
//  NSURLRequest+Logging.m
//
//  Created by Jesus++ on 28.03.2023.
//

#import "NSURLRequest+Logging.h"
#import "NSObject+Swizzling.h"

#define answerFromStatus(status) status == 204 ? "SUCCESS" : (char [11]){'S','T','A','T','U','S',' ',\
									status / 100 ? status / 100 + '0' : ' ',\
									status % 100 / 10 || status / 100 ? status % 100 / 10 + '0' : ' ',\
									status % 10 + '0'}
#define CS "\nCLIENT -> SERVER "
#define SC "\nSERVER -> CLIENT "
#define L1 "%s\n"
#define L2 "%s\n%s\n"
#define L3 "%s\n%s\n%s\n"
#define L4 "%s\n%s\n%s\n%s\n"

LogList logList = Log_All;

typedef enum: Byte
{
	clientToServer,
	serverToClient
} Direction;

typedef void(^CompletionBlock)(NSData *data, NSURLResponse *response, NSError *error);

static void print(Direction d,
				  const char *urlString,
				  const char *methodString,
				  const char *headerString,
				  const char *dataString)
{
	let url = urlString ?: "";
	let method = methodString ?: "";
	let header = headerString ?: "";
	let data = dataString ?: "";

	switch (logList)
	{
		case Log_None:
			break;
		case Log_Url_Only:
			printf(d ? SC L1 : CS L1, url);
			break;
		case Log_Url_Header:
			printf(d ? SC L2 : CS L2, url, header);
			break;
		case Log_Url_Method:
			printf(d ? SC L2 : CS L2, url, method);
			break;
		case Log_Url_Body:
			printf(d ? SC L2 : CS L2, url, data);
			break;
		case Log_Url_Header_Method:
			printf(d ? SC L3 : CS L3, url, header, method);
			break;
		case Log_Url_Header_Body:
			printf(d ? SC L3 : CS L3, url, header, data);
			break;
		case Log_Url_Method_Body:
			printf(d ? SC L3 : CS L3, url, method, data);
			break;
		case Log_All:
			printf(d ? SC L4 : CS L4, url, method, header, data);
			break;
	}
}

static NSString *stringFromData(NSData *data, NSError **error)
{
	*error = nil;
	id bodyObj = [NSJSONSerialization JSONObjectWithData: data ?: NSData.data
												 options: NSJSONReadingFragmentsAllowed
												   error: error];
	if (*error)
		return [NSString stringWithFormat: @"Binary data: %@", data];

	let bodyData2 = [NSJSONSerialization dataWithJSONObject: bodyObj ?: @{}
													options: NSJSONWritingPrettyPrinted
													  error: error];
	if (*error)
		return [NSString stringWithFormat: @"Binary data: %@", data];

	return [NSString.alloc initWithData: bodyData2 ?: NSData.data encoding: NSUTF8StringEncoding];
}

@implementation NSURLRequest (Logging)

+ (void)load
{
	[self swizzleMethod: @selector(initWithURL:)
			 withMethod: @selector(initWithURL_sw:)];
}

- (instancetype)initWithURL_sw: (NSURL *)URL
{
	self = [self initWithURL_sw: URL];
	return self;
}

@end

// MARK: - NSURLSession (Logging)

@implementation NSURLSession (Logging)

+ (void)load
{
	[self swizzleMethod: @selector(dataTaskWithRequest:completionHandler:)
			 withMethod: @selector(dataTaskWithRequest:completionHandler_sw:)];

	[self swizzleMethod: @selector(dataTaskWithRequest:)
			 withMethod: @selector(dataTaskWithRequest_sw:)];
}

- (CompletionBlock)proxyBlockWithRequest: (NSURLRequest *)request
						   andCompletion: (nullable CompletionBlock)completion
{
	return ^(NSData *data,
			 NSURLResponse *response,
			 NSError *error)
	{
		NSError *decodingError = nil;
		let httpResponse = [response isKindOfClass: NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
		let status = httpResponse.statusCode;
		let headerData = [NSJSONSerialization dataWithJSONObject: httpResponse.allHeaderFields ?: @{}
														 options: NSJSONWritingPrettyPrinted
														   error: &error];
		let headerString = stringFromData(headerData, &error);
		let dataString = stringFromData(data, &decodingError);
		let errorString = error.localizedDescription ?: decodingError.localizedDescription;
		let success = status == 200;

		let answer = errorString ?: success ? dataString : @(answerFromStatus(status));

		print(serverToClient,
			  httpResponse.URL.absoluteString.UTF8String,
			  request.HTTPMethod.UTF8String,
			  headerString.UTF8String,
			  answer.UTF8String);

		if (completion)
			completion(data, response, error);
	};
}

- (NSURLSessionDataTask *)dataTaskWithRequest: (NSURLRequest *)request
						 completionHandler_sw: (CompletionBlock)completionHandler
{
	return [self dataTaskWithRequest: request
				completionHandler_sw: [self proxyBlockWithRequest: request
													andCompletion: completionHandler]];
}

- (NSURLSessionDataTask *)dataTaskWithRequest_sw: (NSURLRequest *)request
{
	let task = [self dataTaskWithRequest: request
					completionHandler_sw: [self proxyBlockWithRequest: request
													 andCompletion: nil]];

	return task;
}

@end

// MARK: - NSURLSessionTask (Logging)

@implementation NSURLSessionTask (Logging)

+ (void)load
{
	[self swizzleMethod: @selector(resume) withMethod: @selector(resume_sw)];
}

- (void)resume_sw
{
	NSError *decodingError = nil;
	NSError *serializationError = nil;
	let urlString = self.currentRequest.URL.absoluteString;
	let bodyData = self.currentRequest.HTTPBody ?: NSData.data;
	let dataString = stringFromData(bodyData, &decodingError);
	let methodString = self.currentRequest.HTTPMethod;

	let headerData = [NSJSONSerialization dataWithJSONObject: self.currentRequest.allHTTPHeaderFields ?: @{}
													 options: NSJSONWritingPrettyPrinted
													   error: &serializationError];

	let headerString = stringFromData(headerData, &decodingError);
	let output = decodingError.localizedDescription ?: serializationError.localizedDescription ?: dataString;

	print(clientToServer, urlString.UTF8String,
		  methodString.UTF8String, headerString.UTF8String, output.UTF8String);

	[self resume_sw];
}

@end
