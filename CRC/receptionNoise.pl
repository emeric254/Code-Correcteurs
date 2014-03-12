#!/usr/bin/perl

use strict;
use Physique::LinkUDP;
use CRC;

my $link = P_open(@ARGV);
my $nbrRec = 0; # nbr caracteres recus
my $nbrErr = 0; # nbr d'erreurs
my $nbrErrD = 0; # nbr d'erreurs detectees

do{
my $carRec = P_recoitCar($link);

# on test la paritée de cette reception (on test si la reception est valide) :
   $nbrErrD+=1 unless (CRC::verification($carRec)); # la reception ne respecte pas la parité

# on test la validité de ce caractere recu :
   $nbrErr+=1 if (CRC::decodage($carRec) ne 'o'); # le caractere n'est pas celui attendu

    $nbrRec += 1;
}while ($nbrRec < 100000);


print "\n";
print " -> nombre de receptions : ".$nbrRec."\n";
print " -> nombre de receptions supposees bonnes : ".($nbrRec-$nbrErrD)."\n";
print " -> nombre de vrais bons caracteres : ".($nbrRec-$nbrErr)."\n";
print " -> nombre d'erreurs au total : ".$nbrErr."\n";
print " -> nombre d'erreurs detectees : ".$nbrErrD."\n";
print " -> nombre d'erreurs non detectees : ".($nbrErr-$nbrErrD)."\n";
# attention a la division par "0" ! xD
print (" -> fiabilitee de l'envoi/reception : ".(100-100*$nbrErr/$nbrRec)."%\n") if($nbrRec != 0);
print (" -> fiabilitee de detection d'erreur : ".(100*$nbrErrD/$nbrErr)."%\n") if($nbrErr != 0);
print "\n";

P_close($link);
