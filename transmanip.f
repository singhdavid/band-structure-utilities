      IMPLICIT REAL*8(A-H,O-Z)
      CHARACTER*80 LINE
      CHARACTER*80 FNAME
      CHARACTER*12 OUTNAME
      CHARACTER*5 TNAME
      REAL*8,DIMENSION(3,3) :: SIG,SEEB,THERM
      REAL*8,DIMENSION(:),ALLOCATABLE :: XI,COUNTI,COUNTL
      REAL*8,DIMENSION(:,:,:),ALLOCATABLE :: SII,SEI,SIL,SEL
      REAL*8,DIMENSION(:),ALLOCATABLE :: DSI,DSL
      REAL*8,DIMENSION(:,:),ALLOCATABLE ::DSGRID,EFI
      REAL*8,DIMENSION(:,:,:,:),ALLOCATABLE ::SIGGRID,SEBGRID
      LOGICAL :: FIRST=.TRUE.
C
      WRITE(6,*)'Transport Formatting'
      WRITE(6,*)'  ENTER INPUT case '
      READ(5,'(A80)')FNAME
      OPEN(7,FILE=TRIM(FNAME)//'.trace',FORM='FORMATTED',STATUS='OLD')
      READ(7,'(A80)')LINE
      OPEN(8,FILE=TRIM(FNAME)//'.condtens',
     *      FORM='FORMATTED',STATUS='OLD')
      READ(8,'(A80)')LINE
C
      WRITE(6,*)'ENTER NUMBER OF DOPING LEVELS, MIN and MAX DOPING'
      READ(5,*)NDOP,XMIN,XMAX
      ALLOCATE(XI(NDOP))
      DELTAN=(XMAX-XMIN)/(NDOP-1)
      DO I=1,NDOP
      XI(I)=XMIN+(I-1)*DELTAN
      ENDDO
C
      T0=0.D0
      FN=70
      NUMT=0
    1 READ(7,'(2F10.0,8F16.0)',END=9,ERR=9)EX,T,ENUM,DOS,S,ST,RH,E,C,CH
      READ(8,'(2F10.0,28F16.0)',END=9,ERR=9)EX2,T2,SUME,
     * SIG(1:3,1:3),SEEB(1:3,1:3),THERM(1:3,1:3)
      IF(T.GT.T0)THEN
      FN=FN+1
      NUMT=NUMT+1
      DT=T-T0
      T0=T
      IF(T.LE.9.9D0)THEN
      WRITE(OUTNAME,'(''TRANS-000'',F3.1)')T
      ELSEIF(T.LE.99.9D0)THEN
      WRITE(OUTNAME,'(''TRANS-00'',F4.1)')T
      ELSEIF(T.LE.999.9D0)THEN
      WRITE(OUTNAME,'(''TRANS-0'',F5.1)')T
      ELSE
      WRITE(OUTNAME,'(''TRANS-'',F6.1)')T
      ENDIF
      OPEN(FN,FILE=OUTNAME,FORM='FORMATTED',STATUS='UNKNOWN')
      WRITE(FN,'('' EX,T,ENUM,DOS,SIGXX,SIGYY,SIGZZ,SXX,SYY,SZZ'')')
      ELSE
      IF(FIRST)THEN
      ALLOCATE(COUNTI(NUMT))
      ALLOCATE(COUNTL(NUMT))
      ALLOCATE(DSI(NUMT))
      ALLOCATE(SII(3,3,NUMT))
      ALLOCATE(SEI(3,3,NUMT))
      ALLOCATE(DSL(NUMT))
      ALLOCATE(SIL(3,3,NUMT))
      ALLOCATE(SEL(3,3,NUMT))
      ALLOCATE(SIGGRID(3,3,NUMT,NDOP))
      ALLOCATE(SEBGRID(3,3,NUMT,NDOP))
      ALLOCATE(EFI(NUMT,NDOP))
      ALLOCATE(DSGRID(NUMT,NDOP))
      EXI=0.D0
      DO J=1,NUMT
      COUNTI(J)=SUME
      COUNTI(J)=SUME
      ENDDO
      FIRST=.FALSE.
      ENDIF
      NT=(T+1.D-8)/DT
      FN=70+NT
C
      IF(NT.EQ.1)THEN
      EXL=EXI
      EXI=EX
      ENDIF
      COUNTL(NT)=COUNTI(NT)
      COUNTI(NT)=SUME
      DSL(NT)=DSI(NT)
      DSI(NT)=DOS
      DO I=1,3
      DO J=1,3
      SEL(J,I,NT)=SEI(J,I,NT)
      SIL(J,I,NT)=SII(J,I,NT)
      SEI(J,I,NT)=SEEB(J,I)
      SII(J,I,NT)=SIG(J,I)
      ENDDO
      ENDDO
C
      DO ND=1,NDOP
      PROD=(COUNTL(NT)-XI(ND))*(COUNTI(NT)-XI(ND))
      IF(PROD.LT.0.D0)THEN
      D1=ABS(COUNTL(NT)-XI(ND))
      D2=ABS(COUNTI(NT)-XI(ND))
      ALPHA=D2/(D1+D2)
      BETA=D1/(D1+D2)
      EFI(NT,ND)=ALPHA*EXL+BETA*EXI
      DSGRID(NT,ND)=ALPHA*DSL(NT)+BETA*DSI(NT)
      DO I=1,3
      DO J=1,3
      SIGGRID(J,I,NT,ND)=ALPHA*SIL(J,I,NT)+BETA*SII(J,I,NT)
      SEBGRID(J,I,NT,ND)=ALPHA*SEL(J,I,NT)+BETA*SEI(J,I,NT)
      ENDDO
      ENDDO
      ENDIF
      ENDDO
C
      ENDIF
      WRITE(FN,'(F10.5,F10.2,F16.7,16ES16.8)')
     *       EX,T,ENUM,DOS,SIG(1,1),SIG(2,2),SIG(3,3),
     *       SEEB(1,1),SEEB(2,2),SEEB(3,3)
      GOTO1
C
    9 CONTINUE
      DO ND=1,NDOP
      WRITE(TNAME,'(F5.3)')ABS(XI(ND))
      IF(XI(ND).GE.0.D0)THEN
      OPEN(40,FILE='TRD+'//TNAME,FORM='FORMATTED',STATUS='UNKNOWN')
      ELSE
      OPEN(40,FILE='TRD-'//TNAME,FORM='FORMATTED',STATUS='UNKNOWN')
      ENDIF
      WRITE(40,'(''# T,EF,DOS,SIGMA,SEEBECK'')')
      WRITE(40,'(''#  DOPING LEVEL='',F15.6)')XI(ND)
      DO NT=1,NUMT
      T=DT*NT
      WRITE(40,'(F10.5,20ES15.5)')T,EFI(NT,ND),DSGRID(NT,ND),
     *  SIGGRID(1:3,1:3,NT,ND),SEBGRID(1:3,1:3,NT,ND)
      ENDDO
      CLOSE(40)
      ENDDO
      STOP
      END
