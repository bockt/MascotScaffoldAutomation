package ScaffoldBatchFunctions;

use strict;

### WRITTEN BY erik.ahrne@unibas.ch

use LWP::Simple 'get';
use File::Basename;
use XML::Simple;
use MIME::Lite;
use File::Copy;

sub readDatFileList() {

	my ( $datListFile, $logFile ) = @_;
	my %datFiles;

	open( IN, "<$datListFile" )
	  || (
		&SimpleLogger::log(
			$logFile,                            2,
			"QUEUE FILE NOT FOUND $datListFile", File::Spec->abs2rel($0)
		)
		&& die("QUEUE FILE NOT FOUND $datListFile")
	  );

	while ( my $line = <IN> ) {
		chomp($line);
		my ( $datFile, $pklFile ) = split( "\t", $line );
		$datFiles{$datFile} = $pklFile;
	}

	close(IN);
	return ( \%datFiles );
}

### download (filtered) .dat file from MascotServer via http
sub downloadDATFile() {

	my ( $datFileURL, $outputPath, $taskName,$username,$password, $logFile ) = @_;

	#program variables
	my (
		$resultsFileName,
		$URL,
		$ExportFile,
		$securityPath,
		$securityResponse,
		$sessionID,
	);

	$resultsFileName = basename($datFileURL);
	$outputPath      = File::Spec->catfile( $outputPath, $resultsFileName );

	## e.g http://localhost/mascot/cgi/master_results.pl?file=../data/20001023/F235567.dat
	$datFileURL =~ s/master_results.pl/export_dat_2.pl/
	  ; ### replace by export_dat_2.pl mascot script. THIS SEEMS TO BE THE LINK FOR "SMALL JOBS"/"JOBS WITH FEW VALID HITS" ???
	$datFileURL =~ s/master_results_2.pl/export_dat_2.pl/
	  ;    ### replace by export_dat_2.pl mascot script

	#Check to see if security is enabled
	$securityPath = $datFileURL;
	$securityPath =~
s/export_dat_2.pl\?file=..\/data\/\d+\/F\d+.dat/login.pl?display=nothing&onerrdisplay=nothing&action=issecuritydisabled/;
	$URL = "$securityPath";

	#Run the command
	unless ( defined( $securityResponse = get($URL) ) ) {
		print $securityResponse;
		die "could not get $securityResponse\n";
	}

	#If it is login
	if ( $securityResponse =~ /Mascot security is enabled/ ) {

		#Security is enabled
		$securityPath =~
s/display=nothing&onerrdisplay=nothing&action=issecuritydisabled/display=nothing&onerrdisplay=nothing&action=login&username=/;
		$securityPath .= $username . "&password=" . $password;

		$URL = "$securityPath";

		#Run the command
		unless ( defined( $securityResponse = get $URL)) {
			print $securityResponse;
			die "could not get $securityResponse\n";
		}

		($sessionID) = ( $securityResponse =~ /sessionID=(\w+_\d+)/ );

		unless (defined($sessionID)) {
			die "Could not get Mascot sessionId\n";
		}

		$sessionID = "&sessionID=" . $sessionID;
	}
	else {

		#if not export away
		$sessionID = "&sessionID=";
	}

	print ".DAT File Download sessionID $sessionID\n";
	&SimpleLogger::log( $logFile, 0, ".DAT File Download sessionID $sessionID",
		$taskName );

	#Assembl the Export URL
	$URL =
"$datFileURL&do_export=1&peptide_master=1&protein_master=1&search_master=1&show_format=1&show_header=1&show_params=1&show_mods=1&prot_desc=1&prot_score=1&prot_mass=1&prot_matches=1&prot_cover=1&prot_empai=1&prot_quant=1&pep_exp_mr=1&pep_exp_z=1&pep_calc_mr=1&pep_delta=1&pep_start=1&pep_end=1&pep_miss=1&pep_score=1&pep_homol=1&pep_ident=1&pep_expect=1&pep_seq=1&pep_var_mod=1&pep_num_match=1&pep_scan_title=1&pep_quant=1&export_format=MascotDAT&$sessionID&generate_file=1";

	#Run the command
	unless ( defined( $ExportFile = get($URL) ) ) {
		&SimpleLogger::log( $logFile, 2, "Could not get $URL", $taskName );
		die "\n\ncould not get $URL\n\n";
		### log
	}

	#print $URL;

	#save the results
	open OUT,
	  ">$outputPath"
	  || (
		&SimpleLogger::log( $logFile, 2, "Can't open $outputPath", $taskName )
		&& die("Can't open $outputPath") );
	print OUT $ExportFile;
	close OUT;

	return ($outputPath);

}

