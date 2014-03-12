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

    my ($crc) =  Digest::CRC::crc16($code);
    return $crc;
}


sub verification {
    my $temp = $_[0];
    return (Digest::CRC::crc16($temp)==0);
}


sub decodage {
    @_ == 1 or die;
    my ($code) = @_;
    print $code."\n";
# decalage a droite du degré du polynome
   $code = pack "B8", $code;
   print $code."\n";
    return $code;

}

1;
