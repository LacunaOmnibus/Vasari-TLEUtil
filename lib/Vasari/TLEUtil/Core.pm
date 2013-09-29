package Vasari::TLEUtil::Core;

use strict;
use warnings;
use v5.10;

use Data::Dumper;

use Moose;

use List::Util (qw(first));

has 'glc'    => (is => 'ro', isa => 'Games::Lacuna::Client', required => 1);
has 'config' => (is => 'ro', isa => 'HashRef',               required => 1);
has 'status' => (is => 'rw', isa => 'HashRef',               lazy_build => 1);

sub buildings {
    my $self = shift;
    my $id   = shift;

    unless ($id) {
        return;
    }

    return $self->glc->body(id => $id)->get_buildings->{buildings} // {};
}

sub extract_building {
    my $self        = shift;
    my $buildings   = shift;
    my $target_name = shift;

    unless ($buildings and $target_name) {
        return;
    }

    my $id = first {
        $buildings->{$_}->{name} eq $target_name;
    } keys %$buildings;

    if ($id) {
        ## Id is the key of the hash, gotta add it into the hash for later use.
        $buildings->{$id}->{id} = $id;
        return $buildings->{$id};
    }
}

sub extract_all_matching_buildings {
    my $self = shift;
    my $buildings = shift;
    my $target_name = shift;
    my $rv          = [];
    
    foreach my $id (keys %$buildings) {
        my $building = $buildings->{$id};
        if ($building->{name} eq $target_name) {
            $building->{id} = $id; ## Add id.
            push @$rv, $building;
        }
    }
    
    ## This method will most likely only be used by the buildings upgrader.
    ## Sort by level to most time effectively upgrade everything.
    my @return_value = sort {$a->{level} <=> $b->{level}} @$rv;
    
    return \@return_value;
}

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

    ## There should already be a status, created when $self was built.
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

sub _build_status {
    my $self = shift;
    return $self->glc->empire->get_status;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;



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
