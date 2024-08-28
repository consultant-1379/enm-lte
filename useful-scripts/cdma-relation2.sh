#!/bin/sh

# Created by  : Ronan Mehigan
# Created in  : 01/09/2009
##
### VERSION HISTORY
# Ver1        : Added in TERE 10.0 review
# Purpose     :
# Description :
# Date        : 01/09/2009
# Who         : Fatih ONUR
#
# Ver2        : Modified for req id 2653
# Purpose     : Bugs are fixed for Cdma2000FreqBandRelations
# Description :
# Date        : 11 Jan 2010
# Who         : Fatih ONUR



if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 start

Example: $0 start

DESCRP : Print out cdma relation 

HELP

exit 1
fi


ERBSCOUNT=1

##############
NUMOFRBS=160
LTE=$1
##############

if [ "$LTE" -le 9 ]
then
 LTENAME="LTE0"$LTE
else
 LTENAME="LTE"$LTE
fi

echo "Working on Simulation "$LTENAME
echo "-----------------------------------"

  # Create the ExternalCdma2000Cells which are unique to the ERBS NEs
  #
  # Calculate the starting index number of ExternalCdma2000Cell
  # LTE01 ERBS01 -> ExternalCdma2000Cells 1,2
  # LTE01 ERBS02 -> ExternalCdma2000Cells 3,4
  #
  # LTE01 ERBS160 -> ExternalCdma2000Cells 319,320
  # 
  # LTE02 ERBS01 -> ExternalCdma2000Cells 321,322  ....etc
  # 
  # An=A1+d(n-1)
  # An = 1 + 320(n-1)
  # An = 320n - 319 

StartExternalCdma2000Cell=`expr $LTE \* 320 - 319`
CountExternalCdma2000Cell=$StartExternalCdma2000Cell

  # PLUSBLOCKNUMBER = 8n - 8 wher n is LTENO and for LTE01 and ERBS37 PBN = 8 * 1 - 8 = 0, for LTE02 PBN = 8 * 2 - 8 = 8
  PLUSBLOCKNUMBER=`expr 8 \* $LTE - 8`
  BLOCKNO=1

while [ "$ERBSCOUNT" -le "$NUMOFRBS" ]
do
echo
echo "Working on ERBS="$ERBSCOUNT
echo "-----------------------------------"


echo "Creating Cdma2000Network=1"

FREQBAND=1
FREQCDMA=1
while [ "$FREQBAND" -le "2" ]
do
 echo "Creating Cdma2000FreqBand="$FREQBAND 

 FREQ=1
 while [ "$FREQ" -le "2" ]
 do
  echo "Creating Cdma2000Freq="$FREQ" with attribute freqCdma="$FREQCDMA

  FREQCDMA=`expr $FREQCDMA + 1`
  FREQ=`expr $FREQ + 1`
 done

