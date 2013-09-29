package Vasari::TLEUtil::Task::BuildingsUpgrader;

use strict;
use warnings;
use v5.10;

use Moose;

has 'glc'        => (is => 'ro', isa => 'Games::Lacuna::Client', required => 1);
has 'config'     => (is => 'ro', isa => 'HashRef',               required => 1);
has 'core'       => (is => 'ro', isa => 'Vasari::TLEUtil::Core', required => 1);
has 'build_list' => (is => 'ro', isa => 'HashRef',               lazy_build => 1);

sub run {
    say 'test';
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
            level => 25,
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
            level => 20,
        },
        {
            name  => 'Subspace Transporter',
            level => 20,
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
            level => 25,
        },
        {
            name  => 'Propulsion System Factory',
            level => 20,
        },
        {
            name  => 'Cloaking Lab',
            level => 20,
        },
        {
            name  => 'Observatory',
            level => 20,
        },
        {
            name  => 'Terraforming Lab',
            level => 20,
        },
        {
            name  => 'Gas Giant Lab',
            level => 20,
        },
        {
            name  => 'Pilot Training Facility',
            level => 20,
        },
        {
            name  => 'Munitions Lab',
            level => 20,
        },
        {
            name  => 'Embassy',
            level => 20,
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
            level => 25,
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
