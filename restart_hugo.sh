#!/bin/bash

sh publish_hugo.sh
hugo-algolia -s
docker restart hugo
