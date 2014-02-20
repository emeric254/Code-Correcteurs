use strict;
use warnings;

use Digest::CRC ;

package CRC;

#%.CRC::CRC
#%* Fonction : calcule le CRC d'une valeur numérique.
#%* Paramètre : la valeur numérique
#%* Valeur de retour :
#%** message et son checksum concatener
#%* Exemples :
#%** ++my $par = CRC::CRC($x);++
#%** ++my $par = CRC::CRC(ord("A"));++
#%

sub codage {
    @_ == 1 or die;
    my ($code) = @_;
   

	$code = crc16($code,$code);

    return $code;
}


sub verification {
	my $temp = ord($_[0]);
	return (crc16($temp)==0);	
}


sub decodage {
    @_ == 1 or die;
    my ($code) = @_;
 

# decalage a droite du degré du polynome
   $code = ord($code) >> 16;
   
    return $code;
}

1;
