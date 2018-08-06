# See bottom of file for license and copyright information
use strict;
use warnings;

package PbnAgentTests;

use FoswikiTestCase;
our @ISA = qw( FoswikiTestCase );

use strict;
use warnings;
use Foswiki;
use CGI;

use Foswiki::Plugins::BridgePlugin::PbnAgent;
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

sub test_pbnAgent_Single {
    my $this = shift;

    my $testFile = '../../../test/single_set.pbn';

    my $agent = Foswiki::Plugins::BridgePlugin::PbnAgent->new($foswiki);

    my $cells = $agent->getCells($testFile);

    $this->assert_str_equals(
        'B',
        substr( $cells->[1][1], 0, 1 ),
        "Cell(1,1) must be a Board!"
    );
    $this->assert_str_equals(
        'H',
        substr( $cells->[1][2], 0, 1 ),
        "Cell(1,2) must be a Hand!"
    );
    $this->assert_str_equals(
        'A',
        substr( $cells->[1][3], 0, 1 ),
        "Cell(1,3) must be a Auction!"
    );
    $this->assert_num_equals(
        4,
        $#{ $cells->[0] },
        "There must be 5 entries (0 .. 4) in the header"
    );
    $this->assert_num_equals(
        4,
        $#{ $cells->[1] },
        "There must be 5 entries (0 .. 4) in the data"
    );

}

sub test_pbnAgent_Multiple {
    my $this = shift;

    my $testFile = '../../../test/multiple_sets.pbn';

    my $agent = Foswiki::Plugins::BridgePlugin::PbnAgent->new($foswiki);

    my $cells = $agent->getCells($testFile);

    $this->assert_num_equals( 36, $#{$cells},
        "There must be 37 rows (0 .. 36) in the data" );

    # check for duplicate hand records. Off by 1 errors can cause these.
    for ( my $i = 1 ; $i <= $#{$cells} ; $i++ ) {
        for ( my $j = $i + 1 ; $j <= $#{$cells} ; $j++ ) {
            $this->assert_str_not_equals( $cells->[$i][2], $cells->[$j][2],
                "Hand $i duplicates hand $j!" );
        }
    }
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
