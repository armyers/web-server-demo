# web-server-demo
Create the AWS infrastructure to implement a very simple web server that when queried
returns the server IP, client IP and a precise timestamp (second resolution).

It uses terraform 0.13 (web-server-demo/tf-code) to create the following infrastructure:

* VPC
* public and private subnets
* external ALB, listener and listener rules (service port 80)
* target group
* ASG with launch config
* security groups for the external LB and the internal web server
* ssh bastion server with a EIP

The web server code (web-server-demo/web-server) is written in Python 3 and is a
_very_ simple threaded http server. When queried with a GET request (any path will do),
it returns:

* requested path
* server IP and port
* Host header value
* client IP and port
* X-forwarded-for header
* X-forwarded-proto header
