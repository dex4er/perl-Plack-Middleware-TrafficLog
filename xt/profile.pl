#!/usr/bin/perl -d:NYTProf

use lib 'lib', '../lib';

use DEXTER::Module::Skeleton;

DEXTER::Module::Skeleton->hello;

print "nytprof.out data collected. Call nytprofhtml --open\n";
