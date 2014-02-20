#==============================================
# Bibliothèque Physique::LinkUDP
#==============================================
# Matière : Réseau S2
#==============================================
# usage :
#   use Physique::LinkUDP;
#   # use Physique::Debug;
#   # use Physique::Noise;
#   ...
#   my $link = open(8000,"localhost:8001");
#   envoiCar($link,'Z');
#   close($link);
#   ...
#   my $link = open(9000,"192.168.5.123:9000");
#   my $car = recoitCar($link);
#   close($link);
#
#==============================================
use strict;
use warnings;

package Physique::LinkUDP ;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(P_open P_envoiCar P_recoitCar P_recoitCarAsynchrone P_close);

use IO::Socket;
use IO::Select;

#%.P_open
#%* Fonction : "branche" un lien "physique" (simulé à l'aide du protocole UDP) sur un port UDP
#%             de votre machine et associe l'autre "extrémité" du lien à UDP d'une machine donnée.
#%* Paramètre 1 : le numéro du port UDP à ouvrir localement
#%* Paramètre 2 : l'adresse et le port UDP de l'autre extrémité au format "machine:port" où
#%                machine est le nom ou l'adresse IP d'une machine.
#%* Valeur de retour : une valeur symbolisant le lien (requis pour les fonctions suivantes)
#%* Précondition : le port UDP local ne doit être utilisé par un autre programme
#%* Exemple : ++my $link = P_open(9000,"192.168.5.22:8000");++
#%
sub P_open {
    # Vérification de la validité des paramètres
    @_ == 2 or die __PACKAGE__."::P_open: nombre de paramètres invalides (".@_.")\n";
    my ($localPort,$peer) = @_;
    my ($peerIP,$peerPort) = $peer =~ /(.*):(.*)/ or die __PACKAGE__."::P_open: \"$peer\" n'est pas de la forme adresseIP:portUDP\n";
    debug("P_open","Must listen on UDP port $localPort, must send UDP packets to $peerIP:$peerPort");

    # Création d'un socket UDP
    my $sock = IO::Socket::INET->new (Proto     => 'udp',
                                      Type      => SOCK_DGRAM,
                                      LocalPort => $localPort,
                                      PeerAddr  => "$peerIP:$peerPort",
                                      Reuse     => 1)
        or die __PACKAGE__ . "::P_open: erreur à la création du socket UDP ($localPort <-> $peerIP:$peerPort) : $!\n" ;
    debug("P_open","Created socket listening on port ".$sock->sockport()." sending to ".$sock->peerhost().":".$sock->peerport());

    # Renvoie le socket créé
    return $sock;
}

#%.P_close
#%* Fonction : "débranche" un lien "physique"
#%* Paramètre : le lien physique à débrancher
#%* Valeur de retour : aucune
#%* Exemple : ++P_close($link);++
#%
sub P_close {
    @_ == 1 or die __PACKAGE__."::P_close: nombre de paramètres invalide (".@_.")\n";
    defined $_[0] or die __PACKAGE__."::P_close: lien non défini\n";

    # On cesse d'écouter et on renonce à envoyer
    close $_[0] or die __PACKAGE__."::P_close: erreur à la fermeture du lien";
    $_[0] = undef;
    debug("P_close","Socket closed");

    return;
}

#%.P_envoiCar
#%* Fonction : envoie un caractère sur un lien physique
#%* Paramètre 1 : le lien physique
#%* Paramètre 2 : le caractère à envoyer, sous la forme d'une chaîne de 1 caractère
#%* Valeur de retour : faux indique une erreur détectée 
#%* Exemple : ++P_envoiCar($link,"A");++
#%
sub P_envoiCar {
    @_ == 2 or die __PACKAGE__."::P_envoiCar: nombre de paramètres invalide (".@_.")\n";
    my($sock,$car) = @_;
    defined $sock or die __PACKAGE__."::P_envoiCar: lien non défini\n";
    (defined $car and length $car == 1) or die __PACKAGE__ . "::P_envoiCar: \"$car\" n'est pas un caractere\n";
    my $car0 = $car;

    if (defined $Physique::Noise::FIABILITY) {
	$car = Physique::Noise::transmettre($car);
    }
    # On envoie un caractère sur le socket d'émission
    if($sock->send ($car,0)) {
	debug("P_envoiCar","Character \"".$car.($car eq $car0?"":" (instead of $car0)")
	      ."\" sent to ".$sock->peerhost().":".$sock->peerport());
	return 1;
    } else {
	my $err = $!;
	debug("P_envoiCar","Failed to send character \"".$car0."\" to ".$sock->peerhost().":".$sock->peerport()." ($err)");
	return 0;
    }
}

