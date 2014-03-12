#!/usr/bin/perl

use strict;
use Physique::LinkUDP;
use Physique::Noise; # pour generer des problemes et erreurs de transmission
use CRC;

my $car = 'o';
my $link = P_open(@ARGV);
my $nbrEnv = 0;
my $check = CRC::codage($car); # on ne l'encode qu'une seule fois puisque ce caractere ne change pas

print "\n -> envoi du caractere : ".$car." \n";
print unpack "B16", $check;
print "\n";
print unpack "B8", $car;
print "\n";
my $temp = unpack "B8", $car;
$temp = $temp . unpack "B16", $check;
$temp = pack "B24", $temp;
while($nbrEnv<10)
{
    print $temp."\n";
    P_envoiCar($link,$temp);
    $nbrEnv+=1;
}

print "\n -> nombre de caracteres envoyes : ".$nbrEnv."\n\n";

P_close($link);

