use strict;
use warnings;

package Parity;

#%.Parity::parity
#%* Fonction : calcule la parité d'une valeur numérique.
#%* Paramètre : la valeur numérique
#%* Valeur de retour :
#%** 0 si le nombre de bit à 1 est pair
#%** 1 si le nombre de bit à 1 est impair
#%* Exemples :
#%** ++my $par = Parity::parity($x);++
#%** ++my $par = Parity::parity(ord("A"));++
#%
sub parity {
    @_ == 1 or die;
    my ($code) = @_;
    my $parity = 0;
    while($code != 0) {
	$parity ^= 1 if ($code & 1);
	$code >>= 1;
    }
    return $parity;
}

1;
