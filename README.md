
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
- Run scaffold
- Copy scaffold file (.sf3) to data storage drive
- Send job complete notification e-mail to user
		
### Installation

Required Non-Standard Install Perl Modules: 

- MIME::Lite
- Config::Simple

**Create a confiuration file: ./MascotScaffoldAutomation/etc/msa.ini**

see template file: ./MascotScaffoldAutomation/unitTest/etc/msa.param.example

	OUTPUTDIR path_to_dir_where_scaffold_files_is_copied 
	SCAFFOLDBATCHPATH C:\\Program Files\\Scaffold4\\ScaffoldBatch4.exe
	SMTPSERVERNAME smtp.gmail.com
	NOTFICATIONEMAILSENDERADR sender@gmail.com
	MASCOTSERVERURL http://mascot.somewhere.ch/mascot/cgi/login.pl
	MASCOTWEBUSERNAME sender
	MASCOTWEBPASSWORD letmein
	NOTFICATIONEMAILADRTEST reciever@gmail.com

**Masot Daemon External Processes Configuration**

![](https://github.com/eahrne/MascotScaffoldAutomation/blob/master/docs/Mascot_Daemon_External_Process.PNG)

After Search:

	perl "C:\MSA\createMascotDatFileQueue.pl" "<resulturl>" "<datafilepath>" "<taskname>"

After Completing Task:

	perl "C:\MSA\runScaffoldBatch.pl" "<mascot_user_email>" "<taskname>"

