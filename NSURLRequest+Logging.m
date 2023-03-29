//
//  NSURLRequest+Logging.m
//
//  Created by Jesus++ on 28.03.2023.
//

#import "NSURLRequest+Logging.h"
#import "NSObject+Swizzling.h"

LogList logList = Log_All;

typedef enum: Byte
{
	clientToServer,
	serverToClient
} Direction;

static void print(Direction d,
				  const char *urlString,
				  const char *methodString,
				  const char *headerString,
				  const char *dataString)
{
	char f1c[] = "\nCLIENT -> SERVER %s\n";
	char f2c[] = "\nCLIENT -> SERVER %s\n%s\n";
	char f3c[] = "\nCLIENT -> SERVER %s\n%s\n%s\n";
	char f4c[] = "\nCLIENT -> SERVER %s\n%s\n%s\n%s\n";

	char f1s[] = "\nSERVER -> CLIENT %s\n";
	char f2s[] = "\nSERVER -> CLIENT %s\n%s\n";
	char f3s[] = "\nSERVER -> CLIENT %s\n%s\n%s\n";
	char f4s[] = "\nSERVER -> CLIENT %s\n%s\n%s\n%s\n";

	switch (logList)
	{
		case Log_None:
			break;
		case Log_Url_Only:
			printf(d ? f1s : f1c, urlString);
			break;
		case Log_Url_Header:
			printf(d ? f2s : f2c, urlString, headerString);
			break;
		case Log_Url_Method:
			printf(d ? f2s : f2c, urlString, methodString);
			break;
		case Log_Url_Body:
			printf(d ? f2s : f2c, urlString, dataString);
			break;
		case Log_Url_Header_Method:
			printf(d ? f3s : f3c, urlString, headerString, methodString);
			break;
		case Log_Url_Header_Body:
			printf(d ? f3s : f3c, urlString, headerString, dataString);
			break;
		case Log_Url_Method_Body:
			printf(d ? f3s : f3c, urlString, methodString, dataString);
			break;
		case Log_All:
			printf(d ? f4s : f4c, urlString, methodString,
				   headerString, dataString);
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
	let bodyData2 = [NSJSONSerialization dataWithJSONObject: bodyObj ?: NSDictionary.new
													options: NSJSONWritingPrettyPrinted
													  error: error];
	if (*error)
		return [NSString stringWithFormat: @"Binary data: %@", data];

	return [NSString.alloc initWithData: bodyData2 ?: NSData.data encoding: NSUTF8StringEncoding];
}

@implementation NSURLRequest (Logging)
+ (void)load
{
	[self gl_swizzleMethod: @selector(initWithURL:)
				withMethod: @selector(initWithURL_sw:)];
}

- (instancetype)initWithURL_sw: (NSURL *)URL
{
	self = [self initWithURL_sw: URL];
	return self;
}

@end


@implementation NSURLSession (Logging)

+ (void)load
{
	[self gl_swizzleMethod: @selector(dataTaskWithRequest:completionHandler:)
				withMethod: @selector(dataTaskWithRequest:completionHandler_sw:)];
}

- (NSURLSessionDataTask *)dataTaskWithRequest: (NSURLRequest *)request
						 completionHandler_sw: (void (^)(NSData * _Nullable,
														 NSURLResponse * _Nullable,
														 NSError * _Nullable))completionHandler
{
	return [self dataTaskWithRequest: request
				completionHandler_sw: ^(NSData * _Nullable data,
										NSURLResponse * _Nullable response,
										NSError * _Nullable error)
	{
		long status = 0;
		let resp = (NSHTTPURLResponse *)response;
		if ([resp respondsToSelector: @selector(statusCode)])
		{
			status = resp.statusCode;
		}

		let headerData = [NSJSONSerialization dataWithJSONObject: request.allHTTPHeaderFields ?: @{}
														 options: NSJSONWritingPrettyPrinted
														   error: &error];

		let headerString = stringFromData(headerData, &error);

		NSError *err = nil;
		let dataString = stringFromData(data, &err);
		if (status != 200)
		{
			let answ = status == 204 ? "SUCCESS" : (char [11]){'S','T','A','T','U','S',' ',
				status/100 ? status/100 + '0' : ' ',
				status%100/10 || status/100 ? status%100/10 + '0' : ' ',
				status%10 + '0'};
			print(serverToClient, request.URL.absoluteString.UTF8String,
				  request.HTTPMethod.UTF8String, headerString.UTF8String, answ);
		}
		else if (!err)
		{
			print(serverToClient, request.URL.absoluteString.UTF8String,
				  request.HTTPMethod.UTF8String, headerString.UTF8String, dataString.UTF8String);
		}
		else if (error)
		{
			print(serverToClient, request.URL.absoluteString.UTF8String, request.HTTPMethod.UTF8String,
				  headerString.UTF8String, dataString.UTF8String ?: error.localizedDescription.UTF8String);
		}
		completionHandler(data, response, error);
	}];
}

@end

@implementation NSURLSessionTask (Logging)

+ (void)load
{
	[self gl_swizzleMethod: @selector(resume) withMethod: @selector(resume_sw)];
}

- (void)resume_sw
{
	NSError *error = nil;
	let urlString = self.currentRequest.URL.absoluteString;
	let bodyData = self.currentRequest.HTTPBody ?: NSData.data;
	let dataString = stringFromData(bodyData, &error);
	let methodString = self.currentRequest.HTTPMethod;

	let headerData = [NSJSONSerialization dataWithJSONObject: self.currentRequest.allHTTPHeaderFields ?: @{}
													 options: NSJSONWritingPrettyPrinted
													   error: &error];

	let headerString = stringFromData(headerData, &error);

	print(clientToServer, urlString.UTF8String,
		  methodString.UTF8String, headerString.UTF8String, dataString.UTF8String);

	[self resume_sw];
}

@end
