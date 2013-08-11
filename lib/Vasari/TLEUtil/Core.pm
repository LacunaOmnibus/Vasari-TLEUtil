package Vasari::TLEUtil::Core;

use strict;
use warnings;
use v5.10;

use Data::Dumper;

use Moose;

has 'glc'    => (is => 'rw', isa => 'Games::Lacuna::Client', required => 1);
has 'config' => (is => 'rw', isa => 'HashRef',               required => 1);

sub colonies {
    my $self = shift;
    return $self->status->{empire}->{colonies} if (defined $self->status->{empire}->{colonies});
    $self->get_bodies;
    return $self->status->{empire}->{colonies} // [];
}

sub stations {
    my $self = shift;
    return $self->status->{empire}->{stations} if (defined $self->status->{empire}->{stations});
    $self->get_bodies;
    return $self->status->{empire}->{stations} // [];
}

sub bodies {
    my $self = shift;
    return $self->status->{empire}->{planets} if (defined $self->status->{empire}->{planets});
    $self->get_bodies;
    return $self->status->{empire}->{planets} // [];
}

sub get_bodies {
    my $self = shift;

    ## There should already be a status, created when glc was built.
    ## If there isn't something stupid has happened.
    return {} if (not $self->status->{empire}->{planets});

    ## Reverse so we can key by name, not id. Making sorting easy.
    $self->status->{empire}->{planets} = {reverse %{$self->status->{empire}->{planets}}};
    
    foreach my $name (sort keys %{$self->status->{empire}->{planets}}) {
        my $id = $self->status->{empire}->{planets}->{$name};

        ## If we have an SS regex, use it. Otherwise, return the whole mess.
        my $regex = $self->config->{ss_name_regex};
        if ($regex) {
            if ($name =~ m/$regex/i) {
                push(@{$self->status->{empire}->{stations}}, {
                    id   => $id,
                    name => $name,
                });
            }
            else {
                push(@{$self->status->{empire}->{colonies}}, {
                    id   => $id,
                    name => $name,
                });
            }
        }
        else {
            $self->status->{empire}->{colonies} = $self->status->{empire}->{planets};
            $self->status->{empire}->{stations} = $self->status->{empire}->{planets};
        }
    }
}

## Bread::Board stores a singleton in it's initial state, but doesn't replace
## it if anything got changed. This means, that every time glc is fetched,
## there's no session id in there.  To get around this, let's make a call THEN
## send it to bb.
## This method should only get called by Bread::Board in the construction of
## the glc singleton.
sub innit_glc {
    my $self = shift; ## Not that we want it... yet...
    my $glc  = shift;
    
    my $status = $glc->empire->get_status // die 'No internet connection.';
    
    ## Do this so we can transport the status between glc and core while they're
    ## being built by Bread::Board, saving a few RPCs.
    $glc->{status} = $status;

    return $glc;
}

## As a little hack around to make my life easier.
sub status {
    my $self = shift;
    return $self->glc->{status};
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head2 To be used later...
sub _build_db {
    my $self = shift;

    say 'Checking database.';

    ## TODO, use the implement the options attr of $self.
                
    ## Use the fresh argument to specify if we want to start with a fresh db.
    #if ($self->options->{fresh}) {
    #    unlink $self->param('db_file'); ## Why is it called unlink?
    #}

    ## Check that the file the database lives in actually exists.
    ## If it does, then we'll assume it's been setup correctly.
    ## Otherwise, create and setup a new DB with all our tables in it.
    if (-e $self->config->{db_file}) {
        
        return DBI->connect('DBI:SQLite:dbname=' . $self->config->{db_file})
            or die DBI->errstr;
        
        say 'Loaded database.';
    }
    else {
        say 'No database. Creating one.';
        
        my $dbh = DBI->connect('DBI:SQLite:dbname=' . $self->config->{db_file}) 
            or die DBI->errstr;
        
        say 'Loaded Database';
        return $self->setup_db($dbh);
    }
}

sub setup_db {
    my $self = shift;
    my $dbh  = shift;

    ## This is where we setup each table that the script will use.
    $dbh->do(q{
        CREATE TABLE stars (
            key  INT auto_increment PRIMARY KEY,
            id   INT                NOT NULL,
            name TEXT               NOT NULL,
            x    INT                NOT NULL,
            y    INT                NOT NULL
        )
    }) or die DBI->errstr;

    $dbh->do(q{
        CREATE TABLE bodies (
            key      INT auto_increment PRIMARY KEY,
            id       INT                NOT NULL,
            name     TEXT               NOT NULL,
            x        INT                NOT NULL,
            y        INT                NOT NULL,
            oretype  TEXT               NOT NULL,
            bodytype TEXT               NOT NULL
        )
    }) or die DBI->errstr;

    return $dbh;
}

=cut
