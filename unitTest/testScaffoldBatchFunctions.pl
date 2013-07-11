#!/usr/bin/perl -w
use strict;
use File::Basename;
use File::Spec;
use LWP::Simple;
use Data::Dumper;
use File::Find;

require("../ScaffoldBatchFunctions.pm");
require("../SimpleLogger.pm");


### INIT
# get script directory
my $SCRIPTDIR = dirname(__FILE__);
	### HARD CODED PARMS
# set tmp directory path
my $TMPDIR =  File::Spec->catfile( $SCRIPTDIR,"tmp");
# set log file path 
my $LOGFILE = File::Spec->catfile( $SCRIPTDIR, "log","log.txt" );

my $DATLISTFILE =  File::Spec->catfile( "testData","test_Task.txt" );
my $TASKNAME = "test_Task";
my $DATFILE = File::Spec->catfile( "testData","F015100.dat" );

my %DATFILEPATHS;
$DATFILEPATHS{"c:\\dev\\perl\\workspace\\MascotScaffoldAutomation\\unitTest\\testData\\F015100.dat"} = "c:\\fileA.mgf";
$DATFILEPATHS{"c:\\dev\\perl\\workspace\\MascotScaffoldAutomation\\unitTest\\testData\\F015101.dat"} = "/usr/fileB.mgf";

### clear tmp dir
my @files;
find sub{push(@files,$File::Find::name) if($File::Find::name =~/\.*/i) }, $TMPDIR;
shift @files;
foreach (@files){unlink $_;}

### INIT END

### run tests
#&testReadDatFileList();
#&testDownloadDATFile();
#&testGetFastaFilePath();
&testDownloadFastaFile();
#&testCreateXMLScaffoldDriver();
#&testRunScaffold();
#&testSendEmailNotification();

###### UNIT TESTS
sub testReadDatFileList(){
	my $ret = &ScaffoldBatchFunctions::readDatFileList($DATLISTFILE, $LOGFILE);
	print Dumper $ret;
	print STDERR "testReadDatFileList: FAIL \n" unless(scalar keys %$ret == 2 );
	print "testReadDatFileList PASS \n";
}

sub  testDownloadDATFile (){
	my $datFileURL = 'http://mascot.biozentrum.unibas.ch/mascot/cgi/master_results.pl?file=../data/20130625/F015100.dat';
	print "\ttestDownloadDATFile: ".&ScaffoldBatchFunctions::downloadDATFile($datFileURL,$TMPDIR,$TASKNAME, $LOGFILE)."\n";
	print STDERR "testDownloadDATFile: FAIL " unless(-e File::Spec->catfile( "tmp","F015100.dat" ));  
	print "testDownloadDATFile PASS \n";
}


sub testGetFastaFilePath(){
	my $ret = &ScaffoldBatchFunctions::getFastaFilePath($DATFILE,$TASKNAME,$LOGFILE);
	print "\ttestGetFastaFilePath: $ret\n";
	print STDERR "testGetFastaFilePath: FAIL \n" unless($ret =~ /uniprot_sprot_v57.12.MOUSE.plus_NRX1-3d_AS6_corr.decoy.fasta/);
	print "testGetFastaFilePath PASS \n";
}

sub testDownloadFastaFile(){
	my $downloadFastaFilePath = File::Spec->catfile($TMPDIR,$TASKNAME.".fasta" ) ;
	my $fastaMSFilePath =  "SP_MOUSE_NRX/current/uniprot_sprot_v57.12.MOUSE.plus_NRX1-3d_AS6_corr.decoy.fasta";
	my $ret = &ScaffoldBatchFunctions::downloadFastaFile($fastaMSFilePath,$downloadFastaFilePath,$TASKNAME,$LOGFILE);
	print STDERR "testDownloadFastaFile: FAIL \n" unless(-e $downloadFastaFilePath);
	print "testDownloadFastaFile PASS \n";
}

sub testCreateXMLScaffoldDriver(){
	my $scaffoldDriverFilePath = File::Spec->catfile($TMPDIR,"driver.xml");
	my $fastaFilePath = "c:\\dev\\perl\\workspace\\MascotScaffoldAutomation\\unitTest\\testData\\test_Task.fasta";	

	&ScaffoldBatchFunctions::createXMLScaffoldDriver($scaffoldDriverFilePath, $fastaFilePath, \%DATFILEPATHS,$TMPDIR, $TASKNAME,$LOGFILE);
	print STDERR "testCreateXMLScaffoldDriver: FAIL \n" unless(-e $scaffoldDriverFilePath);
	print "testCreateXMLScaffoldDriver PASS \n";
}

sub testRunScaffold(){
	
	my $sscaffoldBatchPath = "\"C:\\Program Files\\Scaffold4\\ScaffoldBatch4.exe\"";
	my $scaffoldDriverFilePath = File::Spec->catfile( $TMPDIR,"driver.xml");
	my $scaffoldProgressLogFile =  File::Spec->catfile( $SCRIPTDIR, "log","scaffoldProgressLog.txt");
	my $scaffoldErrorLogFile =  File::Spec->catfile( $SCRIPTDIR, "log","scaffoldErrorLog.txt");


	&ScaffoldBatchFunctions::runScaffold($sscaffoldBatchPath,$scaffoldDriverFilePath,$scaffoldProgressLogFile,$scaffoldErrorLogFile,$TASKNAME,$LOGFILE);
	
	print STDERR "testRunScaffold: FAIL \n" unless(-e File::Spec->catfile( $TMPDIR,"test_Task.sfd"));
	print STDERR "testRunScaffold: FAIL \n" unless(-e File::Spec->catfile( $TMPDIR,"test_Task.prot.xml"));

	print "testRunScaffold PASS \n";		
}


sub testSendEmailNotification(){
	
	my $resultsPath = "where/are/my/results";
	my $msg = &ScaffoldBatchFunctions::getEmailNotificationMsg($TASKNAME,$resultsPath,\%DATFILEPATHS
	 );

	print "testSendEmailNotification $msg\n";
	my $notficatioEmailAdr = 'erik.ahrne@unibas.ch';
	my $ret = &ScaffoldBatchFunctions::sendEmailNotification($notficatioEmailAdr,'erik.ahrne@unibas.ch',	'Scaffold Batch Task Completed',$msg,$TASKNAME,$LOGFILE);
	print STDERR "testSendEmailNotification: FAIL \n" unless($ret);	
	print "testSendEmailNotification PASS \n";

}









	

exit(0);


