#!/bin/bash

sh publish_hugo.sh
hugo-algolia -s
docker restart hugo
git add --all *
git commit -m "first commit"
git push -u origin master
