#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Vasari::TLEUtil;

my $task = Vasari::TLEUtil->new(task => "excavator_manager");
$task->run;
