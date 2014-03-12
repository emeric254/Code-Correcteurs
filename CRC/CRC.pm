use strict;
use warnings;
use Digest::CRC ;

package CRC;


#%.CRC::CRC
#%* Fonction : calcule le CRC d'une valeur numérique.
#%* Paramètre : la valeur numérique
#%* Valeur de retour :
#%** message et son checksum concatener
#%

sub codage {
    @_ == 1 or die;
    my ($code) = @_;
    my ($check) =  Digest::CRC::crc16($code);

    $code = unpack "B8", $code;
    $code = $code . unpack "B16", $check;

    return pack "B24", $code;
}


sub verification {
    print "retour de ".$_[0]." > ".Digest::CRC::crc16($_[0])."\n";
    return (Digest::CRC::crc16($_[0]) eq 0);
}


sub decodage {
    @_ == 1 or die;
    my ($code) = unpack "B24",$_[0];
    $code = pack "B8", $code; # récupération que de la partie utile du message
#    print "decoder : ".$code."\n";
    return $code;
}

1;
