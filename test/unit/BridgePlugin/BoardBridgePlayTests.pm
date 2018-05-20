# See bottom of file for license and copyright information
use strict;
use warnings;

package BoardBridgePlayTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;
use warnings;
use Foswiki;
use CGI;

use Foswiki::Plugins::BridgePlugin::Board;
use Data::Dump qw(dump);

my $foswiki;

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

# Set up the test fixture
sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

    $Foswiki::Plugins::SESSION = $foswiki;
}

sub tear_down {
    my $this = shift;
    $this->SUPER::tear_down();
}

## formatPlay is NOT a test. Just a development crutch
sub test_formatPlay {
    my $this = shift;
    
    $Foswiki::Plugins::SESSION = $this->{session};

# formatPlay takes pbn hand descriptions
    my $boardNumber = "1";
    my $dealer = "N";
    my $vul = "None";
    my $deal =  "S:T7.J7.AKQ54.K543 5.QT82.JT62.QJT7 J9862.A5.98.9862 AKQ43.K9643.73.A";    
    
    my $board = Foswiki::Plugins::BridgePlugin::Board->new( $foswiki, 'Testweb', 'TestTopic' );

    $board->{theScale} = '0.7';
    my $result = $board->formatPlay( $boardNumber, $dealer, $vul, $deal );	
}

sub test_placeCurrentDeal {
    my $this = shift;

    my $board = Foswiki::Plugins::BridgePlugin::Board->new( $foswiki, 'Testweb', 'TestTopic' );
   
    my $hands = 'H W:82.AQT962.Q3.AJ2::Q3.3.AKJT97.K653';
    $board->{theDeal} = 'partial';
    my @deal = ();
    @deal =  $board->placeCurrentDeal( $hands );
    

    $this->assert_num_equals( 13, scalar grep( /West/, @deal), 'There must be 13 cards for West.' );
    $this->assert_num_equals( 13, scalar grep( /East/, @deal), 'There must be 13 cards for East.' );
    $this->assert_num_equals( 0, scalar grep( /North/, @deal), 'There must be 0 cards for North.');
    $this->assert_num_equals( 0, scalar grep( /South/, @deal), 'There must be 0 cards for South.');
    
    $this->assert_equals( 'West', $deal[13], 'West must hold the Ace of hearts.' );
    $this->assert_equals( 'West', $deal[39], 'West must hold the Ace of clubs.' );
    $this->assert_equals( 'East', $deal[26], 'East must hold the Ace of diamonds.' );
}

sub test_completeDeal {
    my $this = shift;
    
    my $board = Foswiki::Plugins::BridgePlugin::Board->new( $foswiki, 'Testweb', 'TestTopic' );
#    print "Board: ".dump($board)."\n";
    
    my $hands = 'H W:82.AQT962.Q3.AJ2::Q3.3.AKJT97.K653';
    $board->{theDeal} = 'partial';
    my @deal = ();
    @deal = $board->placeCurrentDeal( $hands );
    @deal = $board->completeDeal( @deal );
    

    $this->assert_num_equals( 13, scalar grep( /West/, @deal), 'There must be 13 cards for West.' );
    $this->assert_num_equals( 13, scalar grep( /East/, @deal), 'There must be 13 cards for East.' );
    $this->assert_num_equals( 13, scalar grep( /North/, @deal), 'There must be 13 cards for North.');
    $this->assert_num_equals( 13, scalar grep( /South/, @deal), 'There must be 13 cards for South.');
    
    $this->assert_equals( 'West', $deal[13], 'West must hold the Ace of hearts.' );
    $this->assert_equals( 'West', $deal[39], 'West must hold the Ace of clubs.' );
    $this->assert_equals( 'East', $deal[26], 'East must hold the Ace of diamonds.' );
}

sub test_dealToRbn {
    my $this = shift;
    
    my $board = Foswiki::Plugins::BridgePlugin::Board->new( $foswiki, 'Testweb', 'TestTopic' );
#    print "Board: ".dump($board)."\n";
    
    my $hands = 'H S:82.AQT962.Q3.AJ2::Q3.3.AKJT97.K653';
    $board->{theDeal} = 'partial';
    my $dealer = substr( $hands, 2, 1) if $hands;
    my @deal = ();
    @deal = $board->placeCurrentDeal( $hands );
    @deal = $board->completeDeal( @deal );
    my $fullHands = $board->deal2rbn( $dealer, @deal );

    my @hands = split( /[:\s]/, $hands );
    my @fullHands = split( /[:\s]/, $fullHands );
    
    $this->assert_str_equals( $hands[0], $fullHands[0], "Hand markers (H) must be equal." );
    $this->assert_str_equals( $hands[1], $fullHands[1], "Dealers must be equal." );
    $this->assert_str_equals( $hands[2], $fullHands[2], "Dealer hands must be equal." );
    $this->assert_str_equals( $hands[4], $fullHands[4], "Partner hands must be equal." );
    $this->assert_num_equals( 13+3, length($fullHands[3]), "Left hand opponent must have 13 cards." );
    $this->assert_num_equals( 13+3, length($fullHands[5]), "Right hand opponent must have 13 cards." );
    
        
}


1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-%$CREATEDYEAR% Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
