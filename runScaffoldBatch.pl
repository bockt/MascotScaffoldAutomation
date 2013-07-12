#!/usr/bin/perl -w
use strict;
use File::Basename;
use File::Spec;
use LWP::Simple;
use Data::Dumper;

##############################################################################
#                                                 
# A perl script to be called by Mascot Daemon External Processes (After Completing Task) 
# to run create a Scaffold XML driver for a list of Mascot .dat and subsequently run Scaffold Batch.
#  Example External Processes After Completeing Task: 
#  perl "C:\MSA\runScaffoldBatch.pl" "<mascot_user_email>" "<taskname>" 
##############################################################################

### INIT
# get script directory
my $scriptDir = dirname(__FILE__);
	### HARD CODED PARMS
# set tmp directory path
my $tmpDir =  File::Spec->catfile( $scriptDir, "tmp");
# set log file path 
my $LOGFILE = File::Spec->catfile( $scriptDir, "log","log.txt" );

require( File::Spec->catfile( $scriptDir, "SimpleLogger.pm"));
require( File::Spec->catfile( $scriptDir, "ScaffoldBatchFunctions.pm"));
### INIT END

### READ CMD LINE ARGUMENTS
my $taskName;
# job complete notification e-mail adr 
my $notficationEmailAdr;
if(scalar(@ARGV) >= 2){
	$notficationEmailAdr = shift @ARGV;
	$taskName = join "_", @ARGV; ### replace spaces with _
	$taskName =~ s/ /_/g; ### replace spaces with _ (windows 7 bug?)
}else{
	### log error
	&SimpleLogger::log($LOGFILE,2,"Task name not specified. @ARGV",File::Spec->abs2rel($0));
	die("Task name not specified. @ARGV")
}
my $datListFile = File::Spec->catfile($tmpDir,$taskName.".txt" ) ;
### READ CMD LINE ARGUMENTS END

### STEP READ MASCOT .DAT FILE QUEUE
print "READ MASCOT .DAT FILE QUEUE\n";
my $datFilesURL_href = &ScaffoldBatchFunctions::readDatFileList($datListFile, $LOGFILE);
### READ MASCOT .DAT FILE QUEUE END

### DOWLOAD .DAT FILES
print "DOWLOAD .DAT FILES\n";
my %datFiles;
foreach my $datFileURL (keys %$datFilesURL_href){
	&SimpleLogger::log($LOGFILE,0,"DOWNLOADING FILE $datFileURL",$taskName); ### log
	print "\t DOWNLOADING FILE $datFileURL\n";
	$datFiles{&ScaffoldBatchFunctions::downloadDATFile($datFileURL,$tmpDir,$taskName, $LOGFILE)} = $datFilesURL_href->{$datFileURL};
	&SimpleLogger::log($LOGFILE,0,"Downloaded .dat file ",$taskName); ### log
}
### DOWLOAD .DAT FILES END

### GET FASTA FILE PATH FROM .DAT FILE
my $fastaMSFilePath = &ScaffoldBatchFunctions::getFastaFilePath((keys(%datFiles))[0],$taskName,$LOGFILE);
&SimpleLogger::log($LOGFILE,0,"Extracted fasta file path (on mascot server) $fastaMSFilePath",$taskName); ### log
print "EXTRACTED FASTA FILE PATH ON MASCOT SERVER\n";
### GET FASTA FILE PATH FROM .DAT FILE END

### DOWNLOAD FASTA FILE
my $downloadFastaFilePath = File::Spec->catfile($tmpDir,basename($fastaMSFilePath)) ;
&ScaffoldBatchFunctions::downloadFastaFile($fastaMSFilePath,$downloadFastaFilePath,$taskName,$LOGFILE);
&SimpleLogger::log($LOGFILE,0,"DOWNLOADED .FASTA FILE $downloadFastaFilePath",$taskName); ### log
print "DOWNLOADED FASTA FILE $downloadFastaFilePath\n";
### DOWNLOAD FASTA FILE END

### CREATE SCAFFOLD .XML DRIVER
my $scaffoldDriverFilePath = File::Spec->catfile($tmpDir,$taskName."_driver.xml");
&ScaffoldBatchFunctions::createXMLScaffoldDriver($scaffoldDriverFilePath, $downloadFastaFilePath, \%datFiles,$tmpDir, $taskName,$LOGFILE);
&SimpleLogger::log($LOGFILE,0,"Created Scaffold XML driver $scaffoldDriverFilePath",$taskName); ### log
print "CREATED SCAFFOLD XML DRIVER $scaffoldDriverFilePath\n"; 
### CREATE SCAFFOLD .XML DRIVER END


### RUN SCAFFOLD BATCH
&SimpleLogger::log($LOGFILE,0,"RUNNING SCAFFOLD BATCH",$taskName); ### log
print "RUNNING SCAFFOLD BATCH\n";
my $scaffoldBatchPath = "\"C:\\Program Files\\Scaffold4\\ScaffoldBatch4.exe\"";
my $scaffoldProgressLogFile =  File::Spec->catfile( $scriptDir, "log","scaffoldProgressLog.txt");
my $scaffoldErrorLogFile =  File::Spec->catfile( $scriptDir, "log","scaffoldErrorLog.txt");
&ScaffoldBatchFunctions::runScaffold($scaffoldBatchPath,$scaffoldDriverFilePath,$scaffoldProgressLogFile,$scaffoldErrorLogFile,$taskName,$LOGFILE);
### RUN SCAFFOLD BATCH END

### SEND E-MAIL NOTIFICATION
unless($notficationEmailAdr  =~ /rainer/i){ ### Rainer doesn't use Mascot Daemon!. 

	my $msg = &ScaffoldBatchFunctions::getEmailNotificationMsg($taskName,$tmpDir, $datFilesURL_href);

	&ScaffoldBatchFunctions::sendEmailNotification($notficationEmailAdr,'erik.ahrne@unibas.ch',	'Scaffold Batch Task Completed',$msg,$taskName,$LOGFILE) ;
	&SimpleLogger::log($LOGFILE,0,"SENT E-MAIL NOTIFICATION to $notficationEmailAdr",$taskName); ### log
	print "SENT E-MAIL NOTIFICATION\n";
}
### SEND E-MAIL NOTIFICATION END

### DONE
&SimpleLogger::log($LOGFILE,0,"DONE!",$taskName); ### log
print "DONE!\n";

exit(0);