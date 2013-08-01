#!/usr/bin/python

import logging, subprocess

logging.basicConfig(filename="logs/update.log", level=logging.INFO)
out = open("logs/update.out", 'a')

logging.info("Received update request")

subprocess.call(["/usr/bin/git", "pull"], stdout=out, stderr=subprocess.STDOUT)

print "Content-type: text/plain"
print
print "Thanks!"
