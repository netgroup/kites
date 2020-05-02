#!/bin/bash
shopt -s extglob
GLOBIGNORE='*.gitignore'
if [ -d "/vagrant/ext/kites/pod-shared/" ] 
then
	cd /vagrant/ext/kites/pod-shared
	rm -rf *
else
    : 																																	
fi
