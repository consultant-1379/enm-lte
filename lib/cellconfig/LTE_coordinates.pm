#!/usr/bin/perl
#############################################################################
#    START LIB MODULE HEADER
#############################################################################
#
#     Name :  LTE_coordinates
#
#     Description : Generate geographical coordinates for fieldreplaceable units
#                   for CBSD
#
#     Author : Harish Dunga
#                  
#############################################################################
##########################################
#  Environment
##########################################
package LTE_coordinates;
require Exporter;
@ISA=qw(Exporter);
# NOTE: NEED TO ADD NEW MODULE FUNCTIONS HERE
@EXPORT=qw(getPositionCoordinates);

use Cwd;
use POSIX;
use LTE_CellConfiguration;
##########################################
# funcs
##########################################
#-----------------------------------------------------------
#  Name         : getNodePosition
#  Description  : returns the position number of the node
#                 in the entire network
#  Params       : $simnum # number of Sim 
#                 $nodenum # nodenumber in that Sim
#                 $numofnodes # total number of nodes in the sim
#  Example      : getNodePosition($simnum,$nodenum,$numofnodes)
#  Return       : returns the position number of the node
#-----------------------------------------------------------
sub getNodePosition{

  local($simnum,$nodenum,$numofnodes)=@_;
  local $nodeposition;
  $nodeposition=(($simnum - 1) * $nodenodes) + $nodenum ;
  return($nodeposition);
}
#-----------------------------------------------------------
#  Name         : getDevicePosition
#  Description  : returns the fieldreplaceableUnit position
#                 in the entire network
#  Params       : $nodeposition # position number of the node
#                 $devicenum # fru number in that node
#                 $numofdevicespernode # total number of frus in
#                                        that node
#  Example      : getDevicePosition($nodeposition,$devicenum,$numofdevicespernode)
#  Return       : returns the position number of the fru
#-----------------------------------------------------------
sub getDevicePosition{

  local($nodeposition,$devicenum,$numofdevicespernode)=@_;
  local $deviceposition=(($nodeposition - 1) * $numofdevicespernode) + $devicenum;
  return($deviceposition);
}
#-----------------------------------------------------------
#  Name         : getPositionCoordinates
#  Description  : returns the latitude-longitude coordinates
#                 of the fru
#  Params       : $simnum # number of Sim 
#                 $nodenum # nodenumber in that Sim
#                 $devicenum # fru number in that node
#                 $numofdevices # total number of frus in
#                                 that node
#                 $numofnodes # total number of nodes in the sim
#  Example      : getNodePosition($simnum,$nodenum,$numofnodes)
#  Return       : returns the latitude and longitude values
#-----------------------------------------------------------
sub getPositionCoordinates{

  local($simnum,$nodenum,$devicenum,$numofdevices,$numofnodes)=@_;
  local $minlatitude="32727532";
  local $maxlatitude="41615628";
  local $minlongitude="-122464048";
  local $maxlongitude="-71068320";
  local $latituderange=($maxlatitude - $minlatitude + 1);
  local $longituderange=($maxlongitude - $minlongitude + 1);
  local $nodeposition=&getNodePosition($simnum,$nodenum,$numofnodes);
  local $deviceposition=&getDevicePosition($nodeposition,$devicenum,$numofdevices);
  local $latitude=(($nodeposition * 9) + $minlatitude);
  local $longitude=(($deviceposition * 9) + $minlongitude);
  if ($latitude > $maxlatitude) {
     local $latitudeOffset=($latitude % $latituderange);
     $latitude=($minlatitude + $latitudeOffset);
  }
  if ($longitude > $maxlongitude) {
     local $longitudeOffset=($longitude % $longituderange);
     $longitude=($minlongitude + $longitudeOffset);
  }
  return($latitude,$longitude);
}
