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

package Foswiki::Plugins::BridgePlugin::Board;

use strict;
use warnings;

use Foswiki::Func ();

use Data::Dump qw( dump );

###############################################################################
sub new {
    my ( $class, $session, $web, $topic ) = @_;

    my $className = $class;
    $className =~ s/^.*:://;

    my $this = bless(
        {
            className      => $className,
            session        => $session,
            baseWeb        => $session->{webName},
            baseTopic      => $session->{topicName},
            thisWeb        => $web,
            thisTopic      => $topic,
            orderedSeats   => [ "West", "North", "East", "South" ],
            orderedSuits   => [ "Spades", "Hearts", "Diamonds", "Clubs" ],
            cardOrder      => 'AKQJT98765432',
            highCardPoints => {
                A => 4,
                K => 3,
                Q => 2,
                J => 1,
            },
            symbols => {
                S =>
                  '<span style="font-size:130%; color: black;">&spades;</span>',
                H =>
                  '<span style="font-size:130%; color: red;">&hearts;</span>',
                D => '<span style="font-size:130%; color: red;">&diams;</span>',
                C =>
                  '<span style="font-size:130%; color: black;">&clubs;</span>',
                N => 'NT',
                P => 'pass',
                A => 'all pass',
            }
        },
        $class
    );

    return $this;
}

###############################################################################
sub bridgeAuction {
    my ( $this, $params, $topicObject ) = @_;

    $this->parseParams($params);

    $topicObject =
      $this->getTopicObject( $this->{theDataWeb}, $this->{theDataTopic} )
      unless $this->{thisWeb}
      . $this->{thisTopic} eq $this->{theDataWeb}
      . $this->{theDataTopic};

    my ( $dealer, $vul, $dealerSeatIndex, @bids ) =
      $this->parseAuction( $this->getFieldValue( $topicObject, 'Auction' ) );

    return $this->renderAuction( $dealerSeatIndex, @bids );

}

###############################################################################
sub parseAuction {
    my ( $this, $auctionRecord ) = @_;

    # Typical:A S?:2DP2NP:3HP3NP:PP

    my @bids = ();

    my ( $dealer, $vul ) = ( $auctionRecord =~ m!\AA\s+(\w)([\w\?]):! );

    my $dealerSeatIndex = $this->findSeatIndex($dealer);

    $auctionRecord =~ s!(\AA\s+(\w)([\w\?]):|:)!!g;

    @bids = ( $auctionRecord =~ m!(\d?\w)!g );

    return ( $dealer, $vul, $dealerSeatIndex, @bids );

}

###############################################################################
sub findSeatIndex {
    my ( $this, $seat ) = @_;

    for ( my $i = 0 ; $i <= $#{ $this->{orderedSeats} } ; $i++ ) {
        return $i if ( $this->{orderedSeats}[$i] =~ m!($seat)! );
    }
    return undef;
}

###############################################################################
sub renderAuction {
    my ( $this, $dealerSeatIndex, @bids ) = @_;

    my $i;

    my $out = '| ';
    foreach my $seat ( @{ $this->{orderedSeats} } ) {
        $out .= $seat . ' | ';
    }
    $out .= "\n| ";

    for ( $i = 0 ; $i < $dealerSeatIndex ; $i++ ) {
        $out .= " | ";
    }

    ( $i, $out ) =
        $this->{theAuctionRounds} eq 'practice'
      ? $this->renderAuctionPractice( $i, $out, @bids )
      : $this->renderAuctionRounds( $i, $out, @bids );

    for ( ; $i < 4 ; $i++ ) {
        $out .= "| ";
    }

    return $out;

}

###############################################################################
sub renderAuctionRounds {
    my ( $this, $i, $out, @bids ) = @_;

    my $auctionRounds =
      $this->{theAuctionRounds} ? $this->{theAuctionRounds} : $#bids / 4;
    my $seat = 0;
    for ( $seat = 0 ; $seat / 4 < $auctionRounds && $seat <= $#bids ; ) {
        ( $i, $out, $seat ) =
          $this->renderAuctionRound( $i, $out, $seat, @bids );
    }
    return $i, $out;
}

