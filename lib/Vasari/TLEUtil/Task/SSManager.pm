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

    my $glc  = $self->bb->resolve(service => 'glc');
    my $core = $self->bb->resolve(service => 'core');

    ## Array of _all_ upgrades that would need to happen to max out
    ## $upgrade_modules on each Space Station to $wanted_level.
    my $upgrades = [];

    foreach my $ss (@$space_stations) {
        ## So now we are left with the task of working out what modules need
        ## upgrading.

        ## Get the plans on the station so we can predict (before making the 
        ## rpc request) weather the upgrade will happen or not.
        my $pcc      = $core->extract_building($ss->{buildings}, 'Station Command Center');
        my $pcc_obj  = $glc->building(id => $pcc->{id}, type => 'StationCommand');
        $ss->{plans} = $pcc_obj->view_plans->{plans};
        
        foreach my $id (keys %{$ss->{buildings}}) {
            my $module = $ss->{buildings}->{$id};

            if ($module->{name} ~~ @$upgrade_modules and
                $module->{level} < $wanted_level) {

                ## Now check if we can upgrade it now or need to take further
                ## action to get the plan into existence and then upgrade.
                ## This is where this process gets very interesting...
                if (grep {$_->{level} == $module->{level} + 1 and $_->{name} eq $module->{name}} @{$ss->{plans}}) {
                    ## Do the upgrade.
                    say Dumper $module;
                }
                else {
                    ## This is what needs to happen:
                    ## - Check if the plan has been made on a planet somewhere.
                    ##     - If so, move it for the next upgrade run.
                    ##     - If not, 
                    ##         - Find a viable planet to make it on, make, send to db.
                    ##         - Next run we find the plan and move it.
                    ##         - Then finally, the above code hits the upgrade button.
                    ## - If all else fails, log in the db that we attempted to make the plan,
                    ##   but failed for various reasons.
                    ##     - Need a script to check this part of the db and attempt to remake
                    ##       the plan at a later date.
                }
            }
        }
    }
}

sub rate_ss {
    my $self      = shift;
    my $buildings = shift;
    
    my $core  = $self->bb->resolve(service => 'core');
    my $score = 0;

    foreach my $module_name (@$upgrade_modules) {
        my $module = $core->extract_building($buildings, $module_name);
        
        if ($module) {
            $score += $module->{level};
        }
    }

    return $score;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
