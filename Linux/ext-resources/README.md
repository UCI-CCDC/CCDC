# ext-resources

This directory is used for relevant external scripts that are pulled from and used. They're kept here in case of a proxy like the one we had at nationals, which made it impossible to reach any outside resources. 

Any fully packaged versions & binaries of software should be kept here as well, and this README should be updated when new additions are made. 


* `shelldetect.db`, `shelldetect.py`
    * [Shell-Detector](https://github.com/emposha/Shell-Detector)
    * python script that helps to find and identify php/perl/asp webshells. Uses python 2.x. 
    * usage: `python shelldetect.py -r F -d /var/www/html/`
