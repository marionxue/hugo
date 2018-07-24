#!/bin/bash

sh publish_hugo.sh
rm -rf public/about/
hugo-algolia -s
docker restart hugo
git add --all *
git commit -m "first commit"
git push -u origin master
