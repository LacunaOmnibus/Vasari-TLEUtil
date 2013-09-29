package Vasari::TLEUtil::Task::BuildingsUpgrader;

use strict;
use warnings;
use v5.10;

use Moose;
use Data::Dumper;

use Text::SimpleTable::AutoWidth;
use Try::Tiny;

has 'glc'        => (is => 'ro', isa => 'Games::Lacuna::Client', required => 1);
has 'config'     => (is => 'ro', isa => 'HashRef',               required => 1);
has 'core'       => (is => 'ro', isa => 'Vasari::TLEUtil::Core', required => 1);
has 'build_list' => (is => 'ro', isa => 'ArrayRef',              lazy_build => 1);

sub run {
    my $self = shift;
    
    ## List of all the building upgrades that go through successfully.
    ## Used to draw a fancy table of what happened at the end of the script.
    my %buildings_upgraded = ();
    
    PLANET:
    foreach my $planet (@{$self->core->colonies}) {
        
        ## Skip planets that should be skipped.
        if ($planet->{name} ~~ @{$self->config->{buildings_upgrader}->{skip_bodies}}) {
            next PLANET;
        }

        say '';
        say "Looking at $planet->{name}.";
        
        ## Get the buildings on the current planet.
        my $buildings = $self->core->buildings($planet->{id});
        
        BUILDING_PRIORITY:
        foreach my $to_build (@{$self->build_list}) {
            my $name  = $to_build->{name};
            my $level = $to_build->{level};
            
            my $to_check_for_upgrade = $self->core->extract_all_matching_buildings($buildings, $name);
            
            if ($to_check_for_upgrade) {

                ## So now we check each building and if it can be upgraded,
                ## within the constraints of the config, then do so!
                BUILD_TO_CHECK:
                foreach my $build (@$to_check_for_upgrade) {
                    if ($build->{pending_build}) {
                        next BUILD_TO_CHECK;
                    }
                    elsif ($build->{level} <= $level - 1) {
                        my $upgrade_level = $build->{level} + 1;
                        say "Upgrading the $name on $planet->{name} to $upgrade_level!!";
                        
                        if (not $self->config->{dry_run}) {
                            
                            ## Every building type is the same as the URL - minus the
                            ## leading slash.
                            my $type             = $build->{url} =~ s/\///r; #/
                            my $build_to_execute = $self->glc->building(id => $build->{id}, type => $type);
                        
                            ## I love being able to do this. Try::Tiny ftw!
                            my $build_response = try {
                                my $rv = $build_to_execute->upgrade();
                                
                                ## Log the building that was upgraded for later output.
                                $buildings_upgraded{$build->{id}} = $build;
                                
                                return $rv;
                            }
                            catch {
                                ## An error was thrown and we need to decide what to do with it.
                                if (m/there's no room left in the build queue/i) {
                                    say "The build queue on $planet->{name} is full!";
                                    
                                    return;
                                }
                                elsif (m/you must repair this building before you can upgrade it/i) {
                                    say "There are damaged buildings on $planet->{name}!!";
                                    
                                    return; ## Skip the entire planet to save RPCs.
                                }
                                else {
                                    ## Hopefully I see this and add handling for it.
                                    say;
                                    return 1;
                                }
                            };
                            
                            next PLANET unless($build_response);
                        }
                    }
                }
            }
        }
    }
    
    if (not $self->config->{dry_run}) {
        ## Draw a pretty lookin' table of the buildings that were upgraded.
        my @upgraded_building_ids = keys %buildings_upgraded;
        
        my $table = Text::SimpleTable::AutoWidth->new();
        $table->captions(['Building', 'Level']);

        foreach (@upgraded_building_ids) {
            $table->row($buildings_upgraded{$_}->{name}, $buildings_upgraded{$_}->{level} + 1);
        }

        $table->row('TOTAL', scalar @upgraded_building_ids);

        print "\n\n". $table->draw ."\n\n";
    }
}

sub _build_build_list {
    return [

        #####################
        ### Essentials!!! ###
        #####################
        
        {
            name  => 'Oversight Ministry',
            level => 30,
        },
        {
            name  => 'Archaeology Ministry',
            level => 30,
        },
        {
            name  => 'Development Ministry',
            level => 30,
        },
        {
            name  => 'Food Reserve',
            level => 30,
        },
        {
            name  => 'Ore Storage Tanks',
            level => 30,
        },
        {
            name  => 'Water Storage Tank',
            level => 30,
        },
        {
            name  => 'Energy Reserve',
            level => 30,
        },
        {
            name  => 'Planetary Command Center',
            level => 30,
        },
        {
            name  => 'Trade Ministry',
            level => 30,
        },
        {
            name  => 'Subspace Transporter',
            level => 30,
        },
        
        #########################
        ### Space Station Lab ###
        #########################
        
        {
            name  => 'Space Station Lab (A)',
            level => 25,
        },
        {
            name  => 'Space Station Lab (B)',
            level => 25,
        },
        {
            name  => 'Space Station Lab (C)',
            level => 25,
        },
        {
            name  => 'Space Station Lab (D)',
            level => 25,
        },
        
        #################
        ### Tyleon!!! ###
        #################
        
        {
            name  => 'Lost City of Tyleon (A)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (B)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (C)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (D)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (E)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (F)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (G)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (H)',
            level => 30,
        },
        {
            name  => 'Lost City of Tyleon (I)',
            level => 30,
        },
        
        ################
        ### Spies!!! ###
        ################
        
        {
            name  => 'Intelligence Ministry',
            level => 30,
        },
        {
            name  => 'Security Ministry',
            level => 30,
        },
        {
            name  => 'Espionage Ministry',
            level => 30,
        },
        {
            name  => 'Intel Training',
            level => 30,
        },
        {
            name  => 'Mayhem Training',
            level => 30,
        },
        {
            name  => 'Politics Training',
            level => 30,
        },
        {
            name  => 'Theft Training',
            level => 30,
        },
        
        ################
        ### Ships!!! ###
        ################
        
        {
            name  => 'Shipyard',
            level => 30,
        },
        {
            name  => 'Propulsion System Factory',
            level => 30,
        },
        {
            name  => 'Cloaking Lab',
            level => 30,
        },
        {
            name  => 'Observatory',
            level => 30,
        },
        {
            name  => 'Terraforming Lab',
            level => 30,
        },
        {
            name  => 'Gas Giant Lab',
            level => 30,
        },
        {
            name  => 'Pilot Training Facility',
            level => 30,
        },
        {
            name  => 'Munitions Lab',
            level => 30,
        },
        {
            name  => 'Embassy',
            level => 30,
        },
        {
            name  => 'Waste Sequestration Well',
            level => 30,
        },
        
        #######################
        ### All The Rest!!! ###
        #######################
        
        {
            name  => 'Shield Against Weapons',
            level => 30,
        },
        {
            name => 'Mission Command',
            level => 30,
        },
        {
            name  => 'Space Port',
            level => 28,
        },
    ];
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
