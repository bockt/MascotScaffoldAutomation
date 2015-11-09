
##Mascot Scaffold Automation
Run Scaffold Batch from within Mascot Daemon.  
### Synopsis
Mascot Daemon External Processes:

After each seach

- Create Mascot Dat File Queue (queue file in tmp folder. File name given by task name (spaces replaced by _))


After Completing Task

- Read .dat file queue
- Download all .dat files
- Parse one .dat file and extract .fasta file path
- Download .fasta file
- Create Scaffold .xml driver
- run scaffold		

### Installation
 Required Non-Standard Install Perl Modules: 

- MIME::Lite
- Config::Simple

![](https://github.com/eahrne/MascotScaffoldAutomation/blob/master/docs/Mascot_Daemon_External_Process.PNG)

**Masot Daemon External Processes Configuration**

After Search:

	perl "C:\MSA\createMascotDatFileQueue.pl" "<resulturl>" "<datafilepath>" "<taskname>"

After Completing Task:

	perl "C:\MSA\runScaffoldBatch.pl" "<mascot_user_email>" "<taskname>"