###############################################################################
sub renderAuctionPractice {
    my ( $this, $i, $out, @bids ) = @_;

    my $par  = 1;
    my $seat = 0;

    if ( $this->{practiceAuctionRound} ) {
        for (
            ;
            $par <= $this->{practiceAuctionRound} && $seat <= $#bids ;
            $par++
          )
        {
            ( $i, $out, $seat ) =
              $this->renderAuctionRound( $i, $out, $seat, @bids );
        }
    }
    $out .= ( $seat > $#bids ) ? " | " : "[[%TOPIC%?par=$par][BID]] | ";
    $i++;

    return $i, $out;
}

###############################################################################
sub renderAuctionRound {
    my ( $this, $i, $out, $seat, @bids ) = @_;

    while () {
        $bids[$seat] =~ s!(S|H|D|C|N|P|A)!$this->{symbols}->{$1}!;
        $out .= $bids[$seat] . " | ";
        $i = ( $i + 1 ) % 4;
        if ( $i == 0 ) {
            $out .= "\n| ";
        }
        last if ( ++$seat % 4 == 0 || $seat > $#bids );
    }
    return $i, $out, $seat;
}

###############################################################################
sub bridgePlay {
    my ( $this, $params, $topicObject ) = @_;

    $this->parseParams($params);

    $topicObject =
      $this->getTopicObject( $this->{theDataWeb}, $this->{theDataTopic} )
      unless $this->{thisWeb}
      . $this->{thisTopic} eq $this->{theDataWeb}
      . $this->{theDataTopic};

    my $hands = $this->getFieldValue( $topicObject, 'Hands' )
      if $this->{theDeal} ne 'new';

    my $dealer = substr( $hands, 2, 1 ) if $hands;
    $dealer = $this->{orderedSeats}[ int( rand(4) ) ] unless $dealer;
    my @deal = ();
    if ( $this->{theDeal} ne 'full' ) {
        @deal = $this->placeCurrentDeal($hands)
          unless $this->{theDeal} eq 'new';
        @deal = $this->completeDeal(@deal);
        $hands = $this->deal2rbn( $dealer, @deal );
    }

    return $this->formatPlay( $this->rbn2pbn( $topicObject, $hands ) );
}

###############################################################################
sub deal2rbn {
    my ( $this, $dealer, @deal ) = @_;

    my %hands     = ();
    my $dealIndex = 0;
    foreach my $seat (@deal) {
        $hands{$seat} .= substr( $this->{cardOrder}, $dealIndex % 13, 1 );
        $dealIndex++;
        if ( ( $dealIndex % 13 ) == 0 ) {
            foreach my $s ( @{ $this->{orderedSeats} } ) {
                $hands{$s} .= '.' unless $dealIndex > 40;
            }
        }
    }

    my $result = "H $dealer";
    foreach my $seat ( @{ $this->{orderedSeats} } ) {
        $result .= ':' . $hands{$seat};
    }
    return $result;
}

###############################################################################
sub completeDeal {
    my ( $this, @deal ) = @_;

    my @seats     = @{ $this->{orderedSeats} };
    my %seatCount = ();

    {
        no warnings qw(uninitialized);
        ;    # @deal may have unitialised values.
        foreach my $seat (@seats) {
            $seatCount{$seat} = grep /$seat/, @deal;
        }
    }

##### populate the seatList
    my @seatList = ();
    foreach my $j ( 0 .. 3 ) {
        for ( my $i = $seatCount{ $seats[$j] } ; $i < 13 ; $i++ ) {
            push @seatList, $seats[$j];
        }
    }

    #print "\n=== Populated seatList: ".join( "+", @seatList);
####shuffle the seatlist
    for ( my $i = $#seatList ; $i >= 0 ; $i-- ) {
        my $j = int( rand( $i + 1 ) );
        @seatList[ $i, $j ] = @seatList[ $j, $i ];
    }

    #print "\n=== Shuffled seatList: ".join( "+", @seatList);
    #print "\n=== Incomplete deal: ". join( "+", @deal );
    my $j = 0;
    for ( my $i = 0 ; $i < 13 * 4 ; $i++ ) {
        next if $deal[$i];
        $deal[$i] = $seatList[$j];
        $j++;
    }

    return @deal;
}

###############################################################################
sub placeCurrentDeal {
    my ( $this, $rbnDeal ) = @_;

    my %hashCardOrder = ();
    my @rbnDeal       = ();

    for ( my $i = 0 ; $i <= length( $this->{cardOrder} ) ; $i++ ) {
        $hashCardOrder{ substr( $this->{cardOrder}, $i, 1 ) } = $i;
    }

    my @deal = ();

    @rbnDeal = ( $rbnDeal =~ m!([NESW2-9TJQKA\.:])!g );

    my $seat      = shift @rbnDeal;
    my $seatIndex = 0;
    $seat = $this->{orderedSeats}[$seatIndex];

    shift @rbnDeal;    # skip the leading colon
    my $suitIndex = 0;
    my $suit      = $this->{orderedSuits}[$suitIndex];

    foreach my $ch (@rbnDeal) {
        if ( $ch eq '.' ) {
            $suitIndex = ( $suitIndex + 1 ) % 4;
            $suit      = $this->{orderedSuits}[$suitIndex];
        }
        elsif ( $ch eq ':' ) {
            $suitIndex = 0;
            $suit      = $this->{orderedSuits}[$suitIndex];
            $seatIndex = ( $seatIndex + 1 ) % 4;
            $seat      = $this->{orderedSeats}[$seatIndex];
        }
        else {
            $deal[ $hashCardOrder{$ch} + 13 * $suitIndex ] = $seat;
        }
    }

    return map { $_ ? $_ : '' } @deal;
}

###############################################################################
sub rbn2pbn {
    my ( $this, $topicObject, $hands ) = @_;

    my %pbnVul = (
        B => 'All',
        E => 'EW',
        N => 'NS',
        Z => 'None',
    );

    my $board = substr( $this->getFieldValue( $topicObject, 'Board' ), 2 );
    my ( $dealer, $vul, $dealerSeatIndex, @bids ) =
      $this->parseAuction( $this->getFieldValue( $topicObject, 'Auction' ) );

    $vul = ( exists $pbnVul{$vul} ) ? $pbnVul{$vul} : 'None';

    my $deal = substr( $hands, 2 );
    $deal =~ s/:/#/;
    $deal =~ s/:/ /g;
    $deal =~ s/#/:/;
    $deal =~ s/10/T/g;

    return $board, $dealer, $vul, $deal;
}

###############################################################################
sub formatPlay {
    my ( $this, $board, $dealer, $vul, $deal ) = @_;

    return
        "This deal ("
      . $this->{theDataWeb} . '.'
      . $this->{theDataTopic}
      . ") is incomplete ("
      . length($deal)
      . "). You cannot play this board."
      if length($deal) < 69;

# Need to fix vul and pbnFormat. the latter must be an expressiong to include the new lines.

    my $pbnBoardFormat = q('[Board "%s"]' + '\n' +) . "\n";
    $pbnBoardFormat .= q('[Dealer "%s"]' + '\n' +) . "\n";
    $pbnBoardFormat .= q('[Vulnerable "%s"]' + '\n' +) . "\n";
    $pbnBoardFormat .= q('[Deal "%s"]');
    my $pbnBoard = sprintf( $pbnBoardFormat, $board, $dealer, $vul, $deal );

## Scaling:
## Ref: http://carsonfarmer.com/2012/08/cross-browser-iframe-scaling/
##  which recommends against zoom.
## Ref: https://www.w3schools.com/css/css3_2dtransforms.asp
    my $w = int( $this->{theScale} * 850 );
    my $h = int( $this->{theScale} * 520 );
    ###  border: 1px solid black;
    my $zoomStyle = <<ENDZOOMSTYLE;
<style>
#wrap { width: ${w}px; height: ${h}px; padding:0; overflow:hidden; }
#thePlayTarget { width: 830px; height: 490px; }
#thePlayTarget {  
    -ms-zoom: $this->{theScale};
    -ms-transform-origin: 0 0;
    -moz-transform: scale($this->{theScale});
    -moz-transform-origin: 0px 50px;
    -o-transform: scale($this->{theScale});
    -o-transform-origin: 0px 50px;
    -webkit-transform: scale($this->{theScale});
    -webkit-transform-origin: 0 0;
}
</style>
ENDZOOMSTYLE

    Foswiki::Func::addToZone( 'head', 'BridgePlugin_zoomStyle', $zoomStyle );

    my $out = '<div id="wrap" ><iframe id="thePlayTarget" ></iframe></div>';
    $out .= "\n";

    my $playTargetScript = sprintf <<'PLAYTARGETSCRIPT', $pbnBoard;
<script>
  var formData = new FormData();
  var content = %s; // the body of the new file...
  var blob = new Blob([content], { type: "text/plain"});

  formData.append( "fileToUpload", blob, "somename.pbn" )

  formData.append("event",0);

      $.ajax({            
          url: 'http://mirgo2.co.uk/bridgesolver/upload_file.php',
          type: 'POST',
          data: formData,
          cache: false,
          contentType: false,
          processData: false,
          success: function (returndata) {
var re = new RegExp('filename=\"(//mirgo2.co.uk/bridgesolver/uploads/.*?.pbn)\"'  );

var myResult = returndata.match( re );

document.getElementById('thePlayTarget').setAttribute( 'src', 'http://dds.bridgewebs.com/bsol2/ddummy.htm?club=bsol_site&file=https:' + myResult[1] );
          },
          error: function () {
              alert("error in ajax form submission");
          }
      });
</script>  
PLAYTARGETSCRIPT

    return $out . $playTargetScript;
}

###############################################################################
sub bridgeHands {
    my ( $this, $params, $topicObject ) = @_;

    $this->parseParams($params);

    $topicObject =
      $this->getTopicObject( $this->{theDataWeb}, $this->{theDataTopic} )
      unless $this->{thisWeb}
      . $this->{thisTopic} eq $this->{theDataWeb}
      . $this->{theDataTopic};

    my ( $handIndex, %hand, %cards );

    my @hands = split /:/, $this->getFieldValue( $topicObject, 'Hands' );
    my ($firstHand) = ( $hands[0] =~ m!\A\w\s+(\w)! );

    $handIndex = $this->findSeatIndex($firstHand);

    for ( my $i = 0 ; $i <= $#{ $this->{orderedSeats} } ; $i++ ) {
        $hand{ $this->{orderedSeats}[$handIndex] } = $hands[ $i + 1 ] || "";
        $handIndex = ( $handIndex + 1 ) % 4;
    }

    while ( my ( $seat, $h ) = each %hand ) {

        $cards{$seat}{value} = $this->handValue($h);
        my @suits = split /\./, $h;
        for ( my $i = 0 ; $i <= $#{ $this->{orderedSuits} } ; $i++ ) {
            $cards{$seat}{ $this->{orderedSuits}[$i] } = $suits[$i] || "";
        }
    }

    return $this->formatHandsAsBoard(%cards) if $this->{displayBoard};
    return $this->formatHandsTable(%cards);

}

###############################################################################
sub handValue {
    my ( $this, $hand ) = @_;

    my $value = 0;
    foreach my $card ( split //, $hand ) {
        $value += $this->{highCardPoints}->{$card}
          if $this->{highCardPoints}->{$card};
    }
    return $value;
}

###############################################################################
sub getFieldValue {
    my ( $this, $topicObject, $fieldName ) = @_;

    my $result;
    {
        local @_;
        eval { $result = $topicObject->get( 'FIELD', $fieldName )->{value} };

        return $result unless @_;
    }
    return "There is no '$fieldName' field in this topic";

}

###############################################################################
sub formatHandsTable {
    my ( $this, %cards ) = @_;

    my $out = '| |';
    foreach my $seat ( @{ $this->{orderedSeats} } ) {
        $out .= " $seat |";
    }
    $out .= "\n";
    foreach my $suit ( @{ $this->{orderedSuits} } ) {
        $out .= "| " . $this->{symbols}->{ substr( $suit, 0, 1 ) } . " |";
        foreach my $seat ( @{ $this->{orderedSeats} } ) {
            $out .= " $cards{$seat}{$suit} |";
        }
        $out .= "\n";
    }
    $out .= "|HCP|";
    foreach my $seat ( @{ $this->{orderedSeats} } ) {
        $out .= " $cards{$seat}{value} |";
    }
    return $out;
}

###############################################################################
sub formatHandsAsBoard {
    my ( $this, %cards ) = @_;

    my @board = (
        '<table>',
        '<tr> <td></td><td>%s</td><td> </td></tr>',
'<tr><td>%s</td><td style="text-align: center; vertical-align: middle;"> %s </td><td>%s</td></tr>',
        '<tr> <td></td><td>%s</td><td> </td></tr>',
        '</table>'
    );

    my $out = sprintf(
        join( '', @board ),
        $this->printHand( 'North', %cards ),
        $this->printHand( 'West',  %cards ),
        $this->{displayBoard},
        $this->printHand( 'East',  %cards ),
        $this->printHand( 'South', %cards )
    );
    return $out;
}

###############################################################################
sub printHand {
    my ( $this, $seat, %cards ) = @_;

    return '' if join( '', ( values %{ $cards{$seat} } ) ) eq '0';

    my $out;
    foreach my $suit ( @{ $this->{orderedSuits} } ) {
        $out .=
            $this->{symbols}{ substr( $suit, 0, 1 ) } . ' '
          . $cards{$seat}{$suit}
          . '<br />';
    }
    return $out;
}

###############################################################################
sub getTopicObject {
    my ( $this, $web, $topic ) = @_;

    my ( $topicObject, $topicText ) = Foswiki::Func::readTopic( $web, $topic );

    return $topicObject;
}

###############################################################################
sub writeDebug {
    my $this = shift;

    Foswiki::Func::writeDebug( $this->{className} . " - $_[0]" )
      if $this->{debug};
}

###############################################################################
sub parseParams {
    my ( $this, $params ) = @_;

    my $query = Foswiki::Func::getRequestObject();
    $this->{practiceAuctionRound} =
      ( $query->param('par') && $query->param('par') =~ m!(\d+)! )
      ? $query->param('par')
      : undef;

    $this->{debug} =
      Foswiki::Func::isTrue( scalar $params->{debug}, $this->{debug} )
      unless defined $this->{debug};

    $this->{theDataTopic} = $params->{topic} || $this->{thisTopic};

    $this->{theDataWeb} = $params->{web} || $this->{thisWeb};
    throw Error::Simple( "Web: " . $this->{theDataWeb} . " does not exist" )
      unless $this->{theDataWeb} eq ''
      || Foswiki::Func::webExists( $this->{theDataWeb} );

    ( $this->{theDataWeb}, $this->{theDataTopic} ) =
      Foswiki::Func::normalizeWebTopicName( $this->{theDataWeb},
        $this->{theDataTopic} );
    throw Error::Simple( "Topic: "
          . $this->{theDataWeb} . "."
          . $this->{theDataTopic}
          . " does not exist" )
      unless $this->{theDataTopic} eq ''
      || Foswiki::Func::topicExists( $this->{theDataWeb},
        $this->{theDataTopic} );

    $this->{theAuctionRounds} =
      ( $params->{rounds} && $params->{rounds} =~ m!\A(\d+|practice)\Z!i )
      ? lc( $params->{rounds} )
      : '';

    $this->{displayBoard} =
      validateBoard( $this->{theDataWeb},
        "$Foswiki::cfg{SystemWebName}\.BridgePlugin",
        $params->{board} );

    $this->{theDeal} =
      ( $params->{deal} && $params->{deal} =~ m!\A(full|partial|new)\Z!i )
      ? $params->{deal}
      : 'full';
    $this->{theScale} =
      ( $params->{zoom} && $params->{zoom} =~ m!\A\d*\.\d*\Z! )
      ? $params->{zoom}
      : 1.0;

    return $this;
}

sub validateBoard {
    my ( $defaultweb, $fulltopic, $board ) = @_;

    my $defaultBoard = sprintf( "%s%s/%s/%s/%s",
        $Foswiki::cfg{DefaultUrlHost},
        $Foswiki::cfg{PubUrlPath},
        $Foswiki::cfg{SystemWebName},
        "BridgePlugin", "bridgeboard.gif" );
    my $validBoard;
    if ( $board && $board eq 'on' ) { $validBoard = $defaultBoard }
    elsif ( $board && ( $board =~ m!\Ahttp! ) ) {
        $validBoard = $board;
    }    ### http://host/path/file
    elsif ( $board && !( $board =~ m!/! ) ) {
        $validBoard = "$fulltopic/$board";
    }    ### file
    elsif ( $board && ( $board =~ m!\A[^/.]+/[^/]+\Z! ) ) {
        $validBoard = "$defaultweb\.$board";
    }    ### topic/file
    elsif ($board) {
        $validBoard = $board;
    }    ### web.topic/file OR web/subweb.topic/file
    else { return '' }    ### empty

    if ( $validBoard =~ m!\Ahttp! ) { return $validBoard }
    else {
        my ( $attWeb, $attTopic, $attFile ) =
          ( $validBoard =~ m!\A([^\.]+)\.([^/]+)/([^/]+)\Z! );
        if ( Foswiki::Func::attachmentExists( $attWeb, $attTopic, $attFile ) ) {
            $validBoard = sprintf( "%s%s/%s/%s/%s",
                $Foswiki::cfg{DefaultUrlHost},
                $Foswiki::cfg{PubUrlPath},
                $attWeb, $attTopic, $attFile );
        }
        else { $validBoard = $defaultBoard }
    }

    return $validBoard;
}

1;