### extract fasta file path on mascot server from .dat file. @TODO What if multiple fasta files were searched (Don't know how Scaffold deals with this???)
sub getFastaFilePath() {

	my ( $datFile, $taskName, $logFile ) = @_;

	open( FH, $datFile )
	  || ( &SimpleLogger::log( $logFile, 2, "Can't open $datFile", $taskName )
		&& die("Can't open $datFile") );
	my @buf = <FH>;
	close(FH);
	my @lines = grep ( /fastafile/, @buf );

	unless ( defined $lines[0] ) {
		&SimpleLogger::log( $logFile, 2,
			"Could not extract fasta file path from $datFile", $taskName );
		die("Could not extract fasta file path from $datFile");
	}

	my $fastaFilePath = $lines[0];
	$fastaFilePath =~ s/fastafile\=//;
	chomp($fastaFilePath);
	$fastaFilePath =~ s/.*\/sequence\///;

	return ($fastaFilePath);

}

### Download fasta file using getFasta.pl cgi script on mascot server
sub downloadFastaFile() {

	my ( $fastaMSFilePath, $downloadFastaFilePath, $mascotServerURL, $taskName, $logFile ) = @_;

	open OUT, ">$downloadFastaFilePath"
	  || (
		&SimpleLogger::log( $logFile, 2, "Can't open $downloadFastaFilePath",
			$taskName )
		&& die("Can't open $downloadFastaFilePath")
	  );
	
	my $content = get $mascotServerURL.'/mascot/cgi/getFasta.pl?fasta='.$fastaMSFilePath;

	if(defined $content){
		$content =~ s/\r//g;  ### remove windows line break. Not compatible with Scaffold.
		print OUT $content;
		close OUT;
		return(1);
	}else{ # fail
		return(0);
	}
}

### create scaffold xml driver
sub createXMLScaffoldDriver() {

	my ( $driverFilePath, $fastaFilePath, $datFilePaths_href, $outPutDirPath,
		$taskName, $logFile )
	  = @_;

	my $outpathSfd = File::Spec->catfile( $outPutDirPath, $taskName . ".sf3" );
	#my $outpathXML =
	#  File::Spec->catfile( $outPutDirPath, $taskName . ".prot.xml" );
	#my $outpathMzIdentML =
	#  File::Spec->catfile( $outPutDirPath, $taskName . ".mzid" );
	  
#	my $outpathMzIdentML =
#	  File::Spec->catfile( $outPutDirPath, $taskName . "_PRIDE" );  
	  
	
	my $databaseName = "foo";

	my $scaffoldDriverHash = {

		### build hash
		Experiment => [
			{
				name           => $taskName,
#				useIndependentSampleGrouping => "true",
				useFamilyProteinGrouping => "false",
				highMassAccuracyScoring => "false",
				use3xScoring => "false",
				
				AFastaDatabase => {
					id                       => $databaseName,
					path                     => $fastaFilePath,
					decoyProteinRegEx        => "REV_",
					databaseAccessionRegEx   => ">([^ ]*)",
					databaseDescriptionRegEx => ">[^ ]*[ ](.*)",
					name 					=> "Generic", 
				
				},
				DisplayThresholds => {
					name                => "Batch", ### Name of my set of thresholds
					id                  => "thresh",
					proteinProbability  => "0.9",
					minimumPeptideCount => "2",
					peptideProbability  => "0.2"
				},
				Export => [ 
					{
						type       => "sf3",
						thresholds => "thresh",
						path       => $outpathSfd
					},
#					{
#						type       => "protxml",
#						thresholds => "thresh",
#						path       => $outpathXML
#					},
#					{ ### useful for pride submissions
#						type       => "mzIdentML",
#						thresholds => "thresh",
#						version    =>"1.1.0",
#						showDecoys =>"false",
#						useFilter  =>"true",
#						individualReports  =>"true",
#						useGzip    =>"false",
#						writePeaklists  =>"true",
#						path       => $outpathMzIdentML,
#						threshold  =>"thresh"
#					},

				],
			}
		]
	};

	#my $c = 1;
	foreach my $datFilePath (keys %$datFilePaths_href) {
		
		my $sampleLabel = $datFilePaths_href ->{$datFilePath}; ### @TODO sample label as given in SampleQueuer (should be part of the file name) 
		$sampleLabel=basename($sampleLabel);
		$sampleLabel =~ s/\.mgf$//;
		$sampleLabel =~ s/\.raw$//;
		
		push(
			@{ $scaffoldDriverHash->{Experiment}[0]->{BiologicalSample} },
			{
				database  => $databaseName,
				InputFile => [$datFilePath],
				#name      =>  $sampleLabel. "_$c"
				name      =>  $sampleLabel
			}
		);  
		#$c++;
	}

	### convert hash to xml and pritn to file

	my $out = XMLout( $scaffoldDriverHash, RootName => "Scaffold" );

	### very dirty hack to ensure print FastaDatabase element to be printed first
	$out =~ s/AFastaDatabase/FastaDatabase/;
	$out =~ s/&gt;/>/g;                      ### Not sure why I have to do this.

	open OUT, ">$driverFilePath"
	  || (
		&SimpleLogger::log( $logFile, 2, "Can't open $driverFilePath",
			$taskName )
		&& die("Can't open $driverFilePath")
	  );
	print OUT $out;
	close OUT;

}

