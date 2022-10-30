#!/bin/bash

# open user directory
cd ~
# download brotli
git clone https://github.com/google/ngx_brotli --recursive
# move brotli to src directory
sudo mv ngx_brotli /usr/local/src
# store brotli configuration
brotli="--add-dynamic-module=/usr/local/src/ngx_brotli"
