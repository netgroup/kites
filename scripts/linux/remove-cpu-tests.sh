#!/bin/bash
shopt -s extglob
GLOBIGNORE='*.gitignore'
if [ -d "/vagrant/ext/kites/cpu/" ]; then
	cd /vagrant/ext/kites/cpu
	rm -rf *
	echo "cpu cleaned"
else
	:
fi
if [ -d "/vagrant/ext/kites/tests/" ]; then
	cd /vagrant/ext/kites/tests
	rm -rf *
	echo "tests cleaned"
else
	:
fi
