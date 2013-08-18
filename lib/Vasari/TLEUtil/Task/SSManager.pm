package Vasari::TLEUtil::Task::SSManager;

use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Moose;

has 'bb' => (is => 'rw', isa => 'Vasari::TLEUtil::Container', required => 1);

my $upgrade_modules = [
    'Station Command Center',
    'Parliament',
    'Interstellar Broadcast System',
    'Police Station',
    'Culinary Institute',
    'Art Museum',
    'Opera House',
#    'Warehouse', # I prefer to leave the Warehouse up to the station owner.
];

## The level we want to get all the SS modules to.
## For the moment, 20 is high enough as it is the level we can do all the
## Parliament actions except for firing the BFG. Which us, being PSoA, is
## not exactly very important for us. (I love being peaceful...)
my $wanted_level = 20;

## The score we want all stations to get up to.
my $wanted_score = $wanted_level * scalar $upgrade_modules;

sub run {
    my $self = shift;

    my $glc  = $self->bb->resolve(service => 'glc');
    my $core = $self->bb->resolve(service => 'core');

    my $to_work_on = [];

    foreach my $ss (@{$core->stations}) {
        my $buildings = $core->buildings($ss->{id});
        my $score = $self->rate_ss($buildings);

        if ($score >= $wanted_score) {
            say $ss->{name} . ' is finished!';
        }
        else {
            $ss->{buildings} = $buildings; ## Save a few RPCs.
            push @$to_work_on, $ss;
        }

        last;
    }

    ## Now that we have a list of stations that need work, let's get to it!
    say 'Working on ' . scalar @$to_work_on . ' Space Station(s).';
    $self->work($to_work_on);
}

sub work {
    my $self           = shift;
    my $space_stations = shift; ## Calling it $sss doesn't make much sense without the '

    foreach my $ss (@$space_stations) {

        ## So now we are left with the task of working out what modules need
        ## upgrading.
        foreach my $module (@{$ss->{buildings}}) {

            if ($module->{name} ~~ @$upgrade_modules) {

                ## Do stuff


            }
        }
    }
}

sub rate_ss {
    my $self      = shift;
    my $buildings = shift;
    
    my $core = $self->bb->resolve(service => 'core');

    my $score = 0;

    foreach my $module (@$modules) {
        my $building = $core->extract_building($buildings, $module);
        
        if ($building) {
            $score += $building->{level};
        }
    }

    return $score;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
