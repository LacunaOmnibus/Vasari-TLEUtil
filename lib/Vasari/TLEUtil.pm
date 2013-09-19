package Vasari::TLEUtil;

use v5.10;
use strict;
use warnings;

use Moose;
use Data::Dumper;

use Vasari::TLEUtil::Core;
use Vasari::TLEUtil::Task::ExcavatorManager;
use Vasari::TLEUtil::Task::SSManager;

use DBI;
use Getopt::Long (qw(GetOptions));
use YAML::XS (qw(LoadFile));
use Games::Lacuna::Client;

our $VERSION = "0.0.1";

my @available_tasks = [
    'excavator_manager',
    'ss_manager',
];

has 'task'   => (is => 'rw', isa => 'Str', required => 1);

# Build a bunch of things we need.
has 'config' => (is => 'rw', isa => 'HashRef',               lazy_build => 1);
has 'db'     => (is => 'ro',                                 lazy_build => 1);
has 'glc'    => (is => 'ro', isa => 'Games::Lacuna::Client', lazy_build => 1);
has 'core'   => (is => 'ro', isa => 'Vasari::TLEUtil::Core', lazy_build => 1);

sub run {
    my $self = shift;

    ## Before we do anything, lets check that the task provided is valid!
    if (not $self->task ~~ @available_tasks) {
        die 'Bad task.';
    }

    ## Once we have all that, move on...
    say 'Running the ' . $self->task . ' task.';
    
    ## TODO: measure run time of the task!

    ## Not sure if there's a cleaner way to do this, but it works! :D
    ## I think something like this should work, but I'm missing something...
    ## $self->{$self->task}();
    my $task = $self->task;
    $self->$task();
}

sub excavator_manager {
    my $self = shift;
    my $task = Vasari::TLEUtil::Task::ExcavatorManager->new(
        db     => $self->db,
        glc    => $self->glc,
        config => $self->config,
        core   => $self->core,
    );
    $task->run;
}

sub ss_manager {
    my $self = shift;
    my $task = Vasari::TLEUtil::Task::SSManager->new(
        
    );
    $task->run;
}

sub _build_config {
    my $self = shift;

    my $config = LoadFile('config.yml');
    
    GetOptions(
        "debug" => \$config->{debug},
    );

    return $config;
}

sub _build_db {
    my $self = shift;

    return DBI->connect('DBI:SQLite:dbname='.$self->config->{db_file}) or die DBI->errstr;
}

sub _build_glc {
    my $self = shift;

    return Games::Lacuna::Client->new(
        name      => $self->config->{empire_name},
        password  => $self->config->{empire_pass},
        uri       => $self->config->{server_url},
        api_key   => $self->config->{api_key} || 'anonymous',
    );
}

sub _build_core {
    my $self = shift;

    return Vasari::TLEUtil::Core->new(
        glc    => $self->glc,
        config => $self->config
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
