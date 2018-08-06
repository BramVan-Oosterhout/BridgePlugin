# Copyright (C) 2013-2015 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Plugins::BridgePlugin::PbnAgent;

use strict;
use warnings;

use Foswiki::Func ();

#use Foswiki::Plugins::BridgePlugin::EvaluateHands;

use Data::Dump qw(dump);

###############################################################################
sub new {
    my ( $class, $agentType ) = @_;

    my $className = $class;
    $className =~ s/^.*:://;

    my $this = bless(
        {
            className => $className,

            #    session => $session,
            #    baseWeb => $session->{webName},
            #    baseTopic => $session->{topicName},
        },
        $class
    );

    return $this;
}

###############################################################################
sub writeDebug {
    my $this = shift;
    print STDERR $this->{className} . " - $_[0]\n";    # if $this->{debug};
}

###############################################################################
#
# sub getCells parses the file and creates a row/column array of cells.
sub getCells {
    my ( $this, $filename ) = @_;

    my @headers   = qw( TOPIC Board Hands Auction Dealer );
    my %result    = ();
    my @cells     = ();
    my $rowNumber = 0;

    open( my $fh, '<:encoding(UTF-8)', $filename )
      or die "Could not open file '$filename' $!";

    push( @{ $cells[ $rowNumber++ ] }, @headers );

    while (<$fh>) {
        next if m!\"\?\"!;
        next if m!\A\s*\Z!;

        $_ = m!\[(\w+)\s+"([^"]+)"!;

        if ( $1 eq 'Event' && $result{Event} ) {
            push( @{ $cells[ $rowNumber++ ] }, $this->pbn2rbn( \%result ) );
        }

        $result{$1} = $2;
    }
    close $fh;

    push( @{ $cells[$rowNumber] }, $this->pbn2rbn( \%result ) );

    return \@cells;
}

###############################################################################
sub pbn2rbn {
    my ( $this, $result ) = @_;

    my %vul = (
        NS   => 'N',
        EW   => 'E',
        None => 'Z',
        All  => 'B',
    );

    my $topic = $result->{Event};
    $topic =~ s![^\w\d]!!g;
    $topic .= $result->{Board};

    my $board = $result->{Board};

    my $hands = $result->{Deal};
    $hands =~ s!10!T!g;
    $hands =~ s! !:!g;

    my $auction =
      $vul{ $result->{Vulnerable} } ? $vul{ $result->{Vulnerable} } : '?';
    $auction = $result->{Dealer} . $auction . ':';

    return ( $topic, "B $board", "H $hands", "A $auction", $result->{Dealer} );
}

1;
