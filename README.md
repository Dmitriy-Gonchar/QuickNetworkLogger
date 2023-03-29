# QuickNetworkLogger

## Usage  
Just add files to your project and set the desired target. The following data can be output to the console for each request: URL, headers, body, http method.

* URL - the address of the request / response is displayed
* Headers - headers are displayed in the form of JSON
* HTTP method - displays the request method (POST/GET/DELETE/ETC)
* Body - the body of the request is displayed if the data is serialized (JSON), it is output in a human-readable format with indents, if not, the size of the transmitted / received data is displayed, also with a response code of 204, which does not imply sending the body, it is simply displayed SUCCESS .

## Example
```

CLIENT -> SERVER https://example.com/path_to_request
POST
{
    "User-Agent": "MyApp"
}
{
    "Body-field-for-added-value": "anyValue"
}

SERVER -> CLIENT https://example.com/path_to_request
POST
{
}
SUCCESS
```

## Enjoy👌🏻