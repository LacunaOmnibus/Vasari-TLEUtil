package Games::Lacuna::Client;
use 5.0080000;
use strict;
use warnings;
use Carp 'croak';
use File::Temp qw( tempfile );
use Cwd        qw( abs_path );
use Try::Tiny;

use constant DEBUG => 1;

use Games::Lacuna::Client::Module; # base module class
use Data::Dumper;

#our @ISA = qw(JSON::RPC::Client);
use Class::XSAccessor {
  getters => [qw(
    rpc
    uri name password api_key
  )],
  accessors => [qw(
    debug
    session_id
    session_start
    session_timeout
    session_persistent
    rpc_sleep
    prompt_captcha
    open_captcha
  )],
};

require Games::Lacuna::Client::RPC;

require Games::Lacuna::Client::Alliance;
require Games::Lacuna::Client::Body;
require Games::Lacuna::Client::Buildings;
require Games::Lacuna::Client::Captcha;
require Games::Lacuna::Client::Empire;
require Games::Lacuna::Client::Inbox;
require Games::Lacuna::Client::Map;
require Games::Lacuna::Client::Stats;


sub new {
  my $class = shift;
  my %opt = @_;
  
  my @req = qw(uri name password api_key);
  croak("Need the following parameters: @req")
    if (not exists $opt{uri}
        or not exists $opt{name}
        or not exists $opt{password}
        or not exists $opt{api_key});
  $opt{uri} =~ s/\/+$//;

  my $debug = exists $ENV{GLC_DEBUG} ? $ENV{GLC_DEBUG} : 0;

  my $self = bless {
    session_start      => 0,
    session_id         => 0,
    session_timeout    => 3600*1.8, # server says it's 2h, but let's play it safe.
    session_persistent => 0,
    debug              => $debug,
    %opt
  } => $class;

  # the actual RPC client
  $self->{rpc} = Games::Lacuna::Client::RPC->new(client => $self);

  return $self,
}

sub empire {
  my $self = shift;
  return Games::Lacuna::Client::Empire->new(client => $self, @_);
}

sub alliance {
  my $self = shift;
  return Games::Lacuna::Client::Alliance->new(client => $self, @_);
}

sub body {
  my $self = shift;
  return Games::Lacuna::Client::Body->new(client => $self, @_);
}

sub building {
  my $self = shift;
  return Games::Lacuna::Client::Buildings->new(client => $self, @_);
}

sub captcha {
  my $self = shift;
  return Games::Lacuna::Client::Captcha->new(client => $self, @_);
}

sub inbox {
  my $self = shift;
  return Games::Lacuna::Client::Inbox->new(client => $self, @_);
}

sub map {
  my $self = shift;
  return Games::Lacuna::Client::Map->new(client => $self, @_);
}

sub stats {
  my $self = shift;
  return Games::Lacuna::Client::Stats->new(client => $self, @_);
}


sub register_destroy_hook {
  my $self = shift;
  my $hook = shift;
  push @{$self->{destroy_hooks}}, $hook;
}

sub DESTROY {
  my $self = shift;
  if ($self->{destroy_hooks}) {
    $_->($self) for @{$self->{destroy_hooks}};
  }

  if (not $self->session_persistent) {
    $self->empire->logout;
  }
  elsif (defined $self->cfg_file) {
    $self->write_cfg;
  }
}

sub assert_session {
  my $self = shift;

  my $now = time();
  if (!$self->session_id || $now - $self->session_start > $self->session_timeout) {
    if ($self->debug) {
      print STDERR "DEBUG: Logging in since there is no session id or it timed out.\n";
    }
    my $res = $self->empire->login($self->{name}, $self->{password}, $self->{api_key});
    $self->{session_id} = $res->{session_id};
    if ($self->debug) {
      print STDERR "DEBUG: Set session id to $self->{session_id} and updated session start time.\n";
    }
  }
  elsif ($self->debug) {
      print STDERR "DEBUG: Using existing session.\n";
  }
  $self->{session_start} = $now; # update timeout
  return $self->session_id;
}

1;
__END__