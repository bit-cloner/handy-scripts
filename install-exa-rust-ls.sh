#!/bin/bash
wget https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip
unzip  exa-linux-x86_64-0.9.0.zip
mv exa-linux-x86_64 exa
sudo mv exa /usr/local/bin/
exa
alias rls="exa"

