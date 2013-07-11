package SimpleLogger;

### log levels INFO (0), WARN (1), ERROR (2) 
sub log(){
	
	my @logLevels = ("INFO","WARN","ERROR");
	my ($logFile,$level,$msg,$task)= @_;
	open (LOG, ">>$logFile") || die "Cannot open log file" ;  
	print LOG localtime(time)."\t".$logLevels[$level],"\t".$msg."\t".$task."\t\n";  
	close (LOG);
	
	
}

sub clearLog(){
	
	my ($logFile) = @_;
	open (LOG, ">$logFile") || die "Cannot open log file";  
	close(LOG);
		
} 

return(1);