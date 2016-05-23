title: "HTTP重定向状态码的区别"
date: 2016-05-23 18:13:53
categories: HTTP
tags: [HTTP,redirect,重定向]
---
**摘要**：HTTP重定向状态码区分。
**Abstract**: Difference between HTTP redirect code 301, 302, 303, 307
<!-- more -->

|状态码|原因短语|含义|
|:----|:---|:--|
|301|Moved Permanently|资源被永久移除。客户端后续应该请求到新的URI上（相应报文首部给出），客户端需要向新的URI重新发起请求。后续的请求也都应该请求新的URI。|
|302|Found|临时重定向。客户端后续请求仍然使用原有的URI。|
|303|See Other(since HTTP/1.1)|告诉客户端，用Get方法请求给定的新URI中的资源。对于POST/PUT/DELETE请求，客户端应该假定服务器已经收到并处理了该请求，应该向新的URI再发一次GET请求来获取结果。后续请求还需要请求到老URI上。|
|307|Temporary Redirect (since HTTP/1.1)|临时重定向。对于所有POST/PUT/DELETE请求，客户端**应当重新发起本次请求**。后续的请求还应该使用老的URI。|


`302 Found`标准与实现有偏差，The HTTP/1.0（RFC 1945）规定客户端需要做临时重定向，原始的描述是`"Moved Temporarily"`，本应实现成307所描述的功能，但是主流的浏览器实现成了类似303 See Other的功能。因此在HTTP/1.1中，增加了303和307两个状态码来区分两种不同的行为。

## 参考

* 1 [Difference between HTTP redirect codes](http://stackoverflow.com/questions/4764297/difference-between-http-redirect-codes)
* 2 Gourley, David, and Brian Totty. HTTP: the definitive guide. " O'Reilly Media, Inc.", 2002.
* 3 [List of HTTP status codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection)