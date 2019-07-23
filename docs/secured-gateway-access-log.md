## End to end OAuth 2 JOSE/JWT Interaction

These logging highlights illustrate what's happening during the OAuth2 flow when  JOSE/JWT.

First, a request is sent to `http://localhost:8080/resource and this is intercepted by the API gateway. The gateway expects all requestes to be authenticated, so it immediately gets to work:

```bash
gateway            | 2019-07-23 11:11:13.831 DEBUG 1 --- [or-http-epoll-2] .s.u.m.MediaTypeServerWebExchangeMatcher : httpRequestMediaTypes=[text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8]
gateway            | 2019-07-23 11:11:13.832 DEBUG 1 --- [or-http-epoll-2] .s.u.m.MediaTypeServerWebExchangeMatcher : Processing text/html
gateway            | 2019-07-23 11:11:13.832 DEBUG 1 --- [or-http-epoll-2] .s.u.m.MediaTypeServerWebExchangeMatcher : text/html .isCompatibleWith text/html = true
uaa                | [2019-07-23 11:11:13.991] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-1] .... DEBUG --- UaaMetricsFilter: Successfully matched URI: /uaa/oauth/authorize to a group: /ui
```

The gateway asks the authentication provider to authenticate the user via the `authentication-uri` of `http://localhost:8090/uaa/oauth/authorize`. The UAA then steps in and presents the user with an authentication challenge.

```bash
...
uaa                | [2019-07-23 11:11:21.350] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-8] .... DEBUG --- ChainedAuthenticationManager: Attempting chained authentication of org.springframework.security.authentication.UsernamePasswordAuthenticationToken@3ce6bcf6: Principal: user1; Credentials: [PROTECTED]; Authenticated: false; Details: remoteAddress=172.23.0.1, sessionId=<SESSION>; Not granted any authorities with manager:org.cloudfoundry.identity.uaa.authentication.manager.CheckIdpEnabledAuthenticationManager@3c5169cf required:null
uaa                | [2019-07-23 11:11:21.360] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-8] .... DEBUG --- AuthzAuthenticationManager: Processing authentication request for user1
uaa                | [2019-07-23 11:11:21.476] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-8] .... DEBUG --- AuthzAuthenticationManager: Password successfully matched for userId[user1]:61b7c1c4-a0c0-44f7-a709-a8638068d137
uaa                | [2019-07-23 11:11:21.488] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-8] ....  INFO --- Audit: IdentityProviderAuthenticationSuccess ('user1'): principal=61b7c1c4-a0c0-44f7-a709-a8638068d137, origin=[remoteAddress=172.23.0.1, sessionId=<SESSION>], identityZoneId=[uaa], authenticationType=[uaa]
uaa                | [2019-07-23 11:11:21.490] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-8] ....  INFO --- Audit: UserAuthenticationSuccess ('user1'): principal=61b7c1c4-a0c0-44f7-a709-a8638068d137, origin=[remoteAddress=172.23.0.1, sessionId=<SESSION>], identityZoneId=[uaa]
```

The UAA has confirmed the users identity has been as `user1` and their principal id has been assigned as `1b7c1c4-a0c0-44f7-a709-a8638068d137`. The UAA will now ask the user to 'Authorise' the `login-client` application (the gateway).

```bash
uaa                | [2019-07-23 11:11:25.044] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-4] .... DEBUG --- UaaMetricsFilter: Successfully matched URI: /uaa/oauth/authorize to a group: /ui
uaa                | [2019-07-23 11:11:25.058] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-4] .... DEBUG --- SessionResetFilter: Evaluating user-id for session reset:61b7c1c4-a0c0-44f7-a709-a8638068d137
uaa                | [2019-07-23 11:11:25.062] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-4] .... DEBUG --- UserManagedAuthzApprovalHandler: Looking up user approved authorizations for client_id=login-client and username=user1
uaa                | [2019-07-23 11:11:25.069] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-4] .... DEBUG --- JdbcApprovalStore: adding approval: [[61b7c1c4-a0c0-44f7-a709-a8638068d137, resource.read, login-client, Fri Aug 23 11:11:25 GMT 2019, APPROVED, Tue Jul 23 11:11:25 GMT 2019]]
uaa                | [2019-07-23 11:11:25.650] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-5] ....  INFO --- Audit: TokenIssuedEvent ('["resource.read","openid","email"]'): principal=61b7c1c4-a0c0-44f7-a709-a8638068d137, origin=[caller=login-client, details=(remoteAddress=172.23.0.4, clientId=login-client)], identityZoneId=[uaa]
```

The gateway application `login-client` has now been granted access to the users profile, which includes the scope `resource.read`

```bash
gateway            | 2019-07-23 11:11:25.757 DEBUG 1 --- [or-http-epoll-2] org.springframework.web.HttpLogging      : [26d3ff07] Decoded [{access_token=eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vbG9jYWxob3N0OjgwODAvdWFhL3Rva2VuX2tleXMiLCJraW (truncated)...]
```

The gateway has now been issued with a JWT `access_token` (part redacted in the log for security).

```bash
uaa                | [2019-07-23 11:11:25.854] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-6] .... DEBUG --- SecurityFilterChainPostProcessor$HttpsEnforcementFilter: Filter chain 'tokenKeySecurity' processing request GET /uaa/token_keys
gateway            | 2019-07-23 11:11:25.909 DEBUG 1 --- [or-http-epoll-2] org.springframework.web.HttpLogging      : [434f3904] Decoded "{"keys":[{"kty":"RSA","e":"AQAB","use":"sig","kid":"key-id-1","alg":"RS256","value":"-----BEGIN PUB (truncated)...
```

The gateway is checking the validity of the JWT token using the keys provided by the UAA using the endpoint set in the `jwk-set-uri` which is `http://uaa:8090/uaa/token_keys`.

```bash
gateway            | 2019-07-23 11:11:26.030 DEBUG 1 --- [or-http-epoll-2] org.springframework.web.HttpLogging      : [3c76d40a] Decoded [{user_id=61b7c1c4-a0c0-44f7-a709-a8638068d137, user_name=user1, name=first1 last1, given_name=first1 (truncated)...]
gateway            | 2019-07-23 11:11:26.078 DEBUG 1 --- [or-http-epoll-2] o.s.c.g.h.RoutePredicateHandlerMapping   : Route matched: resource
gateway            | 2019-07-23 11:11:26.079 DEBUG 1 --- [or-http-epoll-2] o.s.c.g.h.RoutePredicateHandlerMapping   : Mapping [Exchange: GET http://localhost:8080/resource] to Route{id='resource', uri=http://resource:9000, order=0, predicate=org.springframework.cloud.gateway.support.ServerWebExchangeUtils$$Lambda$334/1074263646@2fb64b12, gatewayFilters=[OrderedGatewayFilter{delegate=org.springframework.cloud.security.oauth2.gateway.TokenRelayGatewayFilterFactory$$Lambda$336/1107412069@42187950, order=0}, OrderedGatewayFilter{delegate=org.springframework.cloud.gateway.filter.factory.RemoveRequestHeaderGatewayFilterFactory$$Lambda$339/1139814130@210d549e, order=0}]}
```

The JWT token checked out, so the gateway starts forwarding the request to the resource server's `/resource` endpoint. The resource server then contacts the UAA...

```bash
uaa                | [2019-07-23 11:11:26.513] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-8] .... DEBUG --- UaaMetricsFilter: Successfully matched URI: /uaa/token_keys to a group: /oauth-oidc
uaa                | [2019-07-23 11:11:26.516] cloudfoundry-identity-server/uaa - ???? [http-nio-8090-exec-8] .... DEBUG --- SecurityFilterChainPostProcessor$HttpsEnforcementFilter: Filter chain 'tokenKeySecurity' processing request GET /uaa/token_keys
resource           | 2019-07-23 11:11:26.564 DEBUG 1 --- [or-http-epoll-2] org.springframework.web.HttpLogging      : [472e353f] Decoded "{"keys":[{"kty":"RSA","e":"AQAB","use":"sig","kid":"key-id-1","alg":"RS256","value":"-----BEGIN PUB (truncated)...
```

The resource server is also checking the validity of the JWT token against the keys held by the UAA. The keys check out, so the resource server decodes the JWT `access_token` and allows the user to access the `/resource` endpoint...

