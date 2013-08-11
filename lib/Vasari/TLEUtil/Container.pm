package Vasari::TLEUtil::Container;

use v5.10;
use strict;
use warnings;

use Moose;
use Bread::Board;

use DBI;
use Getopt::Long (qw(GetOptions));
use YAML::XS (qw(LoadFile));
use Games::Lacuna::Client;

## An object used as a container must inherit from Bread::Board::Container.
use MooseX::NonMoose; ## Use this to properly inherit from a Non-Moose module.
extends 'Bread::Board::Container';

sub BUILD {
    my ($self) = @_;

    container $self => as {

        ## Database stuff
        service 'db' => (
            class => 'DBI',
            dependencies => {
                config => depends_on('config'),
            },
            block => sub {
                my $self = shift;

                return DBI->connect('DBI:SQLite:dbname='.$self->param('config')->{db_file})
                    or die DBI->errstr;
            },
        );

        ## Configuration file
        service 'config' =>  (
            block => sub {
                my $self = shift;

                my $config = LoadFile('config.yml');
                GetOptions(
                    "debug" => \$config->{debug},
                );

                return $config // {};
            },
        );

        ## Core stuff
        service 'core' => (
            class     => 'Vasari::TLEUtil::Core',
            lifecycle => 'Singleton',
            dependencies => {
                ## Should already be initialized.
                glc    => depends_on('glc'),
                config => depends_on('config'),
            },
            block     => sub {
                my $self = shift;
                my $core = Vasari::TLEUtil::Core->new(
                    glc    => $self->param('glc'),
                    config => $self->param('config'),
                );
                return $core;
            },
        );

        ## Games::Lacuna::Client stuff
        service 'glc' => (
            class        => 'Games::Lacuna::Client',
            lifecycle    => 'Singleton',
            dependencies => {
                config => depends_on('config'),
            },
            block => sub {
                my $self = shift;

                my $glc = Games::Lacuna::Client->new(
                    name      => $self->param('config')->{empire_name},
                    password  => $self->param('config')->{empire_pass},
                    uri       => $self->param('config')->{server_url},
                    api_key   => 'anonymous',
                );

                $glc = Vasari::TLEUtil::Core->innit_glc($glc);
                return $glc;
            },
        );
    };

    return $self;
}

no Moose;
no Bread::Board;
__PACKAGE__->meta->make_immutable;
1;
