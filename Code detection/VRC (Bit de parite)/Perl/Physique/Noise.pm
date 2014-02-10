#==============================================
# Bibliothèque Physique::Noise
#==============================================
# Matière : Réseau S2
#==============================================
# Fonction : simule des perturbations sur un caractère qui
# serait transmis via un réseau bruité.
#==============================================

package Physique::Noise;

our $FIABILITY = 80; # 80% de bon

sub transmettre {
    @_ == 1 or die __PACKAGE__."::transmettre: nombre de paramètres invalide\n";
    my ($car) = @_;
    length $car == 1 or die __PACKAGE__ . "::transmettre: \"$car\" n'est pas un caractere\n";
    defined $FIABILITY or return $car;
    $car = ord($car);
    
    my $fiab_bit = sqrt(sqrt($FIABILITY/100));
    ($fiab_bit >= 0.5 && $fiab_bit <= 1) or die __PACKAGE__."::transmettre: $FIABILITY n'est pas une fiabilité valide\n";

    foreach my $sh (0, 2, 4, 6) {
        if(rand(1) > $fiab_bit) {
            $car = $car ^ (1 << $sh);   
        }
    }
    return chr($car);
}

1;
