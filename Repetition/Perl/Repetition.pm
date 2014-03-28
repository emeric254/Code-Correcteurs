use strict;
use warnings;

package Repetition;

our $nbrRepetition = 2;

sub codage {
    @_ == 1 or die;
    my ($code) = @_;
    $code = $code x $nbrRepetition;
    return $code;
}

sub verification {
    @_ == 1 or die;
    my ($code) = @_;
    my $chaine1 = substr($code,0,length($code)/$nbrRepetition);
    my $chaine2 = substr($code,length($code)/$nbrRepetition);
    return $chaine1 eq $chaine2;
}

sub decodage {
    @_ == 1 or die;
    my ($code) = @_;
    return substr($code,length($code)/$nbrRepetition);
}

1;
