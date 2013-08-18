package Vasari::TLEUtil;

use v5.10;
use strict;
use warnings;

use Moose;
use Data::Dumper;

use Vasari::TLEUtil::Container;
use Vasari::TLEUtil::Task::ExcavatorManager;
use Vasari::TLEUtil::Task::SSManager;

our $VERSION = "0.0.1";
my @available_tasks = [
    'excavator_manager',
    'ss_manager',
];

has 'task'   => (is => 'rw', isa => 'Str', required => 1);
has 'bb'     => (is => 'rw', isa => 'Vasari::TLEUtil::Container', lazy_build => 1);

sub run {
    my $self = shift;

    ## Before we do anything, lets check that the task provided is valid!
    if (not $self->task ~~ @available_tasks) {
        die 'Bad task.';
    }

    my $config = $self->bb->resolve(service => 'config');
    my $glc    = $self->bb->resolve(service => 'glc');

    ## Once we have all that, move on...
    say 'Running the ' . $self->task . ' task.';
    
    ## Not sure if there's a cleaner way to do this, but it works! :D
    ## I think something like this should work, but I'm missing something...
    ## $self->{$self->task}();
    my $task = $self->task;
    $self->$task();

    if ($config->{debug}) {
        say 'Task complete, made the following server calls:';
        say Dumper $glc->{call_stats};
    }
}

sub excavator_manager {
    my $self = shift;
    Vasari::TLEUtil::Task::ExcavatorManager->new(bb => $self->bb)->run;
}

sub ss_manager {
    my $self = shift;
    Vasari::TLEUtil::Task::SSManager->new(bb => $self->bb)->run;
}

sub _build_bb {
    my $self = shift;

    return Vasari::TLEUtil::Container->new(
        ## Just the Bread::Board app name, nothing I care about. ;)
        name => 'App',
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
