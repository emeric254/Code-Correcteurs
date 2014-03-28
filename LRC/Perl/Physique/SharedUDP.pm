#==============================================
# Bibliothèque Physique::SharedUDP
#==============================================
# Matière : Réseau S2
#==============================================
# usage :
#   use Physique::SharedUDP;
#   # use Physique::Debug;
#   ...
#   my $medium = open(8000,"192.168.5.255");
#   envoiCar($medium,'Z');
#   close($medium);
#   ...
#   my $medium = open(9000,"255.255.255.255");
#   my $car = recoitCar($medium);
#   close($medium);
#
#==============================================
use strict;
use warnings;

package Physique::SharedUDP ;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(P_open P_envoiCar P_recoitCar P_recoitCarAsynchrone P_close);

use IO::Socket;
use IO::Select;

#%.P_open
#%* Fonction : "connecte" un port UDP local à un support "physique" partagé (simulé par la
#%             protocole UDP). Ce support partagé est identifié par une adresse IP de diffusion
#%             et par le port UDP utilisé.
#%* Paramètre 1 : le numéro du port UDP
#%* Paramètre 2 : une adresse IP de diffusion d'une de vos interfaces réseaux ou l'adresse IP de
#%                diffusion limitée ("255.255.255.255") sous la forme d'une chaîne de caractères.
#%* Valeur de retour : une valeur symbolisant le support (requis pour les fonctions suivantes)
#%* Note : le port UDP peut être déjà utilisé. Ceci permet la communication d'une machine à elle-même.
#%* Exemple : ++my $medium = P_open(7000,"192.168.5.255");++
#%
sub P_open {
    # Vérification de la validité des paramètres
    @_ == 2 or die __PACKAGE__."::P_open: nombre de paramètres invalides (".@_.")\n";
    my ($port,$bc) = @_;
    $bc = "255.255.255.255" if not defined $bc;
    debug("P_open","Must listen on port $port for UDP packets addressed to $bc");
    debug("P_open","Must send by UDP broadcast to $bc:$port");

    # Création d'un socket pour la réception
    my $sock = IO::Socket::INET->new (Proto     => 'udp',
                                      Type      => SOCK_DGRAM,
                                      LocalAddr => $bc,
                                      LocalPort => $port,
                                      Broadcast => 1,
                                      ReuseAddr => 1)
        or die __PACKAGE__ . "::P_open: erreur à la création du socket diffusion UDP sur le port $port : $!\n" ;
    debug("P_open","Created socket listening on port ".$sock->sockport().", accepting broadcast");

    # Renvoie une référence vers la paire (socket, adresse de diffusion)
    my @medium = ($sock,pack_sockaddr_in ($port, inet_aton ($bc)));
    return \@medium;
}

#%.P_close
#%* Fonction : se "déconnecte" du support "physique"
#%* Paramètre : le support physique à débrancher
#%* Valeur de retour : aucune
#%* Exemple : ++P_close($medium);++
#%
sub P_close {
    @_ == 1 or die __PACKAGE__."::P_close: nombre de paramètres invalide (".@_.")\n";
    my ($medium) = @_;
    defined $medium or die __PACKAGE__."::P_close: support fermé ou non défini\n";
    my $sock = @$medium[0];

    # On cesse d'écouter
    close $sock or die __PACKAGE__."::P_close: erreur à la fermeture du socket";
    $_[0] = undef;
    debug("P_close","Socket closed");

    return;
}

#%.P_envoiCar
#%* Fonction : envoie un caractère sur un support physique
#%* Paramètre 1 : le support physique
#%* Paramètre 2 : le caractère à envoyer, sous la forme d'une chaîne de 1 caractère
#%* Valeur de retour : aucune
#%* Exemple : ++P_envoiCar($medium,"X");++
#%
sub P_envoiCar {
    @_ == 2 or die __PACKAGE__."::P_envoiCar: nombre de paramètres invalide (".@_.")\n";
    my($medium,$car) = @_;
    defined $medium or die __PACKAGE__."::P_envoiCar: support fermé ou non défini\n";

    my($sock,$dest) = @$medium;
    (defined $car and length $car == 1) or die __PACKAGE__ . "::P_envoiCar: \"$car\" n'est pas un caractere\n";

    # On envoie un caractère sur le socket d'émission
    $sock->send ($car,0,$dest) or die __PACKAGE__ . "::P_envoiCar: Erreur a l'emission de \"$car\" : $!\n";
    debug_send("P_envoiCar",$car,$dest);

    return;
}

#%.P_recoitCar
#%* Fonction : récupère un caractère reçu sur un support physique. Les caractères sont fournis
#%             dans leur ordre d'arrivé. Au besoin, la procédure attend l'arrivé d'un caractère.
#%* Paramètre : le support physique
#%* Valeur de retour : le caractère reçu
#%* Exemple : ++my $c = P_recoitCar($medium);++
#%
sub P_recoitCar {
    @_ == 1 or die __PACKAGE__."::P_recoitCar: nombre de paramètres invalide (".@_.")\n";
    my ($medium) = @_;
    defined $medium or die __PACKAGE__."::P_recoitCar: support fermé ou non défini\n";
    my $sock = @$medium[0];
    my ($car) = (undef);

    # On attend un caractère sur le socket de réception
    debug("P_recoitCar","Looking for a frame on port ".$sock->sockport());
    my $client = $sock->recv ($car, 1, 0);
    debug_recv("P_recoitCar",$client,$sock,$car);

    # Retourne le premier caractère de la trame
    return substr($car,0,1);
}

#%.P_recoitCarAsynchrone
#%* Fonction : récupère un caractère déjà reçu sur un support physique. Les caractères sont
#%             fournis dans leur ordre d'arrivé. La procédure rend la main si aucun
#%             caractère n'est disponible dans un bref délai.
#%* Paramètre : le support physique
#%* Valeur de retour : le caractère reçu ou undef en l'absence de caractère
#%* Exemple : ++if(my $c = P_recoitCarAsynchrone($medium)) { ... }++
#%
sub P_recoitCarAsynchrone {
    @_ == 1 or die __PACKAGE__."::P_recoitCarAsynchrone: nombre de paramètres invalide (".@_.")\n";
    my ($medium) = @_;
    defined $medium or die __PACKAGE__."::P_recoitCarAsynchrone: support fermé ou non défini\n";
    my $sock = @$medium[0];

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

# Formatage et affichage de message de debogage
sub debug {
    if ($Physique::Debug::DEBUG) {
        my ($fn,$msg) = @_;
        print STDERR "[".__PACKAGE__."::$fn] $msg\n";
    }
}

# Débogage pour l'envoi d'un caractère
sub debug_send {
    if ($Physique::Debug::DEBUG) {
        my ($fun,$car,$dest) = @_;
        my ($port,$ip) = unpack_sockaddr_in $dest;
        $ip = inet_ntoa $ip;
        debug($fun,"Character \"$car\" sent to $ip:$port");
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
