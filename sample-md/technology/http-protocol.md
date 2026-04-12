# HTTP: Hypertext Transfer Protocol

HTTP (Hypertext Transfer Protocol) is the foundation of data communication on the World Wide Web. Developed by **Tim Berners-Lee** and his team at CERN beginning in 1989, HTTP defines how messages are formatted and transmitted between web clients and servers.

## How HTTP Works

HTTP operates as a **request-response** protocol in a client-server model. The basic flow is:

1. A client (typically a web browser) opens a connection to a server
2. The client sends an **HTTP request** message
3. The server processes the request
4. The server returns an **HTTP response** containing a status code and (optionally) the requested resource
5. The connection is closed or kept alive for reuse

HTTP is **stateless** -- servers do not retain information about clients between requests. Session state is maintained through mechanisms like cookies, URL parameters, or server-side storage.

## Protocol Versions

### HTTP/0.9 (1991)

The original version was extremely simple:

- Supported only the `GET` method
- Returned only HTML documents
- No headers, no status codes

```http
GET /index.html
```

### HTTP/1.0 (1996)

Formalized in **RFC 1945**, this version added:

- `HEAD` and `POST` methods
- HTTP headers for metadata
- Status codes in responses
- Content-type negotiation

Each request required a **separate TCP connection**.

### HTTP/1.1 (1997)

The workhorse of the web for nearly two decades. Key improvements:

- **Persistent connections** -- Multiple requests over a single TCP connection
- **Pipelining** -- Sending requests without waiting for responses
- **Chunked transfer encoding** -- Streaming responses of unknown length
- Five new methods: `PUT`, `DELETE`, `CONNECT`, `OPTIONS`, `TRACE`
- The `Host` header, enabling virtual hosting

### HTTP/2 (2015)

A major performance upgrade based on Google's SPDY protocol:

- **Binary framing** instead of text-based messages
- **Multiplexing** -- Multiple concurrent requests on one connection
- **Header compression** (HPACK)
- **Server push** -- Proactively sending resources the client will need
- Supported by **71%** of websites

### HTTP/3 (2022)

The latest version replaces TCP with **QUIC** over UDP:

- Eliminates head-of-line blocking
- Faster connection establishment (0-RTT)
- Built-in encryption (TLS 1.3)
- Better performance on unreliable networks
- Adopted by **36.9%** of websites

## Request Methods

| Method | Purpose | Safe | Idempotent | Cacheable |
|--------|---------|------|------------|-----------|
| `GET` | Retrieve a resource | Yes | Yes | Yes |
| `HEAD` | Like GET, but no body | Yes | Yes | Yes |
| `POST` | Submit data for processing | No | No | Conditional |
| `PUT` | Create or replace a resource | No | Yes | No |
| `PATCH` | Partially modify a resource | No | No | No |
| `DELETE` | Remove a resource | No | Yes | No |
| `OPTIONS` | Describe communication options | Yes | Yes | No |
| `TRACE` | Loop-back test | Yes | Yes | No |
| `CONNECT` | Establish a tunnel | No | No | No |

- **Safe** methods do not modify server state
- **Idempotent** methods produce the same result when called multiple times

## Request and Response Examples

### A Simple GET Request

```http
GET /api/users/42 HTTP/1.1
Host: example.com
Accept: application/json
User-Agent: Mozilla/5.0
Accept-Language: en-US,en;q=0.9
```

### Response

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 85
Cache-Control: max-age=3600
Date: Sun, 13 Apr 2026 12:00:00 GMT

{
  "id": 42,
  "name": "Ada Lovelace",
  "email": "ada@example.com"
}
```

### A POST Request

```http
POST /api/users HTTP/1.1
Host: example.com
Content-Type: application/json
Content-Length: 64
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

{
  "name": "Grace Hopper",
  "email": "grace@example.com"
}
```

### Response

```http
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/users/43

{
  "id": 43,
  "name": "Grace Hopper",
  "email": "grace@example.com"
}
```

## Status Codes

HTTP responses include a three-digit status code organized into five categories:

### 1xx -- Informational

- `100 Continue` -- Server received headers, client should send body
- `101 Switching Protocols` -- Server is switching to a different protocol

### 2xx -- Success

- `200 OK` -- Standard successful response
- `201 Created` -- Resource successfully created
- `204 No Content` -- Success with no response body

### 3xx -- Redirection

- `301 Moved Permanently` -- Resource has a new permanent URL
- `302 Found` -- Temporary redirect
- `304 Not Modified` -- Cached version is still valid

### 4xx -- Client Error

- `400 Bad Request` -- Malformed request syntax
- `401 Unauthorized` -- Authentication required
- `403 Forbidden` -- Server refuses to authorize the request
- `404 Not Found` -- Resource does not exist
- `429 Too Many Requests` -- Rate limit exceeded

### 5xx -- Server Error

- `500 Internal Server Error` -- Generic server failure
- `502 Bad Gateway` -- Invalid response from upstream server
- `503 Service Unavailable` -- Server temporarily overloaded or in maintenance

## Important Headers

### Request Headers

- **Host** -- Domain name of the server (required in HTTP/1.1)
- **Accept** -- Media types the client can handle
- **Authorization** -- Credentials for authentication
- **User-Agent** -- Client software identification
- **Cookie** -- Previously stored cookies

### Response Headers

- **Content-Type** -- Media type of the response body
- **Content-Length** -- Size of the response body in bytes
- **Set-Cookie** -- Store a cookie on the client
- **Cache-Control** -- Caching directives
- **Location** -- URL for redirects or newly created resources

## HTTPS

> The most popular way of establishing an encrypted HTTP connection is HTTPS.

**HTTPS** combines HTTP with **TLS** (Transport Layer Security) encryption. More than **85%** of websites now use HTTPS, which provides:

- **Encryption** -- Data cannot be read in transit
- **Authentication** -- Verifies the server's identity via certificates
- **Integrity** -- Detects tampering with transmitted data

---

*Source: [HTTP -- Wikipedia](https://en.wikipedia.org/wiki/HTTP). Content adapted and reformatted for demonstration purposes.*