FREQBAND=`expr $FREQBAND + 1`
done

  StopExternalCdma2000Cell=`expr $CountExternalCdma2000Cell + 1`
  
  
  while [ "$CountExternalCdma2000Cell" -le "$StopExternalCdma2000Cell" ]
  do
   
  # DIV=`expr $CountExternalCdma2000Cell / 2000`
   #echo "DIV="$DIV

   DIV=`expr $CountExternalCdma2000Cell / 2000`
   MOD=`expr $CountExternalCdma2000Cell % 2000`

   if [ "$MOD" -eq 0 ]
   then
     GROUP=`expr $DIV - 1`
   else
     GROUP=$DIV
   fi
 
   case "$GROUP"
    in 
     0) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=1;;
     1) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=2;;
     2) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=3;;
     3) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=4;;
   esac   
   
   echo "Creating Cdma2000FreqBand="$TargetCdmaFreqBand",Cdma2000Freq="$TargetCdmaFreq"(freqCdma="$TargetfreqCdma"),ExternalCdma2000Cell="$CountExternalCdma2000Cell
   CountExternalCdma2000Cell=`expr $CountExternalCdma2000Cell + 1`
   
  done



  # Create ExternalCdma2000Cells which are shared across 20 ERBS (200 blocks of 20 ERBS)
  #
  # Need to create 38 ExternalCdma2000Cells
  # 10 in each Freq and the Freq which was used for the unique ERBS gets 8 cells (so 10 + 10 + 10 + 8)
  
  # The ERBSs are divided into 200 blocks of 20 (for the shared ExternalCdma2000Cells)
  ## BLOCKDIV=`expr $ERBSCOUNT / 21`
  ## ERBSBLOCK=`expr $BLOCKDIV + 1`  

  # BLOCKMOD=`expr $ERBSCOUNT % 20`
  # ERBSBLOCK=`expr $BLOCKNO + $PLUSBLOCKNUMBER`

   DIVE=`expr $ERBSCOUNT / 20`
   MODE=`expr $ERBSCOUNT % 20`

  if [ "$MODE" -eq 0 ]
  then
    ERBSBLOCK=`expr $DIVE + $PLUSBLOCKNUMBER`
  else
    ERBSBLOCK=`expr $DIVE + $PLUSBLOCKNUMBER + 1`
  fi



  echo "This is ERBS"$ERBSCOUNT" and it is in block "$ERBSBLOCK " (of 200)"

  #if [ "$BLOCKMOD" -eq 0 ]; then
  #   BLOCKNO=`expr $BLOCKNO + 1`
  #   echo "---------------"
  #   echo "BLOCKNO=" $BLOCKNO
  #   echo "----------------"
  #fi
 
  # Block1 8001-8008, 9901-9910, 11801-11810, 13701-13710
  # Block2 8009-8016, 9911-9920, 11811-11820, 13711-13720
  # 
  # Block(N) (8N+7993 - 8N+8000)*,  (10N+9891 - 10N+9900), (10N+11791 - 10N+11800), (10N+13691 - 10N+13700)
  #
  # Block50 8393-8400, 10391-10400, 12291-12300, 14191-14200
  #
  #
  # Block51 8401-8410, 10401-10408, 12301-12310, 14201-14210
  # Block52 8411-8420, 10409-10416, 12311-12320, 14211-14220
  #
  # Block(P) (10P+7891 - 10P+7900), (8P+9993 - 8P+10000)*, (10P+11791 - 10P+11800), (10P+13691 - 10P+13700)
  #
  # Block100 8891-8900, 10793-10800, 12791-12800, 14691-14700
  #
  #
  # Block101 8901-8910, 10801-10810, 12801-12808, 14701-14710
  # Block102 8911-8920, 10811-10820, 12809-12816, 14711-14720
  #
  # Block(Q) (10Q+7891 - 10Q+7900), (10Q+9791 - 10Q+9800), (8Q+11993 - 8N+12000)*, (10Q+13691 - 10Q+13700)
  # 
  # Block150 9391-9400, 11291-11300, 13193-13200, 15191-15200
  #
  #
  # Block151 9401-9410, 11301-11310, 13201-13210, 15201-15208
  # Block152 9411-9420, 11311-11320, 13211-13220, 15209-15216
  #
  # Block(T)  (10T+7891 - 10T+7900), (10T+9791 - 10T+9800), (10T+11691 - 10T+11700), (8T+13993 - 8T+14000)*
  #
  # Block200 9891-9900, 11791-11800, 13691-13700, 15593-15600
  
 
   DIVB=`expr $ERBSBLOCK / 50`
   MODB=`expr $ERBSBLOCK % 50`
  
  if [ "$MODB" -eq 0 ]
  then
    GROUPB=`expr $DIVB - 1`
  else
    GROUPB=$DIVB
  fi
 
  DIVBLOCK=$GROUPB
  echo "ERBSBLOCK= "$ERBSBLOCK
  #DIVBLOCK=`expr $ERBSBLOCK / 51`
  echo "DIVBLOCK= "$DIVBLOCK
  
  if [ "$DIVBLOCK" -eq 0 ]
  then
   # freq1 already has 2 ExternalCdma2000Cells so needs 8 more, other freq need 10
   # Block1->Block50
   echo " Block1->Block50"
   
    #echo "DIVBLOLCK= "$DIVBLOCK

    Range1Start=`expr $ERBSBLOCK \* 8 + 7993`
    Range1Stop=`expr $ERBSBLOCK \* 8 + 8000`
    
    Range2Start=`expr $ERBSBLOCK \* 10 + 9891`
    Range2Stop=`expr $ERBSBLOCK \* 10 + 9900`
    
    Range3Start=`expr $ERBSBLOCK \* 10 + 11791`
    Range3Stop=`expr $ERBSBLOCK \* 10 + 11800`
    
    Range4Start=`expr $ERBSBLOCK \* 10 + 13691`
    Range4Stop=`expr $ERBSBLOCK \* 10 + 13700`    
  fi
  
  if [ "$DIVBLOCK" -eq 1 ]
  then
   # freq2 already has 2 ExternalCdma2000Cells so needs 8 more, other freq need 10
   # Block51->Block100
   echo " Block51->Block100"

   #echo ""
   #echo "--------------DIVBLOCK=1----------------------"
   #echo "" 
   
   #echo "DIVBLOLCK= "$DIVBLOCK

    Range1Start=`expr $ERBSBLOCK \* 10 + 7891`
    Range1Stop=`expr $ERBSBLOCK \* 10 + 7900`
    
    Range2Start=`expr $ERBSBLOCK \* 8 + 9993`
    Range2Stop=`expr $ERBSBLOCK \* 8 + 10000`
    
    Range3Start=`expr $ERBSBLOCK \* 10 + 11791`
    Range3Stop=`expr $ERBSBLOCK \* 10 + 11800`
    
    Range4Start=`expr $ERBSBLOCK \* 10 + 13691`
    Range4Stop=`expr $ERBSBLOCK \* 10 + 13700`    
  fi
  
  if [ "$DIVBLOCK" -eq 2 ]
  then
   # freq3 already has 2 ExternalCdma2000Cells so needs 8 more, other freq need 10
   # Block101->Block150
   echo " Block101->Block150"
   
    Range1Start=`expr $ERBSBLOCK \* 10 + 7891`
    Range1Stop=`expr $ERBSBLOCK \* 10 + 7900`
    
    Range2Start=`expr $ERBSBLOCK \* 10 + 9791`
    Range2Stop=`expr $ERBSBLOCK \* 10 + 9800`
    
    Range3Start=`expr $ERBSBLOCK \* 8 + 11993`
    Range3Stop=`expr $ERBSBLOCK \* 8 + 12000`
    
    Range4Start=`expr $ERBSBLOCK \* 10 + 13691`
    Range4Stop=`expr $ERBSBLOCK \* 10 + 13700`    
  fi
  
  if [ "$DIVBLOCK" -eq 3 ]
  then
   # freq4 already has 2 ExternalCdma2000Cells so needs 8 more, other freq need 10
   # Block151->Block200
   echo " Block151->Block200"
   
    Range1Start=`expr $ERBSBLOCK \* 10 + 7891`
    Range1Stop=`expr $ERBSBLOCK \* 10 + 7900`
    
    Range2Start=`expr $ERBSBLOCK \* 10 + 9791`
    Range2Stop=`expr $ERBSBLOCK \* 10 + 9800`
    
    Range3Start=`expr $ERBSBLOCK \* 10 + 11691`
    Range3Stop=`expr $ERBSBLOCK \* 10 + 11700`
    
    Range4Start=`expr $ERBSBLOCK \* 8 + 13993`
    Range4Stop=`expr $ERBSBLOCK \* 8 + 14000`    
  fi
  
  
  COUNT=$Range1Start
  #echo "***********************************"
  #echo "Range1Start="$Range1Start
  #echo "Range1Stop="$Range1Stop
  #echo "***********************************"
  while [ "$COUNT" -le "$Range1Stop" ]
  do
  
  # echo "COUNT is "$COUNT
  # echo "STOP is" $Range1Stop
  
   TEMP=`expr $COUNT - 8000`
   # echo "TEMP= "$TEMP
    
   DIV=`expr $TEMP / 1900`
   MOD=`expr $TEMP % 1900`
  
  if [ "$MOD" -eq 0 ]
  then
    GROUP=`expr $DIV - 1`
  else
    GROUP=$DIV
  fi  
 
   case "$GROUP"
    in 
     0) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=1;;
     1) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=2;;
     2) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=3;;
     3) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=4;;
   esac   
  
  echo "Creating Cdma2000FreqBand="$TargetCdmaFreqBand",Cdma2000Freq="$TargetCdmaFreq"(freqCdma="$TargetfreqCdma"),ExternalCdma2000Cell="$COUNT
  COUNT=`expr $COUNT + 1`
  done
  
  COUNT=$Range2Start
  while [ "$COUNT" -le "$Range2Stop" ]
  do
  
   TEMP=`expr $COUNT - 8000`
   # echo "TEMP= "$TEMP
  
   DIV=`expr $TEMP / 1900`
   MOD=`expr $TEMP % 1900`

  if [ "$MOD" -eq 0 ]
  then
    GROUP=`expr $DIV - 1`
  else
    GROUP=$DIV
  fi

   case "$GROUP"
    in 
     0) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=1;;
     1) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=2;;
     2) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=3;;
     3) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=4;;
   esac   
  
  echo "Creating Cdma2000FreqBand="$TargetCdmaFreqBand",Cdma2000Freq="$TargetCdmaFreq"(freqCdma="$TargetfreqCdma"),ExternalCdma2000Cell="$COUNT
  COUNT=`expr $COUNT + 1`
  done
  
  COUNT=$Range3Start
  while [ "$COUNT" -le "$Range3Stop" ]
  do
  
   TEMP=`expr $COUNT - 8000`
   # echo "TEMP= "$TEMP
  
   DIV=`expr $TEMP / 1900`
   MOD=`expr $TEMP % 1900`

  if [ "$MOD" -eq 0 ]
  then
    GROUP=`expr $DIV - 1`
  else
    GROUP=$DIV
  fi

   case "$GROUP"
    in 
     0) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=1;;
     1) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=2;;
     2) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=3;;
     3) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=4;;
   esac   
  
  echo "Creating Cdma2000FreqBand="$TargetCdmaFreqBand",Cdma2000Freq="$TargetCdmaFreq"(freqCdma="$TargetfreqCdma"),ExternalCdma2000Cell="$COUNT
  COUNT=`expr $COUNT + 1`
  done
  
  COUNT=$Range4Start
  while [ "$COUNT" -le "$Range4Stop" ]
  do
  
   TEMP=`expr $COUNT - 8000`
   # echo "TEMP= "$TEMP
   DIV=`expr $TEMP / 1900`
   MOD=`expr $TEMP % 1900`

  if [ "$MOD" -eq 0 ]
  then
    GROUP=`expr $DIV - 1`
  else
    GROUP=$DIV
  fi

   case "$GROUP"
    in 
     0) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=1;;
     1) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=2;;
     2) TargetCdmaFreqBand=1; TargetCdmaFreq=1; TargetfreqCdma=3;;
     3) TargetCdmaFreqBand=1; TargetCdmaFreq=2; TargetfreqCdma=4;;
   esac   
  
  echo "Creating Cdma2000FreqBand="$TargetCdmaFreqBand",Cdma2000Freq="$TargetCdmaFreq"(freqCdma="$TargetfreqCdma"),ExternalCdma2000Cell="$COUNT
  COUNT=`expr $COUNT + 1`
  done
  
ERBSCOUNT=`expr $ERBSCOUNT + 1`
done