```bash
resource           | 2019-07-23 11:11:26.669 TRACE 1 --- [or-http-epoll-2] c.scg.service.SecuredServiceApplication  : ***** JWT Headers: {jku=https://localhost:8080/uaa/token_keys, kid=key-id-1, typ=JWT, alg=RS256}
resource           | 2019-07-23 11:11:26.678 TRACE 1 --- [or-http-epoll-2] c.scg.service.SecuredServiceApplication  : ***** JWT Claims: {sub=61b7c1c4-a0c0-44f7-a709-a8638068d137, user_name=user1, origin=uaa, iss=http://uaa:8090/uaa/oauth/token, client_id=login-client, aud=[resource, openid, login-client], zid=uaa, grant_type=authorization_code, user_id=61b7c1c4-a0c0-44f7-a709-a8638068d137, azp=login-client, scope=["resource.read","openid","email"], auth_time=1563880281, exp=Tue Jul 23 23:11:25 GMT 2019, iat=Tue Jul 23 11:11:25 GMT 2019, jti=fa9c60e2e89b48a584169f839f32e282, email=user1@provider.com, rev_sig=b3f4e1e1, cid=login-client}
resource           | 2019-07-23 11:11:26.678 TRACE 1 --- [or-http-epoll-2] c.scg.service.SecuredServiceApplication  : ***** JWT Token: eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vbG9jYWxob3N0OjgwODAvdWFhL3Rva2VuX2tleXMiLCJraWQiOiJrZXktaWQtMSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJmYTljNjBlMmU4OWI0OGE1ODQxNjlmODM5ZjMyZTI4MiIsInN1YiI6IjYxYjdjMWM0LWEwYzAtNDRmNy1hNzA5LWE4NjM4MDY4ZDEzNyIsInNjb3BlIjpbInJlc291cmNlLnJlYWQiLCJvcGVuaWQiLCJlbWFpbCJdLCJjbGllbnRfaWQiOiJsb2dpbi1jbGllbnQiLCJjaWQiOiJsb2dpbi1jbGllbnQiLCJhenAiOiJsb2dpbi1jbGllbnQiLCJncmFudF90eXBlIjoiYXV0aG9yaXphdGlvbl9jb2RlIiwidXNlcl9pZCI6IjYxYjdjMWM0LWEwYzAtNDRmNy1hNzA5LWE4NjM4MDY4ZDEzNyIsIm9yaWdpbiI6InVhYSIsInVzZXJfbmFtZSI6InVzZXIxIiwiZW1haWwiOiJ1c2VyMUBwcm92aWRlci5jb20iLCJhdXRoX3RpbWUiOjE1NjM4ODAyODEsInJldl9zaWciOiJiM2Y0ZTFlMSIsImlhdCI6MTU2Mzg4MDI4NSwiZXhwIjoxNTYzOTIzNDg1LCJpc3MiOiJodHRwOi8vdWFhOjgwOTAvdWFhL29hdXRoL3Rva2VuIiwiemlkIjoidWFhIiwiYXVkIjpbInJlc291cmNlIiwib3BlbmlkIiwibG9naW4tY2xpZW50Il19.l9SC-3dvUWbqH-teAUpSDfn0V9EeRmaLioj5N6oYZSpKUBIFh7QR9Dd4e2wbG6itpI3ulA30629Tw8aIHo_72Owetc7v4dBmg-IL_c1Nycc5JYXguMMZmKT4oIW2lAfNxWl9Z821HyNk4SsRiIPpcWXiziAO8n4h3anjr7NQESYRFole0gDT19IOX1TIB03ZSbgjmRq3-UclpX-qRYW_XJ-CeVbcjRI_C1XEDuqLVflushpsQvBt6snb1Oq1c6zmvXkXag9QXA0iBusJnIt66zua2-dnGv334VPTo6SaIoGBSp4ReRDCFLKNk2tAF-Kqpc_S8KehmgY0jMYN7QLYNw
resource           | 2019-07-23 11:11:26.684 DEBUG 1 --- [or-http-epoll-2] org.springframework.web.HttpLogging      : [5becb7ae] Writing "Resource accessed by: user1 (with subjectId: 61b7c1c4-a0c0-44f7-a709-a8638068d137)"
```

 Information in the JWT is used to show who read the resource - "Resource accessed by: user1 (with subjectId: 61b7c1c4-a0c0-44f7-a709-a8638068d137)".