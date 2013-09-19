package Vasari::TLEUtil::Task::ExcavatorManager;

use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Moose;

has 'config' => (is => 'ro', isa => 'HashRef',               required => 1);
has 'db'     => (is => 'ro',                                 required => 1);
has 'glc'    => (is => 'ro', isa => 'Games::Lacuna::Client', required => 1);
has 'core'   => (is => 'ro', isa => 'Vasari::TLEUtil::Core', required => 1);

sub run {
    my $self = shift;


=head2

        This small piece of code is a placeholder for a script the will exist
        in the future sometime. However, there are more pressing matters at 
        hand and such, I will not be continuing this part of the code for 
        some time.



    say 'Starting to do something in the new task';

    foreach my $planet (@{$self->colonies}) {
        say $planet->{name};
    }
=cut

    say 'Heya, I\'m working now!';
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
