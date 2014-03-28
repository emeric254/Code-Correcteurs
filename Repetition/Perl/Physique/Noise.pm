#==============================================
# Bibliothèque Physique::Noise
#==============================================
# Matière : Réseau S2
#==============================================
# Fonction : simule des perturbations sur un caractère qui
# serait transmis via un réseau bruité.
#==============================================

package Physique::Noise;

our $FIABILITY = 90; # 10% d'erreur

sub transmettre {
    @_ == 1 or die __PACKAGE__."::transmettre: nombre de paramètres invalide\n";
    my ($car) = @_;
    defined $FIABILITY or return $car;
    
    my $fiab_bit = ($FIABILITY/100);
    ($fiab_bit >= 0.1 && $fiab_bit <= 1) or die __PACKAGE__."::transmettre: $FIABILITY n'est pas une fiabilité valide\n";

    foreach my $sh (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15) {
        if(rand(1) > $fiab_bit) {
            $car = $car ^ (1 << $sh);   
        }
    }
    return $car;
}

1;
