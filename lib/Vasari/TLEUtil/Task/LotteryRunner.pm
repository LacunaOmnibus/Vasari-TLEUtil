package Vasari::TLEUtil::Task::LotteryRunner;

use strict;
use warnings;
use v5.10;

use Moose;
use Data::Dumper;

use LWP::UserAgent;
use HTTP::Request;

has 'glc'    => (is => 'ro', isa => 'Games::Lacuna::Client', required => 1);
has 'config' => (is => 'ro', isa => 'HashRef',               required => 1);
has 'core'   => (is => 'ro', isa => 'Vasari::TLEUtil::Core', required => 1);

sub run {
    my $self = shift;

    my $votes_per_planet = $self->config->{lottery_runner}->{links_per_planet};
    my $bodies = $self->config->{lottery_runner}->{planets};

    # Array ref of planets that need to be voted on.
    my $to_vote;

    foreach my $planet (@{$self->core->colonies}) {
        if ($planet->{name} ~~ @$bodies) {
            say "Voting $votes_per_planet links at " . $planet->{name};
            push(@$to_vote, $planet);
        }
    }

    $self->vote($to_vote, $votes_per_planet);
}

## Should be handed an array of hashes each containing an id and name that
## lottery links should be voted on.
sub vote {
    my $self = shift;
    my $to_vote = shift;
    my $votes_per_planet = shift;

    my $successful_votes;

    foreach my $body (@{$to_vote}) {
        ## Load buildings, find the Entertainment District.
        say "Finding the Entertainment District on " . $body->{name};
        my $buildings = $self->core->buildings($body->{id});
        my $ed = $self->core->extract_building($buildings, 'Entertainment District');

        unless ($ed) {
            return;
        }

        my $ed_obj = $self->glc->building(id => $ed->{id}, type => 'entertainment');

        ## Grab the vote options.
        my $vote_options = $ed_obj->get_lottery_voting_options->{options};

        for (1..$votes_per_planet) {
            my $vote = pop $vote_options; ##  Does it really matter if we do them in reverse order?

            say "Voting at " . $vote->{name};
            $self->visit_link($vote->{url}, $vote->{name}) and $successful_votes++;
        }
    }

    say "Successfully voted at $successful_votes links. Enjoy the Essentia :)";
}

sub visit_link {
    my $self = shift;
    my $link = shift;
    my $name = shift;
    
    my $agent = LWP::UserAgent->new(env_proxy => 1, keep_alive => 1, timeout => 30);
    my $header = HTTP::Request->new(GET => $link);
    my $request = HTTP::Request->new('GET', $link, $header);
    my $response = $agent->request($request);
    
    ## Check the outcome of the response.
    if ($response->is_success) {
    
        my $rv_hs  = $response->headers_as_string;
        my $rv_str = $response->as_string;
        
        if (defined $rv_hs and defined $rv_str) {
            say "Successfully voted at $name.";
            return 1;
        }
        else {
            say "Already voted at $name.";
            return 0;
        }
    }
    elsif ($response->is_error){
        say "Error: ". $response->error_as_HTML;
        return 0;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