### scaffold provided a scaffold xml driver file
sub runScaffold() {

	my ( $scaffoldBatchPath, $scaffoldDriverFilePath, $scaffoldProgressLogFile,
		$scaffoldErrorLogFile, $taskName, $logFile )
	  = @_;

	# hack
	#"\"C:\\Program Files\\Scaffold4\\ScaffoldBatch4.exe\""
	$scaffoldBatchPath =  '"'.$scaffoldBatchPath.'"';
	
	### cmd line
	my $sysCmd =
"$scaffoldBatchPath -f \"$scaffoldDriverFilePath\" >\"$scaffoldProgressLogFile\" 2>\"$scaffoldErrorLogFile\"";

	&SimpleLogger::log( $logFile, 2,
		"XML Driver not Found: $scaffoldDriverFilePath", $taskName )
	  unless ( -e $scaffoldDriverFilePath );

	### run scaffold batch
	my $status = system($sysCmd);
	if ( ( $status >>= 8 ) != 0 ) {

		my $msg = "Failed to run Scaffold Batch, $sysCmd";
		&SimpleLogger::log( $logFile, 2, $msg, $taskName );
		die( $msg . "\n" );
	}
}

### create e-mail msg
sub getEmailNotificationMsg {

	my ( $taskName, $scaffoldResultsPath, $mascotDatFileURLs_href ) = @_;
	my $mascotFilesMsg = join( "\n", keys %$mascotDatFileURLs_href );

	$scaffoldResultsPath = File::Spec->catfile($scaffoldResultsPath,"$taskName.sf3");

	my $msg = <<END;
Scaffold Batch Task $taskName has finished.
The Scaffold results file is available at: 
$scaffoldResultsPath

The Mascot Search Results are available at:
$mascotFilesMsg
	
Enjoy!

/Erik
END

	return ($msg);
}

### send notification e-mail
sub sendEmailNotification() {

	my ( $emailToAdr, $emailFromAdr,$serverName, $msgHeader, $msg, $taskName, $logFile ) =
	  @_;

	# Set this variable to your smtp server name
	#my $ServerName = "smtp.unibas.ch";

	my $from_address = $emailFromAdr;
	my $to_address   = $emailToAdr;
	my $subject      = $msgHeader;
	my $mime_type    = 'text';
	my $message_body = $msg;

	# Create the initial text of the message
	my $mime_msg = MIME::Lite->new(
		From    => $from_address,
		To      => $to_address,
		Subject => $subject,
		Type    => $mime_type,
		Data    => $message_body
	  )
	  or (
		&SimpleLogger::log( $logFile, 2, "Failed to send notifications e-mail",
			$taskName )
		&& die("Failed to send notifications e-mail $!\n")
	  );

	MIME::Lite->send( 'smtp', $serverName );
	my $status = $mime_msg->send()
	  or (
		&SimpleLogger::log( $logFile, 2, "Failed to send notifications e-mail",
			$taskName )
		&& die("Failed to send notifications e-mail $!\n")
	  );
	return ($status);
}

## copy results file to e.g. network drive @TODO currently only .sf3 file is copied
sub copyResultsFile{
	
	my ($toDir,$tmpDir ,$taskName ,$logFile) = @_;
	
	my $fromPath=File::Spec->catfile($tmpDir,"$taskName.sf3");
	my $toPath=File::Spec->catfile($toDir,"$taskName.sf3");
		
	my $status = safeCopy($fromPath,$toPath);
	if ( $status != 1 ) {
		my $msg = "Failed to run system copy $fromPath to $toPath";
		&SimpleLogger::log( $logFile, 2, $msg, $taskName );
		die( $msg . "\n" );
	}
	
}

### file in copy is assigned tmp file name at destination and renamed to its origninal name upon copy complete
sub safeCopy(){
	my ($from,$to) = @_;
	
	my $toTmp = File::Spec->catfile(dirname($to),basename($to).'.tmp');
	
	my $status1 = copy($from,$toTmp);
	if($status1 < 1){
		return($status1);
	}
	
	my $status2 = move($toTmp,$to);
	if($status2 < 1){
		return($status2);
	}
	
	return(1);
	
}

return (1);
  