#!/usr/bin/perl -w
use strict;
use File::Basename;
use File::Spec;
use LWP::Simple;
use Data::Dumper;
use File::Find;
use Config::Simple;

### INIT

# get script directory
my $SCRIPTDIR = dirname(__FILE__);

# get base dir to load required modules
my $BASEDIR = $SCRIPTDIR;
$BASEDIR =~ s/unitTest$//;
require(File::Spec->catfile( $BASEDIR,"ScaffoldBatchFunctions.pm"));
require(File::Spec->catfile( $BASEDIR,"SimpleLogger.pm"));

### read config file
my %config;
Config::Simple->import_from(File::Spec->catfile( $SCRIPTDIR,"etc","msa.ini"), \%config)
    or die Config::Simple->error();

my $OUTPUTDIR = $config{OUTPUTDIR};
my $SCAFFOLDBATCHPATH = $config{SCAFFOLDBATCHPATH};
my $SMTPSERVERNAME = $config{SMTPSERVERNAME};
my $NOTFICATIONEMAILSENDERADR = $config{NOTFICATIONEMAILSENDERADR};
my $MASCOTSERVERURL = $config{MASCOTSERVERURL};
my $MASCOTWEBUSERNAME = $config{MASCOTWEBUSERNAME};
my $MASCOTWEBPASSWORD = $config{MASCOTWEBPASSWORD};
my $NOTFICATIONEMAILADRTEST = $config{NOTFICATIONEMAILADRTEST};

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
&testReadDatFileList();
&testDownloadDATFile();  # server specific test
&testGetFastaFilePath();
&testDownloadFastaFile(); # server specific test
&testCreateXMLScaffoldDriver();
&testRunScaffold(); # scaffold batch installation specific
&testSendEmailNotification();
&testCopyResultsFile(); 

###### UNIT TESTS
sub testReadDatFileList(){
	
	print " --- testReadDatFileList \n";
	my $ret = &ScaffoldBatchFunctions::readDatFileList($DATLISTFILE, $LOGFILE);
	print Dumper $ret;
	die("testReadDatFileList: FAIL \n") unless(scalar keys %$ret == 2 );
	print "testReadDatFileList PASS \n";
}

sub  testDownloadDATFile (){
	
	print " --- testDownloadDATFile \n";
	my $datFileURL = 'http://mascot.biozentrum.unibas.ch/mascot/cgi/master_results.pl?file=../data/20151109/F028923.dat'; # server specific
	print "\ttestDownloadDATFile: ".&ScaffoldBatchFunctions::downloadDATFile($datFileURL,$TMPDIR,$TASKNAME,$MASCOTWEBUSERNAME,$MASCOTWEBPASSWORD, $LOGFILE)."\n";
	die("testDownloadDATFile: FAIL ") unless(-e File::Spec->catfile( "tmp","F028923.dat" ));
	print "testDownloadDATFile PASS \n";
	
}

sub testGetFastaFilePath(){
	
	print " --- testGetFastaFilePath \n";
	my $ret = &ScaffoldBatchFunctions::getFastaFilePath($DATFILE,$TASKNAME,$LOGFILE);
	print "\ttestGetFastaFilePath: $ret\n";
	die("testGetFastaFilePath: FAIL \n") unless($ret =~ /uniprot_sprot_v57.12.MOUSE.plus_NRX1-3d_AS6_corr.decoy.fasta/);
	print "testGetFastaFilePath PASS \n";
}

sub testDownloadFastaFile(){  # server specific
	
	print " --- testDownloadFastaFile \n";
	my $fastaMSFilePath =  "SP_MOUSE_NRX/current/uniprot_sprot_v57.12.MOUSE.plus_NRX1-3d_AS6_corr.decoy.fasta"; 
	my $downloadFastaFilePath = File::Spec->catfile($TMPDIR,basename($fastaMSFilePath));
	
	die("testDownloadFastaFile: FAIL") unless(&ScaffoldBatchFunctions::downloadFastaFile($fastaMSFilePath,$downloadFastaFilePath,$MASCOTSERVERURL,$TASKNAME,$LOGFILE));
	print "testDownloadFastaFile PASS \n";

}

sub testCreateXMLScaffoldDriver(){
	
	print " --- testCreateXMLScaffoldDriver \n";
	my $scaffoldDriverFilePath = File::Spec->catfile($TMPDIR,"driver.xml");
	my $fastaFilePath = "c:\\dev\\perl\\workspace\\MascotScaffoldAutomation\\unitTest\\testData\\test_Task.fasta";	

	&ScaffoldBatchFunctions::createXMLScaffoldDriver($scaffoldDriverFilePath, $fastaFilePath, \%DATFILEPATHS,$TMPDIR, $TASKNAME,$LOGFILE);
	die"testCreateXMLScaffoldDriver: FAIL \n" unless(-e $scaffoldDriverFilePath);
	print "testCreateXMLScaffoldDriver PASS \n";
}
 
sub testRunScaffold(){ # scaffold batch installation specific
	
	print " --- testRunScaffold \n";
	my $scaffoldDriverFilePath = File::Spec->catfile( $TMPDIR,"driver.xml");
	#my $scaffoldProgressLogFile =  File::Spec->catfile( $SCRIPTDIR, "log","scaffoldProgressLog.txt");
	#my $scaffoldErrorLogFile =  File::Spec->catfile( $SCRIPTDIR, "log","scaffoldErrorLog.txt");

	my $scaffoldProgressLogFile =  File::Spec->catfile( $SCRIPTDIR, "log","scaffoldProgressLog_".time."\.txt");
	my $scaffoldErrorLogFile =  File::Spec->catfile( $SCRIPTDIR, "log","scaffoldErrorLog_".time."\.txt");
	
	&ScaffoldBatchFunctions::runScaffold($SCAFFOLDBATCHPATH,$scaffoldDriverFilePath,$scaffoldProgressLogFile,$scaffoldErrorLogFile,$TASKNAME,$LOGFILE);
	
	die("testRunScaffold: FAIL \n") unless(-e File::Spec->catfile( $TMPDIR,"test_Task.sf3"));
	#print STDERR "testRunScaffold: FAIL \n" unless(-e File::Spec->catfile( $TMPDIR,"test_Task.prot.xml"));

	print "testRunScaffold PASS \n";		
}


sub testSendEmailNotification(){
	
	print " --- testSendEmailNotification \n";
	my $resultsPath = "where/are/my/results";
	my $msg = &ScaffoldBatchFunctions::getEmailNotificationMsg($TASKNAME,$resultsPath,\%DATFILEPATHS
	 );

	print "testSendEmailNotification $msg\n";
	my $ret = &ScaffoldBatchFunctions::sendEmailNotification($NOTFICATIONEMAILADRTEST,$NOTFICATIONEMAILSENDERADR,$SMTPSERVERNAME,'Scaffold Batch Task Completed',$msg,$TASKNAME,$LOGFILE);
	die("testSendEmailNotification FAIL \n" ) unless($ret);

}


sub testCopyResultsFile{
	
	print " --- testCopyResultsFile \n";
	my $toPath = "tmp/";
	my $fromPath = "testData/";
	
	&ScaffoldBatchFunctions::copyResultsFile($toPath,"$fromPath","to_be_deleted",$LOGFILE);
	die("testCopyResultsFile FAIL" ) unless(-e "tmp/to_be_deleted.sf3" ) ; 
	print "testCopyResultsFile PASS \n"; 
}


exit(0);


