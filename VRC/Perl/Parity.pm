use strict;
use warnings;

package Parity;

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
