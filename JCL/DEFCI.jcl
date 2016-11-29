//DEFCI    JOB @job_parms@
//**********************************************************************
//* Create and define CI file (alternate index) for a ZFAM instance
//**********************************************************************
//* Create config file for following steps
//**********************************************************************
//CONFIG    EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD *
* @ci_nbr@ starts from 02. It matches ID= value in FA##FD
 @ci_nbr@       02
 @environment@  DEV
 @id@           01
 @pri_cyl@      500
 @sec_cyl@      100
/*
//SYSUT2    DD DISP=(NEW,PASS),DSN=&&STRINGS,
//             UNIT=VIO,SPACE=(80,(1000,1000)),
//             DCB=(LRECL=80,RECFM=FB)
//SYSIN     DD DUMMY
//**********************************************************************
//* Customize the DFHCSDUP DEFINE statements and pass to next step
//**********************************************************************
//CUSTOMIZ EXEC PGM=IKJEFT1B
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(CSDZFAMC)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&CSDCMDS,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=(OLD,PASS),DSN=&&STRINGS
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Define the CSD definition for the FAEXPIRE file
//**********************************************************************
//DEFINE    EXEC  PGM=DFHCSDUP
//STEPLIB   DD    DISP=SHR,DSN=@cics_hlq@.SDFHLOAD
//DFHCSD    DD    DISP=SHR,DSN=@cics_csd@
//SYSPRINT  DD    SYSOUT=*,DCB=(BLKSIZE=133)
//SYSIN     DD    DISP=SHR,DSN=&&CSDCMDS
//**********************************************************************
//* Customize the CI file IDCAMS statements and pass to next step
//**********************************************************************
//FAMFILEC EXEC PGM=IKJEFT1B
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//INPUT    DD DISP=SHR,DSN=@source_lib@(ZFAMCI)
//OUTPUT   DD DISP=(NEW,PASS),DSN=&&ZFAMCI,
//            UNIT=VIO,SPACE=(80,(1000,1000)),
//            DCB=(LRECL=80,RECFM=FB)
//STRINGS  DD DISP=(OLD,PASS),DSN=&&STRINGS
//SYSTSIN  DD *
 EXEC '@source_lib@(REXXREPL)'
/*
//**********************************************************************
//* Define the FAEXPIRE for one enterprise caching environment
//**********************************************************************
//FAMFILED  EXEC  PGM=IDCAMS
//SYSPRINT  DD    SYSOUT=*,DCB=(BLKSIZE=133)
//SYSIN     DD    DISP=SHR,DSN=&&ZFAMCI
//*
//