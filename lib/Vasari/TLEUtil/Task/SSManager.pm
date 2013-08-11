package Vasari::TLEUtil::Task::SSManager;

use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Moose;

has 'bb' => (is => 'rw', isa => 'Vasari::TLEUtil::Container', required => 1);

sub run {
    my $self = shift;

    my $glc  = $self->bb->resolve(service => 'glc');
    my $core = $self->bb->resolve(service => 'core');

    foreach my $ss (@{$core->stations}) {
        say $ss->{name};
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
