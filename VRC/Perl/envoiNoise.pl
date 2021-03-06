#!/usr/bin/perl

use strict;
use Physique::LinkUDP;
use Physique::Noise; # pour generer des problemes et erreurs de transmission
use Parity;

sub codage {
   my ($car) = @_;

# ajout d'un zero a droite de la valeur binaire du caractere (decalage a gauche) :
   $car = ord($car) << 1;

# application de la paritee si ce caractere "impair", on inverse le dernier bit qui devient donc un "1" :
   $car = $car ^ 1  if Parity::parity($car);

# on retourne le caractere et non pas sa valeur binaire :
   return chr($car);
}



my $car = 'o';
my $link = P_open(@ARGV);
my $nbrEnv = 0;
my $temp = codage($car); # on ne l'encode qu'une seule fois puisque ce caractere ne change pas

print "\n -> envoi du caractere : ".$car." \n";

while($nbrEnv<100000)
{
   P_envoiCar($link,$temp);
   $nbrEnv+=1;
}

print "\n -> nombre de caracteres envoyes : ".$nbrEnv."\n\n";

P_close($link);
