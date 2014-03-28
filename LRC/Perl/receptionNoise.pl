#!/usr/bin/perl

use strict;
use Physique::LinkUDP;
use Parity;

sub verification {
    my $car = ord($_[0]);

# retour du resultat du test de la parite de ce caractere :
    return not Parity::parity($car);
}

sub decodage {
    my $car = ord($_[0]);

# ou retourner le caractere vide si il y a erreur :
    return '' unless ( verification(chr($car)) );

# retourner le decodage du caractere par decalage a droite si la paritee est respectee :
    return chr( $car >> 1);
}




my $link = P_open(@ARGV);
my $nbrRec = 0; # nbr caracteres recus
my $nbrErr = 0; # nbr d'erreurs
my $nbrErrD = 0; # nbr d'erreurs detectees
my $ErrTempH = 0;
my $ErrTempV = 0;
my $H = 0;
my $V = 0 ;
my $verifTemp = 0;
my @temp = ();
my @data = ();

do{

    # on test la paritee de cette reception (on test si la reception est valide) :
    $ErrTempH = 0;
    $ErrTempV = 0;
    for(my $i=0;$i<7;$i++)
    {

        @data[$i] = P_recoitCar($link);
        print ord(@data[$i])."\n" ;
        @temp[$i] = @data[$i];
        $ErrTempH+=1 unless (verification(@temp[$i]));
        $V = $i  unless (verification(@temp[$i]));
    }
    @data[7] = P_recoitCar($link);
    @temp[7] = @data[7];
    for(my $i=0;$i<7;$i++)
    {
        my $temp ="";
        for(my $j=0;$j<8;$j++)
        {
            $temp = $temp.substr(@temp[$j],1,length(@temp[$j])-1);
        }

        $ErrTempV +=1  unless (verification($temp));
        $H = $i  unless (verification($temp));
    }

    if($ErrTempH>1&&$ErrTempH>1)
    {
         $nbrErrD+=1;
    }
    else
    {
        if($ErrTempH==1&&$ErrTempH==1)
        {
            $data[$V] = $data[$V] ^ (1 << $H);
        }
    }



# on test la validite de ce caractere recu :
    $verifTemp = 0;
    for(my $i=0;$i<7;$i++)
    {
       $verifTemp+=1 if (decodage($data[$i]) ne 'o'); # le caractere n'est pas celui attendu
    }
    if($verifTemp>1)
    {
        $nbrErr+=1;
    }

    $nbrRec += 1;
}while ($nbrRec < 1);


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
