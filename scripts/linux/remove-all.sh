if [ -d "/vagrant/ext/kites/pod-shared/" ] 
then
	cd /vagrant/ext/kites/pod-shared
	shopt -s extglob 
	rm -rf !(".gitignore")    
else
    : 
fi
