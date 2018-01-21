#!/usr/bin/perl

use utf8;       #Necessario per far capire a Perl come trattare le lettere accentate nelle costanti
use JSON;# qw( decode_json );
use warnings;
use strict;
use Switch;

require "./FamoErPartito_algo.pl";

#print generaSostantivoCongSost(); print"\n";
#print generaAggettivoCongAggettivo();print "\n";
for (my $i=0; $i<10; $i++){
    print generaSostAgg(); print "\n";
    print generaVerboArtSostAgg(); print "\n";
    print generaVerboPrepArtSostAgg(); print "\n";
    print generaVerboAvverbo(); print "\n";
    print generaSostantivoCongSost(); print "\n";
    print generaSostantivoCongSost(); print "\n";
    print generaAggettivoCongAggettivo(); print "\n";
    print "---------------------------------------\n";
}
