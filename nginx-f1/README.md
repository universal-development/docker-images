# nginx-f1

Container image for nginx f1 project

Basic nginx setup for handling requests and generate statistics


Important modules:
 * nginx_upstream_check_module (https://github.com/yaoweibin/nginx_upstream_check_module)
 * nginx-module-stream-sts (https://github.com/vozlt/nginx-module-stream-sts)


# Examples

docker run -p 8181:80 denis256/nginx-f1:0.0.1


docker run -v $(pwd)/example/nginx.conf:/etc/nginx/nginx.conf -p 0.0.0.0:9090:80 -p 0.0.0.0:9091:81 denis256/nginx-f1:0.0.1

docker run -v $(pwd)/example/html:/usr/share/nginx/html:ro -p 0.0.0.0:8181:80 nginx
docker run -v $(pwd)/example/html:/usr/share/nginx/html:ro -p 0.0.0.0:8182:80 nginx


Upstream status check:

http://0.0.0.0:9090/status

Upstream health check:
http://0.0.0.0:9090/upstream-status

Client access:
http://0.0.0.0:9091
