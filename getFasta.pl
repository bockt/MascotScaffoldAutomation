##!/usr/bin/perl 
#use strict;
#
#### WRITTEN BY erik.ahrne@unibas.ch
#
#use CGI;
#
#### To be uploaded to cgi golder on the mascot server
#### Example:  wget http://mascot.biozentrum.unibas.ch/mascot/cgi/getFasta.pl?fasta=/SP_MOUSE_NRX/current/uniprot_sprot_v57.12.MOUSE.plus_NRX1-3d_AS6_corr.decoy.fasta 
#
#my $query = new CGI;
#my $path = "/export01/var/mascot/sequence/".$query->param('fasta');
#
#print "Content-type: text/html\n\n";
#if($path =~ /fasta$/){
#        open(DLFILE, "<$path") || Error ('open', 'file') ;   
#        my @fileholder = <DLFILE>;   
#        close (DLFILE) || Error ('close', 'file');   
#        print @fileholder;
#}else{
#        print "Invalid fasta file ".$query->param('fasta')."\n"; 
#}  
#
#exit(0);
#
#
#
#
#
#
