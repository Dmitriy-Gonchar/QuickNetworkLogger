//
//  NSURLRequest+Logging.h
//
//  Created by Jesus++ on 28.03.2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum
{
	Log_None,
	Log_Url_Only,
	Log_Url_Header,
	Log_Url_Method,
	Log_Url_Body,
	Log_Url_Header_Method,
	Log_Url_Header_Body,
	Log_Url_Method_Body,
	Log_All
} LogList;

extern LogList logList;

@interface NSURLRequest (Logging)
@end

@interface NSURLSession (Logging)
@end

NS_ASSUME_NONNULL_END
