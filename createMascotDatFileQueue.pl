#!/usr/bin/perl -w
use strict;
use File::Basename;
use File::Spec;

##############################################################################
#                                                 
# A perl script to be called by Mascot Daemon External Processes (after search) 
# to create a list of .dat files for a Task.
#  Example External Processes after Serarch: perl "C:\MSA\createMascotDatFileQueue.pl" "<resulturl>" "<datafilepath>" "<taskname>"
##############################################################################

### get script directory
my $scriptDir = dirname(__FILE__);

require( File::Spec->catfile( $scriptDir, "SimpleLogger.pm"));

### HARD CODED PARMS
my $LOGFILE = File::Spec->catfile( $scriptDir, "log","log.txt" );
### PARAMS END

### READ CMD LINE ARGUMENTS
my $resultURL;
my $taskName;
my $dataFilePath;

if(scalar(@ARGV) >= 3){
	$resultURL = shift @ARGV;
	$dataFilePath = shift @ARGV;
	$taskName = join "_", @ARGV; ### replace spaces with _
	$taskName =~ s/ /_/g; ### replace spaces with _ (windows 7 bug?)
}else{
	### log error
	&SimpleLogger::log($LOGFILE,2,"Task name not specified. @ARGV",File::Spec->abs2rel($0));
	die("Task name not specified. @ARGV")
}

my $datListFile = File::Spec->catfile( $scriptDir, "tmp",$taskName.".txt" );

### READ CMD LINE ARGUMENTS END

### add dat file to list
open (OUT, ">>$datListFile") || Error('open', 'file');  
print OUT "$resultURL\t$dataFilePath\n";  
close (OUT);

### LOG SUCCESS 
print "CREATED/UPDATED $datListFile\n";
&SimpleLogger::log($LOGFILE,0,"CREATED/UPDATED $datListFile","$taskName");

exit(0);