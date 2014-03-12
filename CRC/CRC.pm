use strict;
use warnings;
use Digest::CRC ;

package CRC;


sub codage {
    @_ == 1 or die;
    my ($code) = @_;
    my ($check) =  unpack "B16", Digest::CRC::crc16($code); # on fixe la taille voulue du checksum que l'on calcul à 16bit, cela permet de ne pas perdre les 0 devant le premier bit de poids fort

#    print Digest::CRC::crc16($code)."\n";
#    print unpack("B16",Digest::CRC::crc16($code))."\n";

    $code.=pack("B16",$check); # on concatène le checksum au message

#    print $code."\n\n";
#    print unpack("B*",$code)."\n\n";

    return $code;
}


sub verification {
    @_ == 1 or die;
    my $temp = $_[0];
    my $check= chop $temp; # on enlève 8 bit de la fin du message
    $check = chop($temp).$check; # on enlève encore 8bits et on y concatène les 8bits précédents pour donc retrouver les 16bits de fin du message
    $check = unpack "B*", $check;

#    print $temp." > ".unpack("B16",Digest::CRC::crc16($temp))." ?= ".$check."\n";

    return ($check eq unpack("B16",Digest::CRC::crc16($temp)));
}


sub decodage {
    @_ == 1 or die;
    my ($code) = unpack "B24",$_[0]; # on créer la chaîne qui représente la valeur binaire du message
    $code = pack "B8", $code; # récupération de la partie utile du message qui ne sont que les 8 premiers bits
#    print "decoder : ".$code."\n";
    return $code;
}

1;
