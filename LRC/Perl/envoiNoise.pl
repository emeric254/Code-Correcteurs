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

sub codage2 {
    my @car =();
    my $retour="";
   for(my $i=0;$i<7;$i++)
   {
       @car[$i] = ord($_[0]);
       @car[$i] = unpack "B8", @car[$i];
       @car[$i]= reverse(@car[$i]);
       print @car[$i]."\n";
       shift;
   }

    for(my $i=0;$i<7;$i++)
    {
        my $retour = "";
        for(my $j=0;$j<7;$j++)
        {
            $retour = $retour.chop(@car[$i]);
            print $retour."\n";
        }
        $retour = ord($retour);
        $retour = $retour << 1;
        $retour = $retour ^ 1  if Parity::parity($retour);
    }
# on retourne le caractere et non pas sa valeur binaire :
   return chr($retour);
}



my $car = 'o';
my $link = P_open(@ARGV);
my $nbrEnv = 0;
my @temp = ();


for(my $i=0;$i<7;$i++)
{
    @temp[$i] = codage($car);
    #~ print ord(@temp[$i] );
}
@temp[8] = codage2($temp[0],$temp[1],$temp[2],$temp[3],$temp[4],$temp[5],$temp[6]);
print "\n -> envoi du caractere : ".$car." \n";

while($nbrEnv<1)
{
    for(my $i=0;$i<8;$i++){
        print ord(@temp[$i])."\n" ;
        P_envoiCar($link,chr(@temp[$i]));
    }
    $nbrEnv+=1;
}

print "\n -> nombre de caracteres envoyes : ".$nbrEnv."\n\n";

P_close($link);
