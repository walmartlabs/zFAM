//FA##DC   JOB @job_parms@
//**********************************************************************
//* Customize and define replication for one instance of ZFAM
//**********************************************************************
//* To use this job repeatedly
//* Change ## to the @id@ value in DEFFA##, example: C ## 01 ALL
//* Customize replication parameters
//* Note: the scheme used below must match @scheme@ in DEFFA##
//* Submit
//* Enter CANCEL on the command line to cancel changes and exit edit
//**********************************************************************
//* Create FA##DC document template member
//**********************************************************************
//CREATE    EXEC PGM=IEBGENER,REGION=1024K
//SYSPRINT  DD SYSOUT=*
//SYSUT1    DD *
type: AS
http://sysplex01-fam.mycompany.com:@rep_port@
/*
//SYSUT2    DD DISP=SHR,DSN=@doct_lib@(FA##DC)
//SYSIN     DD DUMMY
//**********************************************************************
//* Define FA##DC document template definition
//**********************************************************************
//DEFDOCT   EXEC  PGM=DFHCSDUP
//STEPLIB   DD    DISP=SHR,DSN=@cics_hlq@.SDFHLOAD
//DFHCSD    DD    DISP=SHR,DSN=@cics_csd@
//SYSPRINT  DD    SYSOUT=*,DCB=(BLKSIZE=133)
//SYSIN     DD    *
 DEFINE DOCTEMPLATE(FA##DC) GROUP(FA##)
        TEMPLATENAME(FA##DC) DDNAME(@doct_dd@) MEMBERNAME(FA##DC)
        APPENDCRLF(YES) TYPE(EBCDIC)
/*
//