#%.P_recoitCar
#%* Fonctionr : récupère un caractère reçu sur un lien physique. Les caractères sont fournis
#%              dans leur ordre d'arrivé. Au besoin, la procédure attend l'arrivé d'un caractère.
#%* Paramètre : le lien physique
#%* Valeur de retour : le caractère reçu
#%* Exemple : ++my $c = P_recoitCar($link);++
#%
sub P_recoitCar {
    @_ == 1 or die __PACKAGE__."::P_recoitCar: nombre de paramètres invalide (".@_.")\n";
    my ($sock) = @_;
    defined $sock or die __PACKAGE__."::P_recoitCar: lien non défini\n";
    my ($car) = (undef);

    # On attend un caractère sur le socket de réception
    debug("P_recoitCar","Looking for a frame on port ".$sock->sockport());
    my $client = $sock->recv ($car, 1, 0);
    debug_recv("P_recoitCar",$client,$sock,$car);

    # Retourne le premier caractère de la trame
    return substr($car,0,1);
}

#%.P_recoitCarAsynchrone
#%* Fonction : récupère un caractère déjà reçu sur un lien physique. Les caractères sont
#%             fournis dans leur ordre d'arrivé. La procédure rend la main si aucun
#%             caractère n'est disponible dans un bref délai.
#%* Paramètre : le lien physique
#%* Valeur de retour : le caractère reçu ou undef en l'absence de caractère
#%* Exemple : ++if(my $c = P_recoitCarAsynchrone($link)) { ... }++
#%
sub P_recoitCarAsynchrone {
    @_ == 1 or die __PACKAGE__."::P_recoitCarAsynchrone: nombre de paramètres invalide (".@_.")\n";
    my ($sock) = @_;
    defined $sock or die __PACKAGE__."::P_recoitCarAsynchrone: lien non défini\n";

    # On regarde s'il y a de l'information sur le socket de réception
    # On attend au besoin 0,1 secondes
    my $select = IO::Select->new($sock);
    if ( $select->can_read(0.1) ){

        # De l'information est présente : on la lit
        my $client = $sock->recv (my $car, 1, 0);
        debug_recv("P_recoitCarAsynchrone",$client,$sock,$car);

        # Retourne le premier caractère de la trame
        return substr($car,0,1);
    } else {
        debug_no_recv("P_recoitCarAsynchrone",$sock);

        # Retourne la valeur indéfinie
        return undef;
    }
}

# Formattage et affichage de message de débogage
sub debug {
    if ($Physique::Debug::DEBUG) {
        my ($fn,$msg) = @_;
        print STDERR "[".__PACKAGE__."::$fn] $msg\n";
    }
}

# Débogage pour la reception d'un caractère
sub debug_recv {
    if ($Physique::Debug::DEBUG) {
        my($fun,$client,$sock,$car) = @_;
        if (defined $client) {
            my ($client_port, $client_addr) =  unpack_sockaddr_in ($client);
            my $ip_addr = inet_ntoa($client_addr);
            debug($fun, "Character \"$car\" received on port ".$sock->sockport()." from $ip_addr:$client_port");
        } else {
            debug($fun, "Character \"$car\" received on port ".$sock->sockport()." from an unknown source");
        }
    }
}

# Débogage en cas d'absence de caractère disponible
sub debug_no_recv {
    if ($Physique::Debug::DEBUG) {
        my ($fun,$sock) = @_;
        my ($sec,$min,$hour) = localtime(time());
        my $dtime = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
        debug($fun,"No character available on port ".$sock->sockport()." at $dtime");
    }
}

1;
