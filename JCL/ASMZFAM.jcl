//ASMZFAM  JOB @job_parms@
//**********************************************************************
//* Assemble and compile the source code
//**********************************************************************
//PROC     JCLLIB ORDER=(@proc_lib@)
//**********************************************************************
//* Assemble and link L8WAIT
//**********************************************************************
//L8WAIT   EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(L8WAIT)
//*
//LKED.SYSIN DD *
   NAME L8WAIT(R)
/*
//**********************************************************************
//* Compile and link ZFAM000
//**********************************************************************
//ZFAM000  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM000)
//*
//LKED.SYSIN DD *
   NAME ZFAM000(R)
/*
//**********************************************************************
//* Assemble and link ZFAM001
//**********************************************************************
//ZFAM001  EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM001)
//*
//LKED.SYSIN DD *
   NAME ZFAM001(R)
/*
//**********************************************************************
//* Compile and link ZFAM002
//**********************************************************************
//ZFAM002  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM002)
//*
//LKED.SYSIN DD *
   NAME ZFAM002(R)
/*
//**********************************************************************
//* Compile and link ZFAM003
//**********************************************************************
//ZFAM003  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM003)
//*
//LKED.SYSIN DD *
   NAME ZFAM003(R)
/*
//**********************************************************************
//* Compile and link ZFAM004
//**********************************************************************
//ZFAM004  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM004)
//*
//LKED.SYSIN DD *
   NAME ZFAM004(R)
/*
//**********************************************************************
//* Compile and link ZFAM005
//**********************************************************************
//ZFAM005  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM005)
//*
//LKED.SYSIN DD *
   NAME ZFAM005(R)
/*
//**********************************************************************
//* Assemble and link ZFAM006
//**********************************************************************
//ZFAM006  EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM006)
//*
//LKED.SYSIN DD *
   NAME ZFAM006(R)
/*
//**********************************************************************
//* Compile and link ZFAM007
//**********************************************************************
//ZFAM007  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM007)
//*
//LKED.SYSIN DD *
   NAME ZFAM007(R)
/*
//**********************************************************************
//* Compile and link ZFAM008
//**********************************************************************
//ZFAM008  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM008)
//*
//LKED.SYSIN DD *
   NAME ZFAM008(R)
/*
//**********************************************************************
//* Compile and link ZFAM009
//**********************************************************************
//ZFAM009  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM009)
//*
//LKED.SYSIN DD *
   NAME ZFAM009(R)
/*
//**********************************************************************
//* Assemble and link ZFAM010
//**********************************************************************
//ZFAM010  EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM010)
//*
//LKED.SYSIN DD *
   NAME ZFAM010(R)
/*
//**********************************************************************
//* Compile and link ZFAM011
//**********************************************************************
//ZFAM011  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM011)
//*
//LKED.SYSIN DD *
   NAME ZFAM011(R)
/*
//**********************************************************************
//* Assemble and link ZFAM020
//**********************************************************************
//ZFAM020  EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM020)
//*
//LKED.SYSIN DD *
   NAME ZFAM020(R)
/*
//**********************************************************************
//* Assemble and link ZFAM022
//**********************************************************************
//ZFAM022  EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM022)
//*
//LKED.SYSIN DD *
   NAME ZFAM022(R)
/*
//**********************************************************************
//* Assemble and link ZFAM030
//**********************************************************************
//ZFAM030  EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM030)
//*
//LKED.SYSIN DD *
   NAME ZFAM030(R)
/*
//**********************************************************************
//* Compile and link ZFAM031
//**********************************************************************
//ZFAM031  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM031)
//*
//LKED.SYSIN DD *
   NAME ZFAM031(R)
/*
//**********************************************************************
//* Assemble and link ZFAM040
//**********************************************************************
//ZFAM040  EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM040)
//*
//LKED.SYSIN DD *
   NAME ZFAM040(R)
/*
//**********************************************************************
//* Compile and link ZFAM041
//**********************************************************************
//ZFAM041  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM041)
//*
//LKED.SYSIN DD *
   NAME ZFAM041(R)
/*
//**********************************************************************
//* Compile and link ZFAM090
//**********************************************************************
//ZFAM090  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM090)
//*
//LKED.SYSIN DD *
   NAME ZFAM090(R)
/*
//**********************************************************************
//* Compile and link ZFAM101
//**********************************************************************
//ZFAM101  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM101)
//*
//LKED.SYSIN DD *
   NAME ZFAM101(R)
/*
//**********************************************************************
//* Compile and link ZFAM102
//**********************************************************************
//ZFAM102  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAM102)
//*
//LKED.SYSIN DD *
   NAME ZFAM102(R)
/*
//**********************************************************************
//* Assemble and link ZFAMNC
//**********************************************************************
//ZFAMNC   EXEC DFHEITAL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAMNC)
//*
//LKED.SYSIN DD *
   NAME ZFAMNC(R)
/*
//**********************************************************************
//* Compile and link ZFAMPLT
//**********************************************************************
//ZFAMPLT  EXEC DFHYITVL,PROGLIB=@program_lib@,
//         DSCTLIB=@source_lib@
//TRN.SYSIN  DD DISP=SHR,DSN=@source_lib@(ZFAMPLT)
//*
//LKED.SYSIN DD *
   NAME ZFAMPLT(R)
/*
//**********************************************************************
//* Assemble ZUIDSTCK without CICS translator
//**********************************************************************
//ASM    EXEC PGM=ASMA90,
//            REGION=2M,
//            PARM='DECK,NOOBJECT,LIST'
//SYSLIB   DD DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(1700,(400,400))
//SYSUT2   DD UNIT=SYSDA,SPACE=(1700,(400,400))
//SYSUT3   DD UNIT=SYSDA,SPACE=(1700,(400,400))
//SYSPUNCH DD DSN=&&OBJECT,
//            UNIT=SYSDA,DISP=(,PASS),
//            SPACE=(400,(100,100))
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DISP=SHR,DSN=@source_lib@(ZUIDSTCK)
//**********************************************************************
//* Link-edit ZUIDSTCK
//**********************************************************************
//LKED   EXEC PGM=IEWL,REGION=2M,
//            PARM='LIST,XREF',COND=(7,LT,ASM)
//SYSLIB   DD DUMMY
//SYSIN DD *
  MODE AMODE(31),RMODE(ANY)
  SETSSI C3C3C3C5
/*
//SYSLMOD  DD DISP=SHR,DSN=@program_lib@(ZUIDSTCK)
//SYSUT1   DD UNIT=SYSDA,DCB=BLKSIZE=1024,
//            SPACE=(1024,(200,20))
//SYSPRINT DD SYSOUT=*
//SYSLIN   DD DSN=&&OBJECT,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//