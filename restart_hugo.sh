#!/bin/bash

sh publish_hugo.sh
rm -rf public/about/
hugo-algolia -s
#docker restart hugo
docker-compose restart hugo
docker-compose restart service-envoy
git add --all *
git commit -m "first commit"
git push -u origin master
