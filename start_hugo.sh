#!/bin/bash

docker run -d -v /home/hugo/public:/usr/share/nginx/html --net yang --name hugo --restart always nginx:alpine
