# nginx-f1

Container image for nginx f1 project

Basic nginx setup for handling requests and generate statistics


Important modules:
 * nginx_upstream_check_module (https://github.com/yaoweibin/nginx_upstream_check_module)
 * nginx-module-stream-sts (https://github.com/vozlt/nginx-module-stream-sts)


# Examples

docker run -p 8181:80 denis256/nginx-f1:0.0.1
