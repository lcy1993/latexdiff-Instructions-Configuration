#!/usr/bin/env perl
##!/usr/bin/perl -w
# latexdiff - differences two latex files on the word level
#             and produces a latex file with the differences marked up.
#
#   Copyright (C) 2004-16  F J Tilmann (tilmann@gfz-potsdam.de)
#
# Repository/issue tracker:   https://github.com/ftilmann/latexdiff
# CTAN page:          http://www.ctan.org/pkg/latexdiff
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Detailed usage information at the end of the file
#
# ToDo:
#
# Version 1.2.1 (22 June 2017)
#    - add "DeclareOldFontCommand" to styles using \bf or \sf old style font commands (fixies issue #92 )
#    - improved markup: process lstinline commands in listings package correctly
#      for styles using colour, \verb and \lstinline arguments are marked up with colour (blue for added, red for deleted)
#    - bug fix: protecting inline math expressions for mbox did not work as intended (see stack exchange question: http://tex.stackexchange.com/questions/359412/compiling-the-latexdiff-when-adding-a-subscript-before-a-pmatrix-environment-cau)
#    - bug fix: when deleted \item commands are followed immediately by unsafe commands, they were not restored properly
#      (thanks to J. Protze for pull request) (pull request #89)
#    - treat lstlisting and comment as equivalent to verbatim environment
#      make environments that are treated like verbatim environments configurable (config variable VERBATIMENV)
#      treat lstinlne as equivalent to verb command
#      partially addresses issue #38
#    - refactoring: set default configuration variables in a hash, and those that correspond to lists 
#    - feature: option --add-to-config used to amend configuration variables, which are regex pattern lists
#    - bug fix: deleted figures when endfloat package is activated
#    - bug fix: alignat environment now always processed correctly (fix issues #65)
#    - bug fix: avoid processing of commands as potential files in routine init_regex_arr (fix issue #70 )
#    - minimal feature enhancement: treat '@' as allowed character in commands (strictly speaking requires prior \makeatletter statement, but always assuming it to be 
#       @       a letter if it is part of a command name will usually lead to the correct behaviour (see http://tex.stackexchange.com/questions/346651/latexdiff-and-let)
#    - new feature/bug fix: --flatten option \endinput in included files now respected but only if \endinput stands right at the beginning of the line (issue #77)
#    - bug fix: flatten would incorrectly attempt to process commented out \include commands (from discussion in issue #77 )
#    - introduce an invisible space (\hspace{0pt} after \mbox{..} auxiliary commands (not in math mode), to allow line breaks between added and deleted citations (change should not cause adverse behaviour otherwise)
#
# Version 1.2.0:
#    - highlight new and deleted figures
#    - bug fix in title mark-up. Previously deleted commands in title (such as \title, \author or \date) were marked up erroneously
#    - (minor) bug fixes in new 1.1.1 features: disabled label was commented out twice, additional spaces were introduced before list environment begin and end commands
#    - depracation fix: left brace in RegEx now needs to be escaped
#    - add type PDFCOMMENT based on issue #49 submitted by github user peci1 (Martin Pecka)
#    - make utf8 the default encoding
#
# Version 1.1.1
#    - patch mhchem: allow ce in equations
#    - flatten now also expands \input etc. in the preamble (but not \usepackage!)
#    - Better support for Japanese ( contributed by github user kshramt )
#    - prevent duplicated verbatim hashes (patch contributed by github user therussianjig, issue #36)
#    - disable deleted label commands (fixes issue #31)
#    - introduce post-processing to reinstate most deleted environments and all needed item commands (fixes issue #1)
#
# Version 1.1.0
#    - treat diacritics (\",\', etc) as safe commands
#    - treat \_ and \& correctly as safe commands, even if used without spacing to the next word
#    - Add a BOLD markup type that sets added text in bold face (Contribution by Victor Zabalza via pull request )
#    - add append-mboxsafecmd list option to be able to specify special safe commands which need to be surrounded by mbox to avoid breaking (mostly this is needed with ulem package)
#    - support for siunitx and cleveref packages: protect \SI command in siunitx package and \cref,\Cref{range}{*} in cleveref packages (thanks to Stefan Pinnow for testing)
#    - experimental support for chemformula, mhchem packages: define \ch and \ce in packages as safe (but not \ch,\cee in equation array environments) - these unfortunately will not be marked up (thanks to Stefan Pinnow for testing)
#    - bug fix: packages identified correctly even if \usepackage command options extend over several lines (previously \usepackage command needed to be fully contained in one line)
#    - new subtype ONLYCHANGEDPAGE outputs only changed pages (might not work well for floating material)
#    - new subtype ZLABEL operates similarly to LABEL but uses absolute page numbers (needs zref package)
#    - undocumented option --debug/--nodebug to override default setting for debug mode (Default: 0 for release version, 1: for development version
#
# Version 1.0.4
#    - introduce list UNSAFEMATHCMD, which holds list of commands which cannot be marked up with \DIFadd or \DIFdel commands  (only relevant for WHOLE and COARSE math markup modes)
#    - new subtype LABEL which gives each change a label. This can later be used to only display pages where changes
#      have been made (instructions for that are put as comments into the diff'ed file) inspired by answer on http://tex.stackexchange.com/questions/166049/invisible-markers-in-pdfs-using-pdflatex
#    - Configuration variables take into accout some commands from additional packages: 
#      tikzpicture environment now treated as PICTUREENV, and \smallmatrix in ARRENV (amsmath)
#    - --flatten: support for \subfile command (subfiles package)  (in response to http://tex.stackexchange.com/questions/167620/latexdiff-with-subfiles )
#    - --flatten: \bibliography commands expand if corresponding bbl file present
#    - angled bracket optional commands now parsed correctly (patch #3570) submitted by Dave Kleinschmidt (thanks)
#    - \RequirePackage now treated as synonym of \usepackage with respect to setting packages
#    - special rules for apacite package (redefine citation commands)
#    - recognise /dev/null as 'file-like' arguments for --preamble and --config options
#    - fix units package incompatibility with ulem for text maths statements $ ..$ (thanks to Stuart Prescott for reporting this)
#    - amsmath environment cases treated correctly (Bug fix #19029) (thanks to Jalar)
#    - {,} in comments no longer confuse latexdiff (Bug fix #19146)
#    - \% in one-letter sub/Superscripts was not converted correctly
#
# Version 1.0.3
#    - fix bug in add_safe_commands that made latexdiff hang on DeclareMathOperator 
#      command in preamble
#    - \(..\) inline math expressions were not parsed correctly, if they contained a linebreak
#    - applied patch contributed by tomflannaghan via Berlios: [ Patch #3431 ] Adds correct handling of \left< and \right>
#    - \$ is treated correctly as a literal dollar sign (thanks to Reed Cartwright and Joshua Miller for reporting this bug 
#      and sketching out the solution)
#    - \^ and \_ are correctly interpreted as accent and underlined space, respectively, not as superscript of subscript
#      (thanks to Wail Yahyaoui for pointing out this bug)
#
# Version 1.0.1 - treat \big,\bigg etc. equivalently to \left and
#              \right - include starred version in MATHENV - apply
#            - flatten recursively and --flatten expansion is now
#              aware of comments (thanks to Tim Connors for patch) 
#            - Change to post-processing for more reliability for
#              deleted math environments
#            - On linux systems, recognise  and remove DOS style newlines 
#            - Provide markup for some special preamble commands (\title,
#              \author,\date, 
#            - configurable by setting context2cmd 
#            - for styles using ulem package, remove \emph and \text.. from list of
#              safe commands in order to allow linebreaks within the
#              highlighted sections.  
#            - for ulem style, now show citations by enclosing them in \mbox commands. 
#              This unfortunately implies linebreaks within citations no longer function, 
#              so this functionality can be turned off (Option --disable-citation-markup). 
#              With --enable-citation-markup, the mbox markup is forced for other styles)
#            - new substyle COLOR.  This is particularly useful for marking up citations
#              and some special post-processing is implemented to retain cite
#              commands in deleted blocks.
#            - four different levels of math-markup
#            - Option --driver for choosing driver for modes employing changebar package
#            - accept \\* as valid command (and other commands of form \.*). Also accept
#              \<nl> (backslashed newline) 
#            - some typo fixes, include commands defined in preamble as safe commands
#              (Sebastian Gouezel) 
#            - include compared filenames as comments as line 2 and 3 of
#              the preamble (can be modified with option --label, and suppressed with 
#              --no-label), option --visible-label to show files in generated pdf or dvi
#              at the beginning of main document
#
# Version 0.5  A number of minor improvements based on feedback
#              Deleted blocks are now shown before added blocks
#              Package specific processing
#
# Version 0.43 unreleased typo in list of styles at the end
#              Add protect to all \cbstart, \cbend commands
#              More robust substitution of deleted math commands
#
# Version 0.42 November 06  Bug fixes only
#
# Version 0.4   March 06 option for fast differencing using UNIX diff command, several minor bug fixes (\par bug, improved highlighting of textcmds)
#
# Version 0.3   August 05 improved parsing of displayed math, --allow-spaces 
#               option, several minor bug fixes
#
# Version 0.25  October 04 Fix bug with deleted equations, add math mode commands to safecmd, add | to allowed interpunctuation signs
# Version 0.2   September 04 extension to utf-8 and variable encodings
# Version 0.1   August 04    First public release

# Inserted block for differenceing 
# use Algorithm::Diff qw(traverse_sequences);
# in standard version
# The following BEGIN block contains a verbatim copy of
# Ned Konz' Algorithm::Diff package version 1.15 except
# that subroutine _longestCommonSubsequence has been replace by 
# a routine which internally uses the UNIX diff command for
# the differencing rather than the Perl routines if the 
# length of the sequences exceeds some threshold.
# Also, all POD documentation has been stripped out.
#
# (the distribution on which this modification is based is available
#  from http://search.cpan.org/~nedkonz/Algorithm-Diff-1.15
#  the most recent version can be found via  http://search.cpan.org/search?module=Algorithm::Diff )
# Please note that the LICENCSE for Algorithm::Diff :
#   "Copyright (c) 2000-2002 Ned Konz.  All rights reserved.
#    This program is free software;
#    you can redistribute it and/or modify it under the same terms
#    as Perl itself."
# The fast-differencing version of latexdiff is provided as a convenience
# for latex users under Unix-like systems which have a 'diff' command.
# If you believe
# the inlining of Algorithm::Diff violates its license please contact
# me and I will modify the latexdiff distribution accordingly.
# Frederik Tilmann (tilmann@esc.cam.ac.uk)
# Jonathan Paisley is acknowledged for the idea of using the system diff
# command to achieve shorter running times
BEGIN { 
package Algorithm::Diff;
use strict;
use vars qw($VERSION @EXPORT_OK @ISA @EXPORT);
use integer;    # see below in _replaceNextLargerWith() for mod to make
                # if you don't use this
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw(LCS diff traverse_sequences traverse_balanced sdiff);
$VERSION = sprintf('%d.%02d fast', (q$Revision: 1.15 $ =~ /\d+/g));

# Global parameters

use File::Temp qw/tempfile/;
# if larger number of elements in longestCommonSubsequence smaller than
# this number, then use internal algorithm, otherwise use UNIX diff
use constant THRESHOLD => 100 ; 
# Detect whether diff --minimal option is available
# if yes we use it
use constant MINIMAL => ( system('diff','--minimal','/dev/null','/dev/null') >> 8 ==0 ? "--minimal" : "" ) ;



# McIlroy-Hunt diff algorithm
# Adapted from the Smalltalk code of Mario I. Wolczko, <mario@wolczko.com>
# by Ned Konz, perl@bike-nomad.com


# Create a hash that maps each element of $aCollection to the set of positions
# it occupies in $aCollection, restricted to the elements within the range of
# indexes specified by $start and $end.
# The fourth parameter is a subroutine reference that will be called to
# generate a string to use as a key.
# Additional parameters, if any, will be passed to this subroutine.
#
# my $hashRef = _withPositionsOfInInterval( \@array, $start, $end, $keyGen );

sub _withPositionsOfInInterval
{
	my $aCollection = shift;    # array ref
	my $start       = shift;
	my $end         = shift;
	my $keyGen      = shift;
	my %d;
	my $index;
	for ( $index = $start ; $index <= $end ; $index++ )
	{
		my $element = $aCollection->[$index];
		my $key = &$keyGen( $element, @_ );
		if ( exists( $d{$key} ) )
		{
			unshift ( @{ $d{$key} }, $index );
		}
		else
		{
			$d{$key} = [$index];
		}
	}
	return wantarray ? %d : \%d;
}

# Find the place at which aValue would normally be inserted into the array. If
# that place is already occupied by aValue, do nothing, and return undef. If
# the place does not exist (i.e., it is off the end of the array), add it to
# the end, otherwise replace the element at that point with aValue.
# It is assumed that the array's values are numeric.
# This is where the bulk (75%) of the time is spent in this module, so try to
# make it fast!

sub _replaceNextLargerWith
{
	my ( $array, $aValue, $high ) = @_;
	$high ||= $#$array;

	# off the end?
	if ( $high == -1 || $aValue > $array->[-1] )
	{
		push ( @$array, $aValue );
		return $high + 1;
	}

	# binary search for insertion point...
	my $low = 0;
	my $index;
	my $found;
	while ( $low <= $high )
	{
		$index = ( $high + $low ) / 2;

		#		$index = int(( $high + $low ) / 2);		# without 'use integer'
		$found = $array->[$index];

		if ( $aValue == $found )
		{
			return undef;
		}
		elsif ( $aValue > $found )
		{
			$low = $index + 1;
		}
		else
		{
			$high = $index - 1;
		}
	}

	# now insertion point is in $low.
	$array->[$low] = $aValue;    # overwrite next larger
	return $low;
}

# This method computes the longest common subsequence in $a and $b.

# Result is array or ref, whose contents is such that
# 	$a->[ $i ] == $b->[ $result[ $i ] ]
# foreach $i in ( 0 .. $#result ) if $result[ $i ] is defined.

# An additional argument may be passed; this is a hash or key generating
# function that should return a string that uniquely identifies the given
# element.  It should be the case that if the key is the same, the elements
# will compare the same. If this parameter is undef or missing, the key
# will be the element as a string.

# By default, comparisons will use "eq" and elements will be turned into keys
# using the default stringizing operator '""'.

# Additional parameters, if any, will be passed to the key generation routine.

sub _longestCommonSubsequence
{
	my $a      = shift;    # array ref
	my $b      = shift;    # array ref
	my $keyGen = shift;    # code ref
	my $compare;           # code ref

	# set up code refs
	# Note that these are optimized.
	if ( !defined($keyGen) )    # optimize for strings
	{
		$keyGen = sub { $_[0] };
		$compare = sub { my ( $a, $b ) = @_; $a eq $b };
	}
	else
	{
		$compare = sub {
			my $a = shift;
			my $b = shift;
			&$keyGen( $a, @_ ) eq &$keyGen( $b, @_ );
		};
	}

	my ( $aStart, $aFinish, $bStart, $bFinish, $matchVector ) =
	  ( 0, $#$a, 0, $#$b, [] );

	# Check whether to use internal routine (small number of elements)
	# or use it as a wrapper for UNIX diff
	if ( ( $#$a > $#$b ?  $#$a : $#$b) < THRESHOLD ) {
	  ###	  print STDERR "DEBUG: regular longestCommonSubsequence\n";
	  # First we prune off any common elements at the beginning
	  while ( $aStart <= $aFinish
		  and $bStart <= $bFinish
		  and &$compare( $a->[$aStart], $b->[$bStart], @_ ) )
	    {
	      $matchVector->[ $aStart++ ] = $bStart++;
	    }

	  # now the end
	  while ( $aStart <= $aFinish
		and $bStart <= $bFinish
		and &$compare( $a->[$aFinish], $b->[$bFinish], @_ ) )
	    {
	      $matchVector->[ $aFinish-- ] = $bFinish--;
	    }

	  # Now compute the equivalence classes of positions of elements
	  my $bMatches =
	    _withPositionsOfInInterval( $b, $bStart, $bFinish, $keyGen, @_ );
	  my $thresh = [];
	  my $links  = [];
	  
	  my ( $i, $ai, $j, $k );
	  for ( $i = $aStart ; $i <= $aFinish ; $i++ )
	    {
	      $ai = &$keyGen( $a->[$i], @_ );
	      if ( exists( $bMatches->{$ai} ) )
		{
		  $k = 0;
		  for $j ( @{ $bMatches->{$ai} } )
		    {
		      
		      # optimization: most of the time this will be true
		      if ( $k and $thresh->[$k] > $j and $thresh->[ $k - 1 ] < $j )
			{
			  $thresh->[$k] = $j;
			}
		      else
			{
			  $k = _replaceNextLargerWith( $thresh, $j, $k );
			}
		      
		      # oddly, it's faster to always test this (CPU cache?).
		      if ( defined($k) )
			{
			  $links->[$k] =
			    [ ( $k ? $links->[ $k - 1 ] : undef ), $i, $j ];
			}
		    }
		}
	    }

	  if (@$thresh)
	    {
	      for ( my $link = $links->[$#$thresh] ; $link ; $link = $link->[0] )
		{
		  $matchVector->[ $link->[1] ] = $link->[2];
		}
	    }
	}
	else {
	  my ($fha,$fhb,$fna,$fnb,$ele,$key);
	  my ($alines,$blines,$alb,$alf,$blb,$blf);
	  my ($minimal)=MINIMAL;
	  # large number of elements, use system diff
	  ###	  print STDERR "DEBUG: fast (diff) longestCommonSubsequence\n";

	  ($fha,$fna)=tempfile("DiffA-XXXX") or die "_longestCommonSubsequence: Cannot open tempfile for sequence A";
	  ($fhb,$fnb)=tempfile("DiffB-XXXX") or die "_longestCommonSubsequence: Cannot open tempfile for sequence B";
	  # prepare sequence A
	  foreach $ele ( @$a ) {
	    $key=&$keyGen( $ele, @_ );
	    $key =~ s/\\/\\\\/g ;
	    $key =~ s/\n/\\n/sg ;
	    print $fha "$key\n" ;
	  }
	  close($fha);
	  # prepare sequence B
	  foreach $ele ( @$b ) {
	    $key=&$keyGen( $ele, @_ );
	    $key =~ s/\\/\\\\/g ;
	    $key =~ s/\n/\\n/sg ;
	    print $fhb "$key\n" ;
	  }
	  close($fhb);
	  
	  open(DIFFPIPE, "diff $minimal $fna $fnb |") or die "_longestCommonSubsequence: Cannot launch diff process. $!" ;
	  # The diff line numbering begins with 1, but Perl subscripts start with 0
	  # We follow the diff numbering but substract 1 when assigning to matchVector
	  $aStart++; $bStart++ ; $aFinish++ ; $bFinish++ ;
	  while( <DIFFPIPE> ) {
	    if ( ($alines,$blines) = ( m/^(\d*(?:,\d*)?)?c(\d*(?:,\d*)?)?$/ ) ) {
	      ($alb,$alf)=split(/,/,$alines);
	      ($blb,$blf)=split(/,/,$blines);
	      $alf=$alb unless defined($alf);
	      $blf=$blb unless defined($blf);
	      while($aStart < $alb ) {
		$matchVector->[ -1 + $aStart++ ] = -1 + $bStart++ ;
	      }
	      # check for consistency
	      $bStart==$blb or die "_longestCommonSubsequence: Fatal error in interpreting diff output: Inconsistency in changed sequence";
	      $aStart=$alf+1;
	      $bStart=$blf+1;
	    }
	    elsif ( ($alb,$blines) = ( m/^(\d*)a(\d*(?:,\d*)?)$/ ) ) {
	      ($blb,$blf)=split(/,/,$blines);
	      $blf=$blb unless defined($blf);
	      while ( $bStart < $blb ) {
		$matchVector->[ -1 + $aStart++ ] = -1 + $bStart++ ;
	      }
	      $aStart==$alb+1 or die "_longestCommonSubsequence: Fatal error in interpreting diff output: Inconsistency in appended sequence near elements $aStart and $bStart";
	      $bStart=$blf+1;
	    }
	    elsif ( ($alines,$blb) = ( m/^(\d*(?:,\d*)?)d(\d*)$/ ) ) {
	      ($alb,$alf)=split(/,/,$alines);
	      $alf=$alb unless defined($alf);
	      while ( $aStart < $alb ) {
		$matchVector->[ -1 + $aStart++ ] = -1 + $bStart++ ;
	      }
	      $bStart==$blb+1 or die "_longestCommonSubsequence: Fatal error in interpreting diff output: Inconsistency in deleted sequence near elements $aStart and $bStart";
	      $aStart=$alf+1;
	    }
	    elsif ( m/^Binary files/ ) {
	      # if diff reports it is a binary file force --text mode. I do not like
	      # to always use this option because it is probably only available in GNU diff
	      open(DIFFPIPE, "diff --text $fna $fnb |") or die "Cannot launch diff process. $!" ;
	    }
	    # Default: just skip line
	  }
	  while ($aStart <= $aFinish ) {
	    $matchVector->[ -1 + $aStart++ ] = -1 + $bStart++ ;
	  }
	  $bStart==$bFinish+1  or die "_longestCommonSubsequence: Fatal error in interpreting diff output: Inconsistency at end";
	  close DIFFPIPE;
	  # check whether a system error has occurred or return status is greater than or equal to 5
	  if ( $! || ($? >> 8) > 5) {
	    print STDERR "diff process failed with exit code ", ($? >> 8), " $!\n";
	    die;
	  }
	  unlink $fna,$fnb ;
	}
	return wantarray ? @$matchVector : $matchVector;
}

sub traverse_sequences
{
	my $a                 = shift;                                  # array ref
	my $b                 = shift;                                  # array ref
	my $callbacks         = shift || {};
	my $keyGen            = shift;
	my $matchCallback     = $callbacks->{'MATCH'} || sub { };
	my $discardACallback  = $callbacks->{'DISCARD_A'} || sub { };
	my $finishedACallback = $callbacks->{'A_FINISHED'};
	my $discardBCallback  = $callbacks->{'DISCARD_B'} || sub { };
	my $finishedBCallback = $callbacks->{'B_FINISHED'};
	my $matchVector = _longestCommonSubsequence( $a, $b, $keyGen, @_ );

	# Process all the lines in @$matchVector
	my $lastA = $#$a;
	my $lastB = $#$b;
	my $bi    = 0;
	my $ai;

	for ( $ai = 0 ; $ai <= $#$matchVector ; $ai++ )
	{
		my $bLine = $matchVector->[$ai];
		if ( defined($bLine) )    # matched
		{
			&$discardBCallback( $ai, $bi++, @_ ) while $bi < $bLine;
			&$matchCallback( $ai,    $bi++, @_ );
		}
		else
		{
			&$discardACallback( $ai, $bi, @_ );
		}
	}

	# The last entry (if any) processed was a match.
	# $ai and $bi point just past the last matching lines in their sequences.

	while ( $ai <= $lastA or $bi <= $lastB )
	{

		# last A?
		if ( $ai == $lastA + 1 and $bi <= $lastB )
		{
			if ( defined($finishedACallback) )
			{
				&$finishedACallback( $lastA, @_ );
				$finishedACallback = undef;
			}
			else
			{
				&$discardBCallback( $ai, $bi++, @_ ) while $bi <= $lastB;
			}
		}

		# last B?
		if ( $bi == $lastB + 1 and $ai <= $lastA )
		{
			if ( defined($finishedBCallback) )
			{
				&$finishedBCallback( $lastB, @_ );
				$finishedBCallback = undef;
			}
			else
			{
				&$discardACallback( $ai++, $bi, @_ ) while $ai <= $lastA;
			}
		}

		&$discardACallback( $ai++, $bi, @_ ) if $ai <= $lastA;
		&$discardBCallback( $ai, $bi++, @_ ) if $bi <= $lastB;
	}

	return 1;
}

sub traverse_balanced
{
	my $a                 = shift;                                  # array ref
	my $b                 = shift;                                  # array ref
	my $callbacks         = shift || {};
	my $keyGen            = shift;
	my $matchCallback     = $callbacks->{'MATCH'} || sub { };
	my $discardACallback  = $callbacks->{'DISCARD_A'} || sub { };
	my $discardBCallback  = $callbacks->{'DISCARD_B'} || sub { };
	my $changeCallback    = $callbacks->{'CHANGE'};
	my $matchVector = _longestCommonSubsequence( $a, $b, $keyGen, @_ );

	# Process all the lines in match vector
	my $lastA = $#$a;
	my $lastB = $#$b;
	my $bi    = 0;
	my $ai    = 0;
	my $ma    = -1;
	my $mb;

	while (1)
	{

		# Find next match indices $ma and $mb
		do { $ma++ } while ( $ma <= $#$matchVector && !defined $matchVector->[$ma] );

		last if $ma > $#$matchVector;    # end of matchVector?
		$mb = $matchVector->[$ma];

		# Proceed with discard a/b or change events until
		# next match
		while ( $ai < $ma || $bi < $mb )
		{

			if ( $ai < $ma && $bi < $mb )
			{

				# Change
				if ( defined $changeCallback )
				{
					&$changeCallback( $ai++, $bi++, @_ );
				}
				else
				{
					&$discardACallback( $ai++, $bi, @_ );
					&$discardBCallback( $ai, $bi++, @_ );
				}
			}
			elsif ( $ai < $ma )
			{
				&$discardACallback( $ai++, $bi, @_ );
			}
			else
			{

				# $bi < $mb
				&$discardBCallback( $ai, $bi++, @_ );
			}
		}

		# Match
		&$matchCallback( $ai++, $bi++, @_ );
	}

	while ( $ai <= $lastA || $bi <= $lastB )
	{
		if ( $ai <= $lastA && $bi <= $lastB )
		{

			# Change
			if ( defined $changeCallback )
			{
				&$changeCallback( $ai++, $bi++, @_ );
			}
			else
			{
				&$discardACallback( $ai++, $bi, @_ );
				&$discardBCallback( $ai, $bi++, @_ );
			}
		}
		elsif ( $ai <= $lastA )
		{
			&$discardACallback( $ai++, $bi, @_ );
		}
		else
		{

			# $bi <= $lastB
			&$discardBCallback( $ai, $bi++, @_ );
		}
	}

	return 1;
}

sub LCS
{
	my $a = shift;                                           # array ref
	my $matchVector = _longestCommonSubsequence( $a, @_ );
	my @retval;
	my $i;
	for ( $i = 0 ; $i <= $#$matchVector ; $i++ )
	{
		if ( defined( $matchVector->[$i] ) )
		{
			push ( @retval, $a->[$i] );
		}
	}
	return wantarray ? @retval : \@retval;
}

sub diff
{
	my $a      = shift;    # array ref
	my $b      = shift;    # array ref
	my $retval = [];
	my $hunk   = [];
	my $discard = sub { push ( @$hunk, [ '-', $_[0], $a->[ $_[0] ] ] ) };
	my $add = sub { push ( @$hunk, [ '+', $_[1], $b->[ $_[1] ] ] ) };
	my $match = sub { push ( @$retval, $hunk ) if scalar(@$hunk); $hunk = [] };
	traverse_sequences( $a, $b,
		{ MATCH => $match, DISCARD_A => $discard, DISCARD_B => $add }, @_ );
	&$match();
	return wantarray ? @$retval : $retval;
}

sub sdiff
{
	my $a      = shift;    # array ref
	my $b      = shift;    # array ref
	my $retval = [];
	my $discard = sub { push ( @$retval, [ '-', $a->[ $_[0] ], "" ] ) };
	my $add = sub { push ( @$retval, [ '+', "", $b->[ $_[1] ] ] ) };
	my $change = sub {
		push ( @$retval, [ 'c', $a->[ $_[0] ], $b->[ $_[1] ] ] );
	};
	my $match = sub {
		push ( @$retval, [ 'u', $a->[ $_[0] ], $b->[ $_[1] ] ] );
	};
	traverse_balanced(
		$a,
		$b,
		{
			MATCH     => $match,
			DISCARD_A => $discard,
			DISCARD_B => $add,
			CHANGE    => $change,
		},
		@_
	);
	return wantarray ? @$retval : $retval;
}

1;
}
import Algorithm::Diff qw(traverse_sequences);
# End of inserted block for stand-alone version


use Getopt::Long ;
use strict ;
use warnings;
use utf8 ;

my ($algodiffversion)=split(/ /,$Algorithm::Diff::VERSION);


my ($versionstring)=<<EOF ;
This is LATEXDIFF 1.2.1  (Algorithm::Diff $Algorithm::Diff::VERSION, Perl $^V)
  (c) 2004-2017 F J Tilmann
EOF

# Hash with defaults for configuration variables. These marked undef have default values constructed from list defined in the DATA block
# (under tag CONFIG)
my %CONFIG=(
   MINWORDSBLOCK => 3, # minimum number of tokens to form an independent block
                        # shorter identical blocks will be merged to the previous word
   SCALEDELGRAPHICS => 0.5, # factor with which deleted figures will be scaled down (i.e. 0.5 implies they are shown at half linear size)
                             # this is only used for --graphics-markup=BOTH option
   FLOATENV => undef ,   # Environments in which FL variants of defined commands are used
   PICTUREENV => undef ,   # Environments in which all change markup is removed
   MATHENV => undef ,           # Environments turning on display math mode (code also knows about \[ and \])
   MATHREPL => 'displaymath',  # Environment introducing deleted maths blocks
   MATHARRENV => undef ,           # Environments turning on eqnarray math mode
   MATHARRREPL => 'eqnarray*',  # Environment introducing deleted maths blocks
   ARRENV => undef , # Environments making arrays in math mode.  The underlining style does not cope well with those - as a result in-text math environments are surrounded by \mbox{ } if any of these commands is used in an inline math block
   COUNTERCMD => undef,
                                        # COUNTERCMD textcmds which are associated with a counter
                                        # If any of these commands occur in a deleted block
                                        # they will be succeeded by an \addtocounter{...}{-1}
                                        # for the associated counter such that the overall numbers
                                        # should be the same as in the new file
   LISTENV => undef ,  # list making environments - they will generally be kept
   VERBATIMENV => undef,    # Environments whose content should be treated as verbatim text 
   ITEMCMD => 'item'                    # command marking item in a list environment
);
# Configuration variables: these have to be visible from the subroutines
my ($ARRENV,
    $COUNTERCMD,
    $FLOATENV,
    $ITEMCMD,
    $LISTENV,
    $MATHARRENV,
    $MATHARRREPL,
    $MATHENV,
    $MATHREPL,
    $MINWORDSBLOCK,
    $PICTUREENV,
    $SCALEDELGRAPHICS,
    $VERBATIMENV
);

# my $MINWORDSBLOCK=3; # minimum number of tokens to form an independent block
#                      # shorter identical blocks will be merged to the previous word
# my $SCALEDELGRAPHICS=0.5; # factor with which deleted figures will be scaled down (i.e. 0.5 implies they are shown at half linear size)
#                       # this is only used for --graphics-markup=BOTH option
# my $FLOATENV='(?:figure|table|plate)[\w\d*@]*' ;   # Environments in which FL variants of defined commands are used
# my $PICTUREENV='(?:picture|tikzpicture|DIFnomarkup)[\w\d*@]*' ;   # Environments in which all change markup is removed
# my $MATHENV='(?:equation[*]?|displaymath|DOLLARDOLLAR)[*]?' ;           # Environments turning on display math mode (code also knows about \[ and \])
# my $MATHREPL='displaymath';  # Environment introducing deleted maths blocks
# my $MATHARRENV='(?:eqnarray|align|alignat|gather|multline|flalign)[*]?' ;           # Environments turning on eqnarray math mode
# my $MATHARRREPL='eqnarray*';  # Environment introducing deleted maths blocks
# my $ARRENV='(?:aligned|array|[pbvBV]?matrix|smallmatrix|cases|split)'; # Environments making arrays in math mode.  The underlining style does not cope well with those - as a result in-text math environments are surrounded by \mbox{ } if any of these commands is used in an inline math block
# my $COUNTERCMD='(?:footnote|part|chapter|section|subsection|subsubsection|paragraph|subparagraph)';  # textcmds which are associated with a counter
#                                         # If any of these commands occur in a deleted block
#                                         # they will be succeeded by an \addtocounter{...}{-1}
#                                         # for the associated counter such that the overall numbers
#                                         # should be the same as in the new file
# my $LISTENV='(?:itemize|description|enumerate)'; # list making environments - they will generally be kept
# my $ITEMCMD='item';   # command marking item in a list environment



my $LABELCMD='(?:label)';                # matching commands are disabled within deleted blocks - mostly useful for maths mode, as otherwise it would be fine to just not add those to SAFECMDLIST
my @UNSAFEMATHCMD=('qedhere');           # Commands which are definitely unsafe for marking up in math mode (amsmath qedhere only tested to not work with UNDERLINE markup) (only affects WHOLE and COARSE math markup modes). Note that unlike text mode (or FINE math mode0 deleted unsafe commands are not deleted but simply taken outside \DIFdel
my $MBOXINLINEMATH=0; # if set to 1 then surround marked-up inline maths expression with \mbox ( to get around compatibility
                      # problems between some maths packages and ulem package


# Markup strings
# If at all possible, do not change these as parts of the program
# depend on the actual name (particularly post-processing)
# At the very least adapt subroutine postprocess to new tokens.
my $ADDMARKOPEN='\DIFaddbegin ';   # Token to mark begin of appended text
my $ADDMARKCLOSE='\DIFaddend ';   # Token to mark end of appended text
my $ADDOPEN='\DIFadd{';  # To mark begin of added text passage
my $ADDCLOSE='}';        # To mark end of added text passage
my $ADDCOMMENT='DIF > ';   # To mark added comment line
my $DELMARKOPEN='\DIFdelbegin ';   # Token to mark begin of deleted text
my $DELMARKCLOSE='\DIFdelend ';   # Token to mark end of deleted text
my $DELOPEN='\DIFdel{';  # To mark begin of deleted text passage
my $DELCLOSE='}';        # To mark end of deleted text passage
my $DELCMDOPEN='%DIFDELCMD < ';  # To mark begin of deleted commands (must begin with %, i.e., be a comment
my $DELCMDCLOSE="%%%\n";    # To mark end of deleted commands (must end with a new line)
my $AUXCMD='%DIFAUXCMD' ; #  follows auxiliary commands put in by latexdiff to make difference file legal
                          # auxiliary commands must be on a line of their own
my $DELCOMMENT='DIF < ';   # To mark deleted comment line


# main local variables:
my @TEXTCMDLIST=();  # array containing patterns of commands with text arguments
my @TEXTCMDEXCL=();  # array containing patterns of commands without text arguments (if a pattern
                     # matches both TEXTCMDLIST and TEXTCMDEXCL it is excluded)
my @CONTEXT1CMDLIST=();  # array containing patterns of commands with text arguments (subset of text commands),
                         # but which cause confusion if used out of context (e.g. \caption). 
                         # In deleted passages, the command will be disabled but its argument is marked up
                         # Otherwise they behave exactly like TEXTCMD's 
my @CONTEXT1CMDEXCL=();  # exclude list for above, but always empty
my @CONTEXT2CMDLIST=();  # array containing patterns of commands with text arguments, but which fail or cause confusion
                         # if used out of context (e.g. \title). They and their arguments will be disabled in deleted
                         # passages
my @CONTEXT2CMDEXCL=();  # exclude list for above, but always empty
my @MATHTEXTCMDLIST=();  # treat like textcmd.  If a textcmd is in deleted or added block, just wrap the
                         # whole content with \DIFadd or \DIFdel irrespective of content.  This functionality 
                         # is useful for pseudo commands \MATHBLOCK.. into which math environments are being
                         # transformed 
my @MATHTEXTCMDEXCL=();  # 

# Note I need to declare this with "our" instead of "my" because later in the code I have to "local"ise these  
our @SAFECMDLIST=();  # array containing patterns of safe commands (which do not break when in the argument of DIFadd or DIFDEL)
our @SAFECMDEXCL=();
my @MBOXCMDLIST=();   # patterns for commands which are in principle safe but which need to be surrounded by an \mbox
my @MBOXCMDEXCL=();           # all the patterns in MBOXCMDLIST will be appended to SAFECMDLIST


my ($i,$j,$l);
my ($old,$new);
my ($line,$key);
my (@dumlist);
my ($newpreamble,$oldpreamble);
my (@newpreamble,@oldpreamble,@diffpreamble,@diffbody);
my ($latexdiffpreamble);
my ($oldbody, $newbody, $diffbo);
my ($oldpost, $newpost);
my ($diffall);
# Option names
my ($type,$subtype,$floattype,$config,$preamblefile,$encoding,$nolabel,$visiblelabel,
    $showpreamble,$showsafe,$showtext,$showconfig,$showall,
    $replacesafe,$appendsafe,$excludesafe,
    $replacetext,$appendtext,$excludetext,
    $replacecontext1,$appendcontext1,
    $replacecontext2,$appendcontext2,
    $help,$verbose,$driver,$version,$ignorewarnings,
    $enablecitmark,$disablecitmark,$allowspaces,$flatten,$debug,$earlylatexdiffpreamble);  ###$disablemathmark,
my ($mboxsafe);
# MNEMNONICS for mathmarkup
my $mathmarkup;
use constant {
  OFF => 0,
  WHOLE => 1,
  COARSE => 2,
  FINE => 3
};
# MNEMNONICS for graphicsmarkup
my $graphicsmarkup;
use constant {
  NONE => 0,
  NEWONLY => 1,
  BOTH => 2
};

my ($mboxcmd);

my (@configlist,@addtoconfiglist,@labels,
    @appendsafelist,@excludesafelist,
    @appendmboxsafelist,@excludemboxsafelist,
    @appendtextlist,@excludetextlist,
    @appendcontext1list,@appendcontext2list,
    @packagelist);
my ($assign,@config);
# Hash where keys corresponds to the names of  all included packages (including the documentclass as another package
# the optional arguments to the package are the values of the hash elements
my ($pkg,%packages);

# Defaults
$mathmarkup=COARSE;
$verbose=0;
# output debug and intermediate files, set to 0 in final distribution
$debug=0; 
# insert preamble directly after documentclass - experimental feature, set to 0 in final distribution
# Note that this failed with mini example (or other files, where packages used in latexdiff preamble
# are called again with incompatible options in preamble of resulting file)
$earlylatexdiffpreamble=0;


# define character properties
sub IsNonAsciiPunct { return <<'END'    # Unicode punctuation but excluding ASCII punctuation
+utf8::IsPunct
-utf8::IsASCII
END
}
sub IsNonAsciiS { return <<'END'       # Unicode symbol but excluding ASCII
+utf8::IsS
-utf8::IsASCII
END
}


my %verbhash;

Getopt::Long::Configure('bundling');
GetOptions('type|t=s' => \$type, 
	   'subtype|s=s' => \$subtype, 
	   'floattype|f=s' => \$floattype, 
	   'config|c=s' => \@configlist,
	   'add-to-config|c=s' => \@addtoconfiglist,
	   'preamble|p=s' => \$preamblefile,
	   'encoding|e=s' => \$encoding,
	   'label|L=s' => \@labels,
	   'no-label' => \$nolabel,
	   'visible-label' => \$visiblelabel,
	   'exclude-safecmd|A=s' => \@excludesafelist,
	   'replace-safecmd=s' => \$replacesafe,
	   'append-safecmd|a=s' => \@appendsafelist,
	   'exclude-textcmd|X=s' => \@excludetextlist,
	   'replace-textcmd=s' => \$replacetext,
	   'append-textcmd|x=s' => \@appendtextlist,
	   'replace-context1cmd=s' => \$replacecontext1,
	   'append-context1cmd=s' => \@appendcontext1list,
	   'replace-context2cmd=s' => \$replacecontext2,
	   'append-context2cmd=s' => \@appendcontext2list,
	   'exclude-mboxsafecmd=s' => \@excludemboxsafelist,
	   'append-mboxsafecmd=s' => \@appendmboxsafelist,
	   'show-preamble' => \$showpreamble,
	   'show-safecmd' => \$showsafe,
	   'show-textcmd' => \$showtext,
	   'show-config' => \$showconfig,
	   'show-all' => \$showall,
           'packages=s' => \@packagelist,
	   'allow-spaces' => \$allowspaces,
           'math-markup=s' => \$mathmarkup,
           'graphics-markup=s' => \$graphicsmarkup,
           'enable-citation-markup|enforce-auto-mbox' => \$enablecitmark,
           'disable-citation-markup|disable-auto-mbox' => \$disablecitmark,
	   'verbose|V' => \$verbose,
	   'ignore-warnings' => \$ignorewarnings,
	   'driver=s'=> \$driver,
	   'flatten' => \$flatten,
	   'version' => \$version,
	   'help|h' => \$help,
	   'debug!' => \$debug );

if ( $help ) {
  usage() ;
}


if ( $version ) {
  die $versionstring ; 
}

print STDERR $versionstring if $verbose; 

if (defined($showall)){
  $showpreamble=$showsafe=$showtext=$showconfig=1;
}
# Default types
$type='UNDERLINE' unless defined($type);
$subtype='SAFE' unless defined($subtype);
# set floattype to IDENTICAL for LABEL and ONLYCHANGEDPAGE subtype, unless it has been set explicitly on the command line
$floattype=($subtype eq 'LABEL' || $subtype eq 'ONLYCHANGEDPAGE') ? 'IDENTICAL' : 'FLOATSAFE' unless defined($floattype);
if ( $subtype eq 'LABEL' ) {
  print STDERR "Note that LABEL subtype is deprecated. If possible, use ZLABEL instead (requires zref package)";
}

if (defined($mathmarkup)) {
  $mathmarkup=~tr/a-z/A-Z/;
  if ( $mathmarkup eq 'OFF' ){
    $mathmarkup=OFF;
  } elsif ( $mathmarkup eq 'WHOLE' ){ 
    $mathmarkup=WHOLE;
  } elsif ( $mathmarkup eq 'COARSE' ){
    $mathmarkup=COARSE;
  } elsif ( $mathmarkup eq 'FINE' ){
    $mathmarkup=FINE;
  } elsif ( $mathmarkup !~ m/^[0123]$/ ) {
    die "latexdiff Illegal value: ($mathmarkup)  for option--math-markup. Possible values: OFF,WHOLE,COARSE,FINE,0-3\n";
  }
  # else use numerical value
}



# setting extra preamble commands
if (defined($preamblefile)) {
  $latexdiffpreamble=join "\n",(extrapream($preamblefile),"");
} else {
  $latexdiffpreamble=join "\n",(extrapream($type,$subtype,$floattype),"");
}

if ( defined($driver) ) {
  # for changebar only
  $latexdiffpreamble=~s/\[dvips\]/[$driver]/sg;
}
# setting up @SAFECMDLIST and @SAFECMDEXCL
if (defined($replacesafe)) {
  init_regex_arr_ext(\@SAFECMDLIST,$replacesafe);
} else {
  init_regex_arr_data(\@SAFECMDLIST, "SAFE COMMANDS");
}
foreach $appendsafe ( @appendsafelist ) {
  init_regex_arr_ext(\@SAFECMDLIST, $appendsafe);
}
foreach $excludesafe ( @excludesafelist ) {
  init_regex_arr_ext(\@SAFECMDEXCL, $excludesafe);
}
# setting up @MBOXCMDLIST and @MBOXCMDEXCL
foreach $mboxsafe ( @appendmboxsafelist ) {
  init_regex_arr_ext(\@MBOXCMDLIST, $mboxsafe);
}
foreach $mboxsafe ( @excludemboxsafelist ) {
  init_regex_arr_ext(\@MBOXCMDEXCL, $mboxsafe);
}



# setting up @TEXTCMDLIST and @TEXTCMDEXCL
if (defined($replacetext)) {
  init_regex_arr_ext(\@TEXTCMDLIST,$replacetext);
} else {
  init_regex_arr_data(\@TEXTCMDLIST, "TEXT COMMANDS");
}
foreach $appendtext ( @appendtextlist ) {
  init_regex_arr_ext(\@TEXTCMDLIST, $appendtext);
}
foreach $excludetext ( @excludetextlist ) {
  init_regex_arr_ext(\@TEXTCMDEXCL, $excludetext);
}


# setting up @CONTEXT1CMDLIST ( @CONTEXT1CMDEXCL exist but is always empty )
if (defined($replacecontext1)) {
  init_regex_arr_ext(\@CONTEXT1CMDLIST,$replacecontext1);
} else {
  init_regex_arr_data(\@CONTEXT1CMDLIST, "CONTEXT1 COMMANDS");
}
foreach $appendcontext1 ( @appendcontext1list ) {
  init_regex_arr_ext(\@CONTEXT1CMDLIST, $appendcontext1);
}


# setting up @CONTEXT2CMDLIST ( @CONTEXT2CMDEXCL exist but is always empty )
if (defined($replacecontext2)) {
  init_regex_arr_ext(\@CONTEXT2CMDLIST,$replacecontext2);
} else {
  init_regex_arr_data(\@CONTEXT2CMDLIST, "CONTEXT2 COMMANDS");
}
foreach $appendcontext2 ( @appendcontext2list ) {
  init_regex_arr_ext(\@CONTEXT2CMDLIST, $appendcontext2);
}

# setting configuration variables
@config=();
foreach $config ( @configlist ) {
  if (-f $config || lc $config eq '/dev/null' ) {
    open(FILE,$config) or die ("Couldn't open configuration file $config: $!");
    while (<FILE>) {
      chomp;
      next if /^\s*#/ || /^\s*%/ || /^\s*$/ ;
      push (@config,$_);
    }
    close(FILE);
  }
  else {
#    foreach ( split(",",$config) ) {
#      push @config,$_;
#    }
     push @config,split(",",$config)
  }
}
foreach $assign ( @config ) {
  $assign=~ m/\s*(\w*)\s*=\s*(\S*)\s*$/ or die "Illegal assignment $assign in configuration list (must be variable=value)";  
  exists $CONFIG{$1} or die "Unknown configuration variable $1.";
  $CONFIG{$1}=$2;
}

my @addtoconfig=();
foreach $config ( @addtoconfiglist ) {
  if (-f $config || lc $config eq '/dev/null' ) {
    open(FILE,$config) or die ("Couldn't open addd-to-config file $config: $!");
    while (<FILE>) {
      chomp;
      next if /^\s*#/ || /^\s*%/ || /^\s*$/ ;
      push (@addtoconfig,$_);
    }
    close(FILE);
  }
  else {
#    foreach ( split(",",$config) ) {
#      push @addtoconfig,$_;
#    }
     push @addtoconfig,split(",",$config)
  }
}

# initialise default lists from DATA
# for those configuration variables, which have not been set explicitly, initiate from list in document
foreach $key ( keys(%CONFIG) ) {
  if (!defined $CONFIG{$key}) {
    @dumlist=();
    init_regex_arr_data(\@dumlist,"$key CONFIG");
    $CONFIG{$key}=join(";",@dumlist)
  }
}


foreach $assign ( @addtoconfig ) {
  $assign=~ m/\s*(\w*)\s*=\s*(\S*)\s*$/ or die "Illegal assignment $assign in configuration list (must be variable=value)";  
  exists $CONFIG{$1} or die "Unknown configuration variable $1.";
  $CONFIG{$1}.=";$2";
}

# Map from hash to variables (we do this to have more concise code later, change from comma-separeted list)
foreach  ( keys(%CONFIG) ) {
  if ( $_ eq "MINWORDSBLOCK" ) { $MINWORDSBLOCK = $CONFIG{$_}; }
  elsif ( $_ eq "FLOATENV" ) { $FLOATENV = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "ITEMCMD" ) { $ITEMCMD = $CONFIG{$_} ; }
  elsif ( $_ eq "LISTENV" ) { $LISTENV = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "PICTUREENV" ) { $PICTUREENV = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "MATHENV" ) { $MATHENV = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "MATHREPL" ) { $MATHREPL = $CONFIG{$_} ; }
  elsif ( $_ eq "MATHARRENV" ) { $MATHARRENV = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "MATHARRREPL" ) { $MATHARRREPL = $CONFIG{$_} ; }
  elsif ( $_ eq "ARRENV" ) { $ARRENV = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "VERBATIMENV" ) { $VERBATIMENV = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "COUNTERCMD" ) { $COUNTERCMD = liststringtoregex($CONFIG{$_}) ; }
  elsif ( $_ eq "SCALEDELGRAPHICS" ) { $SCALEDELGRAPHICS = $CONFIG{$_} ; }
  else { die "Unknown configuration variable $_.";}
}

if ( $mathmarkup == COARSE || $mathmarkup == WHOLE ) {
  push(@MATHTEXTCMDLIST,qr/^MATHBLOCK(?:$MATHENV|$MATHARRENV|SQUAREBRACKET)$/);
}



foreach $pkg ( @packagelist ) {
  map { $packages{$_}="" } split(/,/,$pkg) ;
}



if ($showconfig || $showtext || $showsafe || $showpreamble) {
  show_configuration();
  exit 0; 
}

if ( @ARGV != 2 ) { 
  print STDERR "2 and only 2 non-option arguments required.  Write latexdiff -h to get help\n";
  exit(2);
}

# Are extra spaces between command arguments permissible?
my $extraspace;
if ($allowspaces) {
  $extraspace='\s*'; 
} else {
  $extraspace='';
}

# append context lists to text lists (as text property is implied)
push @TEXTCMDLIST, @CONTEXT1CMDLIST;
push @TEXTCMDLIST, @CONTEXT2CMDLIST;

push @TEXTCMDLIST, @MATHTEXTCMDLIST if $mathmarkup==COARSE;

# internal additions to SAFECMDLIST
push(@SAFECMDLIST, qr/^QLEFTBRACE$/, qr/^QRIGHTBRACE$/);


# Patterns. These are used by some of the subroutines, too
# I can only define them down here because value of extraspace depends on an option

  my $pat0 = '(?:[^{}])*';
  my $pat_n = $pat0;
# if you get "undefined control sequence MATHBLOCKmath" error, increase the maximum value in this loop
  for (my $i_pat = 0; $i_pat < 20; ++$i_pat){
    $pat_n = '(?:[^{}]|\{'.$pat_n.'\})*';
  }

  my $brat0 = '(?:[^\[\]]|\\\[|\\\])*'; 
  my $abrat0 = '(?:[^<>])*';

  my $quotemarks = '(?:\'\')|(?:\`\`)';
  my $punct='[0.,\/\'\`:;\"\?\(\)\[\]!~\p{IsNonAsciiPunct}\p{IsNonAsciiS}]';
  my $number='-?\d*\.\d*';
  my $mathpunct='[+=<>\-\|]';
  my $and = '&';
  my $coords= '[\-.,\s\d]*';
# quoted underscore - this needs special treatment as perl treats _ as a letter (\w) but latex does not
# such that a\_b is interpreted as a{\_}b by latex but a{\_b} by perl
  my $quotedunderscore='\\\\_';
# word: sequence of letters or accents followed by letter
  my $word_ja='\p{Han}+|\p{InHiragana}+|\p{InKatakana}+';
  my $word='(?:' . $word_ja . '|(?:(?:[-\w\d*]|\\\\[\"\'\`~^][A-Za-z\*])(?!(?:' . $word_ja . ')))+)';
  my $cmdleftright='\\\\(?:left|right|[Bb]igg?[lrm]?|middle)\s*(?:[<>()\[\]|\.]|\\\\(?:[|{}]|\w+))';
  my $cmdoptseq='\\\\[\w\d@\*]+'.$extraspace.'(?:(?:<'.$abrat0.'>|\['.$brat0.'\]|\{'. $pat_n . '\}|\(' . $coords .'\))'.$extraspace.')*';
  my $backslashnl='\\\\\n';
  my $oneletcmd='\\\\.\*?(?:\['.$brat0.'\]|\{'. $pat_n . '\})*';
  my $math='\$(?:[^$]|\\\$)*?\$|\\\\[(](?:.|\n)*?\\\\[)]';
## the current maths command cannot cope with newline within the math expression
  my $comment='%.*?\n';
  my $pat=qr/(?:\A\s*)?(?:${and}|${quotemarks}|${number}|${word}|$quotedunderscore|$cmdleftright|${cmdoptseq}|${math}|${backslashnl}|${oneletcmd}|${comment}|${punct}|${mathpunct}|\{|\})\s*/ ;




# now we are done setting up and can start working   
my ($oldfile, $newfile) = @ARGV;
# check for existence of input files
if ( ! -e $oldfile ) {
  die "Input file $oldfile does not exist";
}
if ( ! -e $newfile ) {
  die "Input file $newfile does not exist";
}


# set the labels to be included into the file
# first find out which file name is longer for correct alignment
my ($diff,$oldlabel_n_spaces,$newlabel_n_spaces);
$oldlabel_n_spaces = 0;
$newlabel_n_spaces = 0;
$diff = length($newfile) - length($oldfile);
if ($diff > 0) {
  $oldlabel_n_spaces = $diff;
}
if ($diff < 0) {
  $newlabel_n_spaces = abs($diff);
}

my ($oldtime,$newtime,$oldlabel,$newlabel);
if (defined($labels[0])) {
  $oldlabel=$labels[0] ;
} else {
  $oldtime=localtime((stat($oldfile))[9]); 
  $oldlabel="$oldfile   " . " "x($oldlabel_n_spaces) . $oldtime;
}
if (defined($labels[1])) {
  $newlabel=$labels[1] ;
} else {
  $newtime=localtime((stat($newfile))[9]);
  $newlabel="$newfile   " . " "x($newlabel_n_spaces) . $newtime;
}

$encoding=guess_encoding($newfile) unless defined($encoding);

$encoding = "utf8" if $encoding =~ m/^utf8/i ;
if (lc($encoding) eq "utf8" ) {
  binmode(STDOUT, ":utf8");
  binmode(STDERR, ":utf8");
}

$old=read_file_with_encoding($oldfile,$encoding);
$new=read_file_with_encoding($newfile,$encoding);




# reset time
exetime(1);
($oldpreamble,$oldbody,$oldpost)=splitdoc($old,'\\\\begin\{document\}','\\\\end\{document\}');

($newpreamble,$newbody,$newpost)=splitdoc($new,'\\\\begin\{document\}','\\\\end\{document\}');


if ($flatten) {
  $oldbody=flatten($oldbody,$oldpreamble,$oldfile,$encoding);
  $newbody=flatten($newbody,$newpreamble,$newfile,$encoding);
  # flatten preamble
  $oldpreamble=flatten($oldpreamble,$oldpreamble,$oldfile,$encoding);
  $newpreamble=flatten($newpreamble,$newpreamble,$newfile,$encoding);

}




my @auxlines;

# boolean variab
my ($ulem)=0;

if ( length $oldpreamble && length $newpreamble ) {
  # pre-process preamble by looking for commands used in \maketitle (title, author, date etc commands) 
  # and marking up content with latexdiff markup
  @auxlines=preprocess_preamble($oldpreamble,$newpreamble);

  @oldpreamble = split /\n/, $oldpreamble;
  @newpreamble = split /\n/, $newpreamble;

  # If a command is defined in the preamble of the new file, and only uses safe commands, then it can be considered to be safe) (contribution S. Gouezel)
  # Base this assessment on the new preamble
  add_safe_commands($newpreamble);

  # get a list of packages from preamble if not predefined
  %packages=list_packages($newpreamble) unless %packages;
  if ( %packages && $debug ) { my $key ; foreach $key (keys %packages) { print STDERR "DEBUG \\usepackage[",$packages{$key},"]{",$key,"}\n" ;} }
}

# have to return to all processing to properly add preamble additions based on packages found
if (defined($graphicsmarkup)) {
  $graphicsmarkup=~tr/a-z/A-Z/;
  if ( $graphicsmarkup eq 'OFF' or $graphicsmarkup eq 'NONE' ) {
    $graphicsmarkup=NONE;
  } elsif ( $graphicsmarkup eq 'NEWONLY' or $graphicsmarkup eq 'NEW-ONLY' ) {
    $graphicsmarkup=NEWONLY;
  } elsif ( $graphicsmarkup eq 'BOTH' ) {
    $graphicsmarkup=BOTH;
  } elsif ( $graphicsmarkup !~ m/^[012]$/ ) {
    die "latexdiff Illegal value: ($graphicsmarkup)  for option --highlight-graphics. Possible values: OFF,WHOLE,COARSE,FINE,0-2\n";
  }
  # else use numerical value
} else {
  # Default: no explicit setting in menu
  if ( defined $packages{"graphicx"} or defined $packages{"graphics"} ) {
    $graphicsmarkup=NEWONLY; 
  } else {
    $graphicsmarkup=NONE;
  }
}

if (defined $packages{"hyperref"} ) {
  # deleted lines should not generate or appear in link names:
  print STDERR "hyperref package detected.\n" if $verbose ;
  $latexdiffpreamble =~ s/\{\\DIFadd\}/{\\DIFaddtex}/g;
  $latexdiffpreamble =~ s/\{\\DIFdel\}/{\\DIFdeltex}/g;
  $latexdiffpreamble .= join "\n",(extrapream("HYPERREF"),"");
  ###    $latexdiffpreamble .= '%DIF PREAMBLE EXTENSION ADDED BY LATEXDIFF FOR HYPERREF PACKAGE' . "\n";
  ###    $latexdiffpreamble .= '\providecommand{\DIFadd}[1]{\texorpdfstring{\DIFaddtex{#1}}{#1}}' . "\n";
  ###    $latexdiffpreamble .= '\providecommand{\DIFdel}[1]{\texorpdfstring{\DIFdeltex{#1}}{}}' . "\n";
  ###    $latexdiffpreamble .= '%DIF END PREAMBLE EXTENSION ADDED BY LATEXDIFF FOR HYPERREF PACKAGE' . "\n";
}

# add commands for figure highlighting to preamble
if ($graphicsmarkup != NONE ) {
  my @matches;
  # Check if \DIFaddbeginFL definition calls \DIFaddbegin - if so we will issue an error message that graphics highlighting is
  # is not compatible with this.
  # (A more elegant solution would be to suppress the redefinitions of the \DIFaddbeginFL etc commands, but for this narrow use case
  #  I currently don't see this as an efficient use of time)
  ### The foreach loop does not make sense here. I don't know why I put this in -  (F Tilmann)
  ###foreach my $cmd ( "DIFaddbegin","DIFaddend","DIFdelbegin","DIFdelend" ) {
  @matches=( $latexdiffpreamble =~ m/command\{\\DIFaddbeginFL}\{($pat_n)}/sg ) ;
  # we look at the last one of the list to take into account possible redefinition but almost always matches should have exactly one element
  if ( $matches[$#matches] =~ m/\\DIFaddbegin/ ) {
    die "Cannot combine graphics markup with float styles defining \\DIFaddbeginFL in terms of \\DIFaddbegin. Use --graphics-markup=none option or choose a different float style."; 
    exit 10;
  }
  ###}
  $latexdiffpreamble .= join "\n",("\\newcommand{\\DIFscaledelfig}{$SCALEDELGRAPHICS}",extrapream("HIGHLIGHTGRAPHICS"),"");

  # only change required for highlighting both is to declare \includegraphics safe, as preamble already contains commands for deleted environment
  if ( $graphicsmarkup == BOTH ) {
    init_regex_arr_list(\@SAFECMDLIST,'includegraphics');
  }
}

# If listings is being used and latexdiffpreamble uses color markup
if (defined($packages{"listings"} and $latexdiffpreamble =~ /\\RequirePackage(?:\[$brat0\])?\{color\}/)) {
  $latexdiffpreamble .= join "\n",(extrapream("LISTINGS"),"");
}

# adding begin and end marker lines to preamble
$latexdiffpreamble = "%DIF PREAMBLE EXTENSION ADDED BY LATEXDIFF\n" . $ latexdiffpreamble . "%DIF END PREAMBLE EXTENSION ADDED BY LATEXDIFF\n";

# and return to preamble specific processing
if ( length $oldpreamble && length $newpreamble ) {
  print STDERR "Differencing preamble.\n" if $verbose;

  # insert dummy first line such that line count begins with line 1 (rather than perl's line 0) - just so that line numbers inserted by linediff are correct
  unshift @newpreamble,'';
  unshift @oldpreamble,'';
  @diffpreamble = linediff(\@oldpreamble, \@newpreamble);
  # remove dummy line again
  shift @diffpreamble; 
  # add filenames, modification time and latexdiff mark
  defined($nolabel) or splice @diffpreamble,1,0,
      "%DIF LATEXDIFF DIFFERENCE FILE",
      ,"%DIF DEL $oldlabel",
      "%DIF ADD $newlabel";
  if ( @auxlines ) {
    push @diffpreamble,"%DIF DELETED TITLE COMMANDS FOR MARKUP";
    push @diffpreamble,join("\n",@auxlines);
  }
  if ( $earlylatexdiffpreamble) {
    # insert latexdiff command directly after documentclass at beginning of preamble
    # note that grep is only run for its side effect
    ( grep { s/^([^%]*\\documentclass.*)$/$1$latexdiffpreamble/ } @diffpreamble )==1 or die "Could not find documentclass statement in preamble";
  } else {
    # insert latexdiff commands at the end of preamble (default behaviour)
    push @diffpreamble,$latexdiffpreamble;
  }
  push @diffpreamble,'\begin{document}';
}
elsif ( !length $oldpreamble && !length $newpreamble ) {
  @diffpreamble=();
} else {
  print STDERR "Either both texts must have preamble or neither text must have the preamble.\n";
  exit(2);
}

# Special: treat all cite commands as safe except in UNDERLINE and FONTSTRIKE mode
# (there is a conflict between citation and ulem package, see
# package documentation)
# Use post-processing
# and $packages{"apacite"}!~/natbibpapa/

$ulem = ($latexdiffpreamble =~ /\\RequirePackage(?:\[$brat0\])?\{ulem\}/ || defined $packages{"ulem"});


if (defined $packages{"units"}  && $ulem ) {
  # protect inlined maths environments by surrounding with an \mbox
  # this is done to get around an incompatibility between the ulem and units package
  # where spaces in the argument to underlined or crossed-out \unit commands cause an error message
  print STDERR "units package detected at the same time as style using ulem.\n" if $verbose ;
  $MBOXINLINEMATH=1;
}

if (defined $packages{"siunitx"} ) {
  # protect SI command by surrounding them with an \mbox
  # this is done to get around an incompatibility between the ulem and siunitx package
  print STDERR "siunitx package detected.\n" if $verbose ;
  my $mboxcmds='SI,ang,numlist,numrange,SIlist,SIrange';
  init_regex_arr_list(\@SAFECMDLIST,'num,si');
  if ( $enablecitmark || ( $ulem  && ! $disablecitmark )) {
    init_regex_arr_list(\@MBOXCMDLIST,$mboxcmds);
  } else {
    init_regex_arr_list(\@SAFECMDLIST,$mboxcmds);
  }
}

if (defined $packages{"cleveref"} ) {
  # protect selected command by surrounding them with an \mbox
  # this is done to get around an incompatibility between ulem and cleveref package
  print STDERR "cleveref package detected.\n" if $verbose ;
  my $mboxcmds='[Cc]ref(?:range)?\*?,labelcref,(?:lc)?name[cC]refs?' ;
  if ( $enablecitmark || ( $ulem  && ! $disablecitmark )) {
    init_regex_arr_list(\@MBOXCMDLIST,$mboxcmds);
  } else {
    init_regex_arr_list(\@SAFECMDLIST,$mboxcmds);
  }
}

if (defined $packages{"glossaries"} ) {
  # protect selected command by surrounding them with an \mbox
  # this is done to get around an incompatibility between ulem and glossaries package 
  print STDERR "glossaries package detected.\n" if $verbose ;
  my $mboxcmds='[gG][lL][sS](?:|pl|disp|link|first|firstplural|desc|user[iv][iv]?[iv]?),[aA][cC][rR](?:long|longpl|full|fullpl),[aA][cC][lfp]?[lfp]?';
  init_regex_arr_list(\@SAFECMDLIST,'[gG][lL][sS](?:(?:entry)?(?:text|plural|name|symbol)|displaynumberlist|entryfirst|entryfirstplural|entrydesc|entrydescplural|entrysymbolplural|entryuser[iv][iv]?[iv]?|entrynumberlist|entrydisplaynumberlist|entrylong|entrylongpl|entryshort|entryshortpl|entryfull|entryfullpl),[gG]lossentry(?:name|desc|symbol),[aA][cC][rR](?:short|shortpl),[aA]csp?');
  if ( $enablecitmark || ( $ulem  && ! $disablecitmark )) {
    init_regex_arr_list(\@MBOXCMDLIST,$mboxcmds);
  } else {
    init_regex_arr_list(\@SAFECMDLIST,$mboxcmds);
  }
}

if (defined $packages{"chemformula"} or defined $packages{"chemmacros"} ) {
  print STDERR "chemformula package detected.\n" if $verbose ;
  init_regex_arr_list(\@SAFECMDLIST,'ch');
  push(@UNSAFEMATHCMD,'ch');
  # The next command would be needed to allow highlighting the interior of \ch commands in math environments
  # but the redefinitions in chemformula are too deep to make this viable
  # push(@MATHTEXTCMDLIST,'ch');
}

if (defined $packages{"mhchem"} ) {
  print STDERR "mhchem package detected.\n" if $verbose ;
  init_regex_arr_list(\@SAFECMDLIST,'ce');
  push(@UNSAFEMATHCMD,'ce','cee');
  # The next command would be needed to allow highlighting the interior of \cee commands in math environments
  # but the redefinitions in chemformula are too deep to make this viable
  # push(@MATHTEXTCMDLIST,'cee');
}


my ( $citpat);

if ( defined $packages{"apacite"}  ) {
  print STDERR "apacite package detected.\n" if $verbose ;
  $citpat='(?:mask)?(?:full|short|no)?cite(?:A|author|year|meta)?(?:NP)?';
} else {
  # citation command pattern for all other citation schemes
  $citpat='(?:cite\w*|nocite)';
};

if ( ! $ulem ) {
  # modes not using ulem: citation is safe
  push (@SAFECMDLIST, $citpat);
} else {
  ### Experimental: disable text and emph commands
  push(@SAFECMDEXCL, qr/^emph$/, qr/^text..$/);
  # replace \cite{..} by \mbox{\cite{..}} in added or deleted blocks in post-processing
  push(@MBOXCMDLIST,$citpat) unless $disablecitmark;
  if ( uc($subtype) eq "COLOR" or uc($subtype) eq "DVIPSCOL" ) {
    # remove \cite command again from list of safe commands
    pop @MBOXCMDLIST;
    # deleted cite commands
  }
}
push(@MBOXCMDLIST,$citpat) if $enablecitmark ;


if (defined $packages{"amsmath"}  or defined $packages{"amsart"} or defined $packages{"amsbook"} ) {
  print STDERR "amsmath package detected.\n" if $verbose ;
  $MATHARRREPL='align*';
}

# add commands in MBOXCMDLIST to SAFECMDLIST
foreach $mboxcmd ( @MBOXCMDLIST ) {
  init_regex_arr_list(\@SAFECMDLIST, $mboxcmd);
}

# check if \label is in SAFECMDLIST, and if yes replace "label" in $LABELCMD by something that never matches (we hope!)
if ( iscmd("label",\@SAFECMDLIST,\@SAFECMDEXCL) ) {
  $LABELCMD=~ s/label/NEVERMATCHLABEL/;
}



print STDERR "Preprocessing body.  " if $verbose;
preprocess($oldbody,$newbody);


# run difference algorithm
@diffbody=bodydiff($oldbody, $newbody);
$diffbo=join("",@diffbody);
if ( $debug ) {
    open(RAWDIFF,">","latexdiff.debug.bodydiff");
    print RAWDIFF $diffbo;
    close(RAWDIFF);
}
print STDERR "(",exetime()," s)\n","Postprocessing body. \n" if $verbose;
postprocess($diffbo);
$diffall =join("\n",@diffpreamble) ;
# add visible labels
if (defined($visiblelabel)) {
  # Give information right after \begin{document} (or at the beginning of the text for files without preamble
  ### if \date command is used, add information to \date argument, otherwise give right after \begin{document}
  ###  $diffall=~s/(\\date$extraspace(?:\[$brat0\])?$extraspace)\{($pat_n)\}/$1\{$2 \\ LATEXDIFF comparison \\ Old: $oldlabel \\ New: $newlabel \}/  or
  $diffbo = "\\begin{verbatim}LATEXDIFF comparison\nOld: $oldlabel\nNew: $newlabel\\end{verbatim}\n$diffbo"   ;
}

$diffall .= "$diffbo" ;
$diffall .= "\\end{document}$newpost" if length $newpreamble ;
if ( lc($encoding) ne "utf8" && lc($encoding) ne "ascii" ) {
  print STDERR "Encoding output file to $encoding\n" if $verbose;
  $diffall=Encode::encode($encoding,$diffall);
  binmode STDOUT;
}
print $diffall;


print STDERR "(",exetime()," s)\n","Done.\n" if $verbose;


# liststringtoregex(liststring)
# expands string with semi-colon separated list into a regular expression corresponding 
# matching any of the elements
sub liststringtoregex {
  my ($liststring)=@_;
  my @elements=grep /\S/,split(";",$liststring);
  if ( @elements) {
    return('(?:(?:' . join(')|(?:',@elements) .'))');
  } else {
    return "";
  }
}

# show_configuration
# note that this is not encapsulated but uses variables from the main program 
# It is provided for convenience because in the future it is planned to allow output
# to be modified based on what packages are read etc - this works only if the input files are actually red
# whether or not additional files are provided
sub show_configuration {
  if ($showpreamble) {
    print "\nPreamble commands:\n";
    print $latexdiffpreamble ;
  }

  if ($showsafe) {
    print "\nsafecmd: Commands safe within scope of $ADDOPEN $ADDCLOSE and $DELOPEN $DELCLOSE (unless excluded):\n";
    print_regex_arr(@SAFECMDLIST);
    print "\nsafecmd-exlude: Commands not safe within scope of $ADDOPEN $ADDCLOSE and $DELOPEN $DELCLOSE :\n";
    print_regex_arr(@SAFECMDEXCL);
    print "\nmboxsafecmd:  Commands safe only if they are surrounded by \\mbox command:\n";
    print_regex_arr(@MBOXCMDLIST);
    print "\nnmboxsafecmd: Commands not safe:\n";
    print_regex_arr(@MBOXCMDEXCL);
  }

  if ($showtext) {
    print "\nCommands with last argument textual (unless excluded) and safe in every context:\n";
    print_regex_arr(@TEXTCMDLIST);
    print "\nContext1 commands (last argument textual, command will be disabled in deleted passages, last argument will be shown as plain text):\n";
    print_regex_arr(@CONTEXT1CMDLIST);
    print "\nContext2 commands (last argument textual, command and its argument will be disabled in deleted passages):\n";
    print_regex_arr(@CONTEXT2CMDLIST);  
    print "\nExclude list of Commands with last argument not textual (overrides patterns above):\n";
    print_regex_arr(@TEXTCMDEXCL);
  }


  if ($showconfig) {
    print "Configuration variables:\n";
    print "ARRENV=$ARRENV\n";
    print "COUNTERCMD=$COUNTERCMD\n";
    print "FLOATENV=$FLOATENV\n";
    print "ITEMCMD=$ITEMCMD\n";
    print "LISTENV=$LISTENV\n";
    print "MATHARRENV=$MATHARRENV\n";
    print "MATHARRREPL=$MATHARRREPL\n";
    print "MATHENV=$MATHENV\n";
    print "MATHREPL=$MATHREPL\n";
    print "MINWORDSBLOCK=$MINWORDSBLOCK\n";
    print "PICTUREENV=$PICTUREENV\n";
  }
}



## guess_encoding(filename)
## reads the first 20 lines of filename and looks for call of inputenc package
## if found, return the option of this package (encoding), otherwise return utf8
sub guess_encoding {
  my ($filename)=@_;
  my ($i,$enc);
  open (FH, $filename) or die("Couldn't open $filename: $!");
  $i=0;
  while (<FH>) {
    next if /^\s*%/;    # skip comment lines
    if (m/\\usepackage\[(\w*?)\]\{inputenc\}/) {
      close(FH);
      return($1);
    }
    last if (++$i > 20 ); # scan at most 20 non-comment lines
  }
  close(FH);
  ### return("ascii");
  return("utf8");
}


sub read_file_with_encoding {
  my ($output);
  my ($filename, $encoding) = @_;

  if (lc($encoding) eq "utf8" ) {
    open (FILE, "<:utf8",$filename) or die("Couldn't open $filename: $!");
    local $/ ; # locally set record operator to undefined, ie. enable whole-file mode
    $output=<FILE>;
  } elsif ( lc($encoding) eq "ascii") {
    open (FILE, $filename) or die("Couldn't open $filename: $!");
    local $/ ; # locally set record operator to undefined, ie. enable whole-file mode
    $output=<FILE>;
  } else {
    require Encode;
    open (FILE, "<",$filename) or die("Couldn't open $filename: $!");
    local $/ ; # locally set record operator to undefined, ie. enable whole-file mode
    $output=<FILE>;
    print STDERR "Converting $filename from $encoding to utf8\n" if $verbose;
    $output=Encode::decode($encoding,$output);
  }
  close FILE;
  if ($^O eq "linux" ) {
    $output =~ s/\r\n/\n/g ;
  }
  return $output;
}

## %packages=list_packages(@preamble)
## scans the arguments for \documentclass,\RequirePackage and \usepackage statements and constructs a hash
## whose keys are the included packages, and whose values are the associated optional arguments
#sub list_packages {
#  my (@preamble)=@_;
#  my %packages=();
#  foreach $line ( @preamble ) {
#    # get rid of comments
#    $line=~s/(?<!\\)%.*$// ;
#    if ( $line =~ m/\\(?:documentclass|usepackage|RequirePackage)(?:\[(.+?)\])?\{(.*?)\}/ ) {
##      print STDERR "Found something: |$line|\n" if $debug;
#      if (defined($1)) {
#	$packages{$2}=$1;
#      } else {
#	$packages{$2}="";
#      }
#    }
#  }
#  return (%packages);
#}


# %packages=list_packages($preamble)
# scans the arguments for \documentclass,\RequirePackage and \usepackage statements and constructs a hash
# whose keys are the included packages, and whose values are the associated optional arguments
# if argument of \usepackage or \RequirePackage is comma separated list, treat as different packages
sub list_packages {
  my ($preamble)=@_;
  my %packages=();
  my $pkg;

  # remove comments 
  $preamble=~s/(?<!\\)%.*$//mg ;

  while ( $preamble =~  m/\\(?:documentclass|usepackage|RequirePackage)(?:\[($brat0)\])?\{(.*?)\}/gs ) {
    if (defined($1)) {
      foreach $pkg ( split /,/,$2 ) {
	$packages{$pkg}=$1;
      }
    } else {
      foreach $pkg ( split /,/,$2 ) {
	$packages{$pkg}="";
      }
    }
  }
  return (%packages);
}

# Subroutine add_safe_commands modified from version provided by S. Gouezel
# add_safe_commands($preamble)
# scans the argument for \newcommand and \DeclareMathOperator,
# and adds the created commands which are clearly safe to @SAFECMDLIST
sub add_safe_commands {
  my ($preamble)=@_;

  # get rid of comments
  $preamble=~s/(?<!\\)%.*$//mg ;

  my $to_test = "";
  # test for \DeclareMathOperator{\foo}{myoperator}
  while ( $preamble =~ m/\DeclareMathOperator\s*\*?\{\\(\w*?)\}/osg) {
    $to_test=$1;
    if ($to_test ne "" and not iscmd($to_test,\@SAFECMDLIST,\@SAFECMDEXCL) and not iscmd($to_test, \@SAFECMDEXCL, [])) {
      # one should add $to_test to the list of safe commands.
      init_regex_arr_list(\@SAFECMDLIST, $to_test);
      print STDERR "Adding $to_test to the list of safe commands\n" if $verbose;
    }
  }

  while ( $preamble =~ m/\\(?:new|renew|provide)command\s*{\\(\w*)\}(?:|\[\d*\])\s*\{(${pat_n})\}/osg ) {
    my $maybe_to_test  = $1;
    my $should_be_safe = $2;
    print STDERR "DEBUG Checking new command: maybe_to_test, should_be_safe: $1 $2\n" if $debug;
    my $success = 0;
    # test if all latex commands inside it are safe
    $success = 1;
    if ($should_be_safe =~ m/\\\\/) {
      $success = 0;
    } else {
      while ($should_be_safe =~ m/\\(\w+)/g) {
	###	  print STDERR "DEBUG: Testing command $1 " if $debug;
	$success = 0 unless iscmd($1,\@SAFECMDLIST,\@SAFECMDEXCL); ### or $1 eq "";
	###        print STDERR " success=$success\n" if $debug;
      }
    }
    ###      }
    if ($success) {
      $to_test = $maybe_to_test;
      if (  not iscmd($to_test,\@SAFECMDLIST,\@SAFECMDEXCL) and not iscmd($to_test, \@SAFECMDEXCL, [])) {
	#        # one should add $to_test to the list of safe commands.
	init_regex_arr_list(\@SAFECMDLIST, $to_test);
	print STDERR "Adding $to_test to the list of safe commands\n" if $verbose;
      }
    }
  }
}


# helper function for flatten
# remove \endinput at beginning of line and everything
# following it, # if \endinput is not at the beginning of
# the line, nothing will be removed. It is assumed that
# this case is most common when \endinput is part of a
# conditional clause.  The file will only be processed
# correctly if the conditional is always false,
# i.e. \endinput # not actually reached
sub remove_endinput {
  # s/// operates on default input
  $_[0] =~ s/^\\endinput.*\Z//ms ;
  return($_[0]);
}

# flatten($text,$preamble,$filename,$encoding)
# expands \input and \include commands within text
# expands \bibliography command with corresponding bbl file if available
# expands \subfile command (from subfiles package - not part of standard text distribution)
# preamble is scanned for includeonly commands
# encoding is the encoding
sub flatten {
  my ($text,$preamble,$filename,$encoding)=@_;
  my ($includeonly,$dirname,$fname,$newpage,$replacement,$begline,$bblfile,$subfile);
  my ($subpreamble,$subbody,$subpost);
  require File::Basename ; 
  require File::Spec ; 
  $dirname = File::Basename::dirname($filename);
  $bblfile = $filename;
  $bblfile=~s/\.tex$//;
  $bblfile.=".bbl";

  if ( ($includeonly) = ($preamble =~ m/\\includeonly\{(.*?)\}/ ) ) {
    $includeonly =~ s/,/|/g;
  } else {
    $includeonly = '.*?';
  }

  print STDERR "DEBUG: includeonly $includeonly\n" if $debug;

  # recursively replace \\input and \\include files
  1 while $text=~s/(^(?:[^%\n]|\\%)*)(?:\\input\{(.*?)\}|\\include\{(${includeonly}(?:\.tex)?)\})/{ 
	    $begline=(defined($1)? $1 : "") ;
	    $fname = $2 if defined($2) ;
	    $fname = $3 if defined($3) ;
            #      # add tex extension unless there is a three letter extension already 
            $fname .= ".tex" unless $fname =~ m|\.\w{3}$|;
            print STDERR "DEBUG Beg of line match |$1|\n" if defined($1) && $debug ;
            print STDERR "Include file $fname\n" if $verbose;
            print STDERR "DEBUG looking for file ",File::Spec->catfile($dirname,$fname), "\n" if $debug;
            # content of file becomes replacement value (use recursion), add \newpage if the command was include
            ###$replacement=read_file_with_encoding(File::Spec->catfile($dirname,$fname), $encoding) or die "Couldn't find file ",File::Spec->catfile($dirname,$fname),": $!";
	    $replacement=flatten(read_file_with_encoding(File::Spec->catfile($dirname,$fname), $encoding), $preamble,$filename,$encoding) or die "Couldn't find file ",File::Spec->catfile($dirname,$fname),": $!";
	    $replacement = remove_endinput($replacement); 
	    # \include always starts a new page; use explicit \newpage command to simulate this
	    $newpage=(defined($3)? " \\newpage " : "") ;
	    "$begline$newpage$replacement$newpage";
          }/exgm;
  # replace bibliography with bbl file if it exists
  $text=~s/(^(?:[^%\n]|\\%)*)\\bibliography\{(.*?)\}/{ 
           if ( -f $bblfile ){
	     $replacement=read_file_with_encoding(File::Spec->catfile($bblfile), $encoding);
	   } else {
	     warn "Bibliography file $bblfile cannot be found. No flattening of \\bibliography done. Run bibtex on old and new files first";
	     $replacement="\\bibliography{$2}";
	   }
	   $begline=(defined($1)? $1 : "") ;
	   "$begline$replacement";
  }/exgm;
  # replace subfile with contents (subfile package)
  $text=~s/(^(?:[^%\n]|\\%)*)\\subfile\{(.*?)\}/{ 
           $begline=(defined($1)? $1 : "") ;
     	   $fname = $2; 
           #      # add tex extension unless there is a three letter extension already 
           $fname .= ".tex" unless $fname =~ m|\.\w{3}|;
           print STDERR "Include file as subfile $fname\n" if $verbose;
           # content of file becomes replacement value (use recursion)
           # now strip away everything outside and including \begin{document} and \end{document} pair#
	   #             # note: no checking for comments is made
           $subfile=read_file_with_encoding(File::Spec->catfile($dirname,$fname), $encoding) or die "Couldn't find file ",File::Spec->catfile($dirname,$fname),": $!";
           ($subpreamble,$subbody,$subpost)=splitdoc($subfile,'\\\\begin\{document\}','\\\\end\{document\}');
	   $replacement=flatten($subbody, $preamble,$filename,$encoding);
	   $replacement = remove_endinput($replacement); 
	   "$begline$replacement";
  }/exgm;

  return($text);
}


# print_regex_arr(@arr)
# prints regex array without x-ism expansion put in by pearl to stdout
sub print_regex_arr {
  my $dumstring;
  $dumstring = join(" ",@_);     # PERL generates string (?-xism:^ref$) for quoted refex ^ref$
  $dumstring =~ s/\(\?-xism:\^(.*?)\$\)/$1/g;   # remove string and ^,$ marks before output
  print $dumstring,"\n";
}


# @lines=extrapream($type)
# reads line from appendix (end of file after __END__ token)
sub extrapream {
  my $type;
  ###my @retval=("%DIF PREAMBLE EXTENSION ADDED BY LATEXDIFF") ;
  my @retval=();
  my ($copy);

  while (@_) {
    $copy=0;
    $type=shift ;
    if ( -f $type || lc $type eq '/dev/null' ) {
      open (FILE,$type) or die "Cannot open preamble file $type: $!";
      print STDERR "Reading preamble file $type\n" if $verbose ;
      while (<FILE>) {
	chomp ;
	if ( $_ =~ m/%DIF PREAMBLE/ ) {
	  push (@retval,"$_"); 
	} else {
	  push (@retval,"$_ %DIF PREAMBLE"); 
	}
      }
    } 
    else {    # not (-f $type)
      $type=uc($type);   # upcase argument
      print STDERR "Preamble Internal Type $type\n" if $verbose;
      while (<DATA>) {
	if ( m/^%DIF $type/ ) {
	  $copy=1; }
	elsif ( m/^%DIF END $type/ ) {
	  last; }
	chomp;
	push (@retval,"$_ %DIF PREAMBLE") if $copy;
      }
      if ( $copy == 0 ) {
	print STDERR "\nPreamble style $type not implemented.\n";
        print STDERR "Write latexdiff -h to get help with available styles\n";
        exit(2);
      }
      seek DATA,0,0;    # rewind DATA handle to file begin
    }
  }
  ###push (@retval,"%DIF END PREAMBLE EXTENSION ADDED BY LATEXDIFF")  ;
  return @retval;
}


# ($part1,$part2,$part3)=splitdoc($text,$word1,$word2)
# splits $text into 3 parts at $word1 and $word2.
# if neither $word1 nor $word2 exist, $part1 and $part3 are empty, $part2 is $text
# If only $word1 or $word2 exist but not the other, output an error message.

# NB this version avoids $` and $' for performance reason although it only makes a tiny difference
# (in one test gain a tenth of a second for a 30s run)
sub splitdoc {
  my ($text,$word1,$word2)=@_;
  my ($part1,$part2,$part3)=("","","");
  my ($rest,$pos);

  if ( $text =~ m/(^[^%]*)($word1)/mg ) {
    $pos=pos $text;
    $part1=substr($text,0,$pos-length($2));
    $rest=substr($text,$pos);
    if ( $rest =~ m/(^[^%]*)($word2)/mg ) {
      $pos=pos $rest;
      $part2=substr($rest,0,$pos-length($2));
      $part3=substr($rest,$pos);
    } 
    else {
      die "$word1 and $word2 not in the correct order or not present as a pair." ;
    }
  } else {
    $part2=$text;
    die "$word2 present but not $word1." if ( $text =~ m/(^[^%]*)$word2/ms );
  }
  return ($part1,$part2,$part3);
}





# bodydiff($old,$new)
sub bodydiff {
  my ($oldwords, $newwords) = @_;
  my @retwords;

  print STDERR "(",exetime()," s)\n","Splitting into latex tokens \n" if $verbose;
  print STDERR "Parsing $oldfile \n" if $verbose;
  my @oldwords = splitlatex($oldwords);
  print STDERR "Parsing $newfile \n" if $verbose;
  my @newwords = splitlatex($newwords);

  if ( $debug ) {
    open(TOKENOLD,">","latexdiff.debug.tokenold");
    print TOKENOLD join("***\n",@oldwords);
    close(TOKENOLD);
    open(TOKENNEW,">","latexdiff.debug.tokennew");
    print TOKENNEW join("***\n",@newwords);
    close(TOKENNEW);
  }

  print STDERR "(",exetime()," s)\n","Pass 1: Expanding text commands and merging isolated identities with changed blocks  " if $verbose;
  pass1(\@oldwords, \@newwords);


  print STDERR "(",exetime()," s)\n","Pass 2: inserting DIF tokens and mark up.  " if $verbose;
  if ( $debug ) {
    open(TOKENOLD,">","latexdiff.debug.tokenold2");
    print TOKENOLD join("***\n",@oldwords);
    close(TOKENOLD);
    open(TOKENNEW,">","latexdiff.debug.tokennew2");
    print TOKENNEW join("***\n",@newwords);
    close(TOKENNEW);
  }

  @retwords=pass2(\@oldwords, \@newwords);

  return(@retwords);
}




# @words=splitlatex($string)
# split string according to latex rules
# Each element of words is either
# a word (including trailing spaces and punctuation)
# a latex command
# if there is white space in the beginning return that as first token
sub splitlatex {
  my ($inputstring) = @_ ;
  my $string=$inputstring ;
  # if input is empty, return empty list
  length($string)>0 or return ();
  $string=~s/^(\s*)//s;
  my $leadin=$1;
  length($string)>0 or return ($leadin);

  my @retval=($string =~ m/$pat/osg);  

  if (length($string) != length(join("",@retval))) {
    print STDERR "\nWARNING: Inconsistency in length of input string and parsed string:\n     This often indicates faulty or non-standard latex code.\n     In many cases you can ignore this and the following warning messages.\n Note that character numbers in the following are counted beginning after \\begin{document} and are only approximate." unless $ignorewarnings;
    print STDERR "DEBUG Original length ",length($string),"  Parsed length ",length(join("",@retval)),"\n" if $debug;
    print STDERR "DEBUG Input string:  |$string|\n" if (length($string)<500) && $debug;
    print STDERR "DEBUG Token parsing: |",join("+",@retval),"|\n" if (length($string)<500) && $debug ;
    @retval=();
    # slow way only do this if other m//sg method fails
    my $last = 0;
    while ( $string =~ m/$pat/osg ) {
      my $match=$&;
      if ($last + length $& != pos $string  ) {
	my $pos=pos($string);
	my $offset=30<$last ? 30 : $last;
	my $dum=substr($string,$last-$offset,$pos-$last+2*$offset);
	my $dum1=$dum;
	my $cnt=$#retval;
	my $i;
	$dum1 =~ s/\n/ /g;
	unless ($ignorewarnings) {
	  print STDERR "\n$dum1\n";
	  print STDERR " " x 30,"^" x ($pos-$last)," " x 30,"\n";
	  print STDERR "Missing characters near word " . (scalar @retval) . " character index: " . $last . "-" .  pos($string) . " Length: " . length($match) . " Match: |$match| (expected match marked above).\n";
	}
	  # put in missing characters `by hand'
	push (@retval, substr($dum,$offset,$pos-$last-length($match)));
#       Note: there seems to be a bug in substr with utf8 that made the following line output substr which were too long,
#             using dum instead appears to work
#	push (@retval, substr($string,$last, pos($string)-$last-length($match)));
      }
      push (@retval, $match);
      $last=pos $string;
    }

  }
  unshift(@retval,$leadin) if (length($leadin)>0);
  return @retval;
}


# pass1( \@seq1,\@seq2)
# Look for differences between seq1 and seq2.
# Where an common-subsequence block is flanked by deleted or appended blocks, 
# and is shorter than $MINWORDSBLOCK words it is appended
# to the last deleted or appended word.  If the block contains tokens other than words 
# or punctuation it is not merged.
# Deleted or appended block consisting of words and safe commands only are
# also merged, to prevent break-up in pass2 (after previous isolated words have been removed)
# If there are commands with textual arguments (e.g. \caption) both in corresponding 
# appended and deleted blocks split them such that the command and opening bracket 
# are one token, then the rest is split up following standard rules, and the closing 
# bracket is a separate token, ie. turn
# "\caption{This is a textual argument}" into 
# ("\caption{","This ","is ","a ","textual ","argument","}")
# No return value.  Destructively changes sequences
sub pass1 {
  my $seq1 = shift ;
  my $seq2 = shift ;

  my $len1 = scalar @$seq1;
  my $len2 = scalar @$seq2;
  my $wpat=qr/^(?:[a-zA-Z.,'`:;?()!]*)[\s~]*$/;   #'

  my ($last1,$last2)=(-1,-1) ;
  my $cnt=0;
  my $block=[];
  my $addblock=[];
  my $delblock=[];
  my $todo=[];
  my $instruction=[];
  my $i;
  my (@delmid,@addmid,@dummy);

  my ($addcmds,$delcmds,$matchindex);
  my ($addtextblocks,$deltextblocks);
  my ($addtokcnt,$deltokcnt,$mattokcnt)=(0,0,0);
  my ($addblkcnt,$delblkcnt,$matblkcnt)=(0,0,0);

  my $adddiscard = sub {
                      if ($cnt > 0 ) {
			$matblkcnt++;
			# just after an unchanged block 
#			print STDERR "Unchanged block $cnt, $last1,$last2 \n";
                        if ($cnt < $MINWORDSBLOCK 
			    && $cnt==scalar (
				     grep { /^$wpat/ || ( /^\\((?:[`'^"~=.]|[\w\d@*]+))((?:\[$brat0\]|\{$pat_n\})*)/o 
							   && iscmd($1,\@SAFECMDLIST,\@SAFECMDEXCL) 
							   && scalar(@dummy=split(" ",$2))<3 ) }
					     @$block) )  {
			  # merge identical blocks shorter than $MINWORDSBLOCK 
			  # and only containing ordinary words
			  # with preceding different word
			  # We cannot carry out this merging immediately as this
			  # would change the index numbers of seq1 and seq2 and confuse
			  # the algorithm, instead we store in @$todo where we have to merge
                          push(@$todo, [ $last1,$last2,$cnt,@$block ]);
			}
			$block = []; 
			$cnt=0; $last1=-1; $last2=-1;
		      }
		    };
  my $discard=sub { $deltokcnt++;
                    &$adddiscard; #($_[0],$_[1]);
		    push(@$delblock,[ $seq1->[$_[0]],$_[0] ]);
		    $last1=$_[0] };		      

  my $add =   sub { $addtokcnt++;
                    &$adddiscard; #($_[0],$_[1]);
		    push(@$addblock,[ $seq2->[$_[1]],$_[1] ]);
		    $last2=$_[1] };		      

  my $match = sub { $mattokcnt++;
                    if ($cnt==0) {   # first word of matching sequence after changed sequence or at beginning of word sequence
		      $deltextblocks = extracttextblocks($delblock); 
		      $delblkcnt++ if scalar @$delblock;
		      $addtextblocks = extracttextblocks($addblock);
		      $addblkcnt++ if scalar @$addblock;

		      $delcmds = extractcommands($delblock);
      		      $addcmds = extractcommands($addblock);
		      # keygen(third argument of _longestCommonSubsequence) implies to sort on command (0th elements of $addcmd elements)
		      # the calling format for longestCommonSubsequence has changed between versions of
		      # Algorithm::Diff so we need to check which one we are using
		      if ( $algodiffversion  > 1.15 ) {
			### Algorithm::Diff 1.19
			$matchindex=Algorithm::Diff::_longestCommonSubsequence($delcmds,$addcmds, 0, sub { $_[0]->[0] } );
		      } else {
			### Algorithm::Diff 1.15	
			$matchindex=Algorithm::Diff::_longestCommonSubsequence($delcmds,$addcmds, sub { $_[0]->[0] } );
		      }

		      for ($i=0 ; $i<=$#$matchindex ; $i++) {
			if (defined($matchindex->[$i])){
			  $j=$matchindex->[$i];
			  @delmid=splitlatex($delcmds->[$i][3]);
			  @addmid=splitlatex($addcmds->[$j][3]);
			  while (scalar(@$deltextblocks)  && $deltextblocks->[0][0]<$delcmds->[$i][1]) {
			    my ($index,$block,$cnt)=@{ shift(@$deltextblocks) };
			    push(@$todo, [$index,-1,$cnt,@$block]);
			  }
			  push(@$todo, [ $delcmds->[$i][1],-1,-1,$delcmds->[$i][2],@delmid,$delcmds->[$i][4]]);

			  while (scalar(@$addtextblocks) && $addtextblocks->[0][0]<$addcmds->[$j][1]) {
			    my ($index,$block,$cnt)=@{ shift(@$addtextblocks) };
			    push(@$todo, [-1,$index,$cnt,@$block]);
			  }
			  push(@$todo, [ -1,$addcmds->[$j][1],-1,$addcmds->[$j][2],@addmid,$addcmds->[$j][4]]);
			}
		      }
		      # mop up remaining textblocks
		      while (scalar(@$deltextblocks)) {
			my ($index,$block,$cnt)=@{ shift(@$deltextblocks) } ;
			push(@$todo, [$index,-1,$cnt,@$block]);
		      }
		      while (scalar(@$addtextblocks)) {
			my ($index,$block,$cnt)=@{ shift(@$addtextblocks) };
			push(@$todo, [-1,$index,$cnt,@$block]);
		      }
		      
		      $addblock=[];
		      $delblock=[];
		    }
		    push(@$block,$seq2->[$_[1]]);  
		    $cnt++  };

  my $keyfunc = sub { join("  ",split(" ",shift())) };

  traverse_sequences($seq1,$seq2, { MATCH=>$match, DISCARD_A=>$discard, DISCARD_B=>$add }, $keyfunc );


  # now carry out the merging/splitting.  Refer to elements relative from 
  # the end (with negative indices) as these offsets don't change before the instruction is executed
  # cnt>0: merged small unchanged groups with previous changed blocks
  # cnt==-1: split textual commands into components
  foreach $instruction ( @$todo) {
    ($last1,$last2,$cnt,@$block)=@$instruction ;
    if ($cnt>=0) {
      splice(@$seq1,$last1-$len1,1+$cnt,join("",$seq1->[$last1-$len1],@$block)) if $last1>=0;
      splice(@$seq2,$last2-$len2,1+$cnt,join("",$seq2->[$last2-$len2],@$block)) if $last2>=0;
    } else {
      splice(@$seq1,$last1-$len1,1,@$block) if $last1>=0;
      splice(@$seq2,$last2-$len2,1,@$block) if $last2>=0;
    }
  }

  if ($verbose) { 
    print STDERR "\n";
    print STDERR "  $mattokcnt matching  tokens in $matblkcnt blocks.\n";
    print STDERR "  $deltokcnt discarded tokens in $delblkcnt blocks.\n";
    print STDERR "  $addtokcnt appended  tokens in $addblkcnt blocks.\n";
  }
}


# extracttextblocks(\@blockindex)
# $blockindex has the following format 
# [ [ token1, index1 ], [token2, index2],.. ] 
# where index refers to the index in the original old or new word sequence 
# Returns: reference to an array of the form  
# [[ $index, $textblock, $cnt ], ..
# where $index index of block to be merged
#       $textblock contains all the words to be merged with the word at $index (but does not contain this word)
#       $cnt   is length of block
#
# requires: iscmd
#
sub extracttextblocks { 
  my $block=shift;
  my ($i,$token,$index);
  my $textblock=[];
  my $last=-1;
  my $wpat=qr/^(?:[a-zA-Z.,'`:;?()!]*)[\s~]*$/;  #'
  my $retval=[];

  for ($i=0;$i< scalar @$block;$i++) {
    ($token,$index)=@{ $block->[$i] };
    # store pure text blocks
    if ($token =~ /$wpat/ ||  ( $token =~/^\\((?:[`'^"~=.]|[\w\d@\*]+))((?:${extraspace}\[$brat0\]${extraspace}|${extraspace}\{$pat_n\})*)/o 
				&& iscmd($1,\@SAFECMDLIST,\@SAFECMDEXCL) 
				&& !iscmd($1,\@TEXTCMDLIST,\@TEXTCMDEXCL))) {
      # we have text or a command which can be treated as text
      if ($last<0) {
	# new pure-text block
	$last=$index;
      } else {
	# add to pure-text block
	push(@$textblock, $token); 
      }
    } else {
      # it is not text
      if (scalar(@$textblock)) {
	push(@$retval,[ $last, $textblock, scalar(@$textblock) ]);
      }
      $textblock=[];
      $last=-1;
    }
  }
  # finish processing a possibly unfinished block before returning
  if (scalar(@$textblock)) {
    push(@$retval,[ $last, $textblock, scalar(@$textblock) ]);
  }
  return($retval)
}



# extractcommands( \@blockindex )
# $blockindex has the following format 
# [ [ token1, index1 ], [token2, index2],.. ] 
# where index refers to the index in the original old or new word sequence 
# Returns: reference to an array of the form  
# [ [ "\cmd1", index, "\cmd1[optarg]{arg1}{", "arg2" ,"} " ],.. 
# where index is just taken from input array 
# command must have a textual argument as last argument 
# 
# requires: iscmd 
# 
sub extractcommands { 
  my $block=shift;
  my ($i,$token,$index,$cmd,$open,$mid,$closing);
  my $retval=[];

  for ($i=0;$i< scalar @$block;$i++) {
    ($token,$index)=@{ $block->[$i] };
    # check if token is an alphanumeric command sequence with at least one non-optional argument
    # \cmd[...]{...}{last argument}  
    # Capturing in the following results in these associations
    # $1: \cmd[...]{...}{
    # $2: \cmd
    # $3: last argument
    # $4: }  + trailing spaces
    if ( ( $token =~ m/^(\\([\w\d\*]+)(?:${extraspace}\[$brat0\]|${extraspace}\{$pat_n\})*${extraspace}\{)($pat_n)(\}\s*)$/so )
	 && iscmd($2,\@TEXTCMDLIST,\@TEXTCMDEXCL) ) {
      #      push(@$retval,[ $2,$index,$1,$3,$4 ]);
      ($cmd,$open,$mid,$closing) = ($2,$1,$3,$4) ;
      $closing =~ s/\}/\\RIGHTBRACE/ ;
      push(@$retval,[ $cmd,$index,$open,$mid,$closing ]);
    }
  }
  return $retval;
}

# iscmd($cmd,\@regexarray,\@regexexcl) checks
# return 1 if $cmd matches any of the patterns in the 
# array $@regexarray, and none of the patterns in \@regexexcl, otherwise return 0
sub iscmd {
  my ($cmd,$regexar,$regexexcl)=@_;
  my ($ret)=0;
  foreach $pat ( @$regexar ) {
    if ( $cmd =~ m/^${pat}$/ ) {
      $ret=1 ; 
      last;
    }
  }
  return 0 unless $ret;
  foreach $pat ( @$regexexcl ) {
    return 0 if ( $cmd =~ m/^${pat}$/ );
  }
  return 1;
}


# pass2( \@seq1,\@seq2)
# Look for differences between seq1 and seq2.  
# Mark begin and end of deleted and appended sequences with tags $DELOPEN and $DELCLOSE
# and $ADDOPEN and $ADDCLOSE, respectively, however exclude { } & and all comands, unless
# they match an element of the whitelist (SAFECMD)
# For words in TEXTCMD but not in SAFECMD, enclose interior with $ADDOPEN and $ADDCLOSE brackets
# Deleted comment lines are marked with %DIF < 
# Added comment lines are marked with %DIF > 
sub pass2 {
  my $seq1 = shift ;
  my $seq2 = shift ;

  my ($addtokcnt,$deltokcnt,$mattokcnt)=(0,0,0);
  my ($addblkcnt,$delblkcnt,$matblkcnt)=(0,0,0);

  my $retval = [];
  my $delhunk   = [];
  my $addhunk   = [];

  my $discard = sub { $deltokcnt++;
                      push ( @$delhunk, $seq1->[$_[0]]) };

  my $add = sub { $addtokcnt++;
                  push ( @$addhunk, $seq2->[$_[1]]) };

  my $match = sub { $mattokcnt++;
		    if ( scalar @$delhunk ) {
                      $delblkcnt++;
		      # mark up changes, but comment out commands
                      push @$retval,marktags($DELMARKOPEN,$DELMARKCLOSE,$DELOPEN,$DELCLOSE,$DELCMDOPEN,$DELCMDCLOSE,$DELCOMMENT,$delhunk);
		      $delhunk = [];
		    }
                    if ( scalar @$addhunk ) {
                      $addblkcnt++;
                      # we mark up changes, but simply quote commands
                      push @$retval,marktags($ADDMARKOPEN,$ADDMARKCLOSE,$ADDOPEN,$ADDCLOSE,"","",$ADDCOMMENT,$addhunk);
		      $addhunk = [];
		    }
		    push(@$retval,$seq2->[$_[1]]) };
 
  my $keyfunc = sub { join("  ",split(" ",shift())) };

  traverse_sequences($seq1,$seq2, { MATCH=>$match, DISCARD_A=>$discard, DISCARD_B=>$add }, $keyfunc );
  # clear up unprocessed hunks
  push @$retval,marktags($DELMARKOPEN,$DELMARKCLOSE,$DELOPEN,$DELCLOSE,$DELCMDOPEN,$DELCMDCLOSE,$DELCOMMENT,$delhunk) if scalar @$delhunk;
  push @$retval,marktags($ADDMARKOPEN,$ADDMARKCLOSE,$ADDOPEN,$ADDCLOSE,"","",$ADDCOMMENT,$addhunk) if scalar @$addhunk;


  if ($verbose) { 
    print STDERR "\n";
    print STDERR "  $mattokcnt matching  tokens. \n";
    print STDERR "  $deltokcnt discarded tokens in $delblkcnt blocks.\n";
    print STDERR "  $addtokcnt appended  tokens in $addblkcnt blocks.\n";
  }

  return(@$retval);
}

# marktags($openmark,$closemark,$open,$close,$opencmd,$closecmd,$comment,\@block)
# returns ($openmark,$open,$block,$close,$closemark) if @block contains no commands (except white-listed ones),
# braces, ampersands, or comments
# mark comments with $comment
# exclude all other exceptions from scope of open, close like this
# ($openmark, $open,...,$close, $opencmd,command, command,$closecmd, $open, ..., $close, $closemark)
# If $opencmd begins with "%" marktags assumes it is operating on a deleted block, otherwise on an added block
sub marktags {
  my ($openmark,$closemark,$open,$close,$opencmd,$closecmd,$comment,$block)=@_;
  my $word;
  my (@argtext);
  my $retval=[];
  my $noncomment=0;
  my $cmd=-1;    # -1 at beginning 0: last token written is a ordinary word 
                 # 1: last token written is a command
                # for keeping track whether we are just in a command sequence or in a word sequence
  my $cmdcomment= ($opencmd =~ m/^%/);  # Flag to indicate whether opencmd is a comment (i.e. if we intend to simply comment out changed commands)
  my ($command,$commandword,$closingbracket) ; # temporary variables needed below to remember sub-pattern matches

# split this block to flatten out sequences joined in pass1
  @$block=splitlatex(join "",@$block);
  ### print STDERR "DEBUG: marktags $openmark,$closemark,$open,$close,$opencmd,$closecmd,$comment\n" if $debug;
  ### print STDERR "DEBUG: marktags blocksplit ",join("|",@$block),"\n" if $debug;
  foreach (@$block) {
    $word=$_; 
    ### print STDERR "DEBUG MARKTAGS: |$word|\n" if $debug;
    if ( $word =~ s/^%/%$comment/ ) {
      # a comment
      if ($cmd==1) {
	push (@$retval,$closecmd) ;
	$cmd=-1;
      }
      push (@$retval,$word); 
      next;
    }
    if ( $word =~ m/^\s*$/ ) {
      ### print STDERR "DEBUG MARKTAGS: whitespace detected |$word| cmdcom |$cmdcomment| |$opencmd|\n" if $debug;
      # a sequence of white-space characters - this should only ever happen for the first element of block.
      # in deleted block, omit, otherwise just copy it in 
      if ( ! $cmdcomment) {   # ignore in deleted blocks
	push(@$retval,$word);
      }
      next;
    }
    if (! $noncomment) {
      push (@$retval,$openmark); 
      $noncomment=1;
    }
    # negative lookahead pattern (?!) in second clause is put in to avoid matching \( .. \) patterns
    # also note that second pattern will match \\
    ### print STDERR "DEBUG marktags: Considering word |$word|\n";
    if ( $word =~ /^[&{}\[\]]/ || ( $word =~ /^\\(?!\()(\\|[`'^"~=.]|[\w*@]+)/ &&  !iscmd($1,\@SAFECMDLIST,\@SAFECMDEXCL)) ) {
      ###print STDERR "DEBUG MARKTAGS is a non-safe command ($1)\n" if $debug;
      ###    if ( $word =~ /^[&{}\[\]]/ || ( $word =~ /^\\([\w*@\\% ]+)/ && !iscmd($1,\@SAFECMDLIST,\@SAFECMDEXCL)) ) {
      # word is a command or other significant token (not in SAFECMDLIST)
	## same conditions as in subroutine extractcommand:
	# check if token is an alphanumeric command sequence with at least one non-optional argument
	# \cmd[...]{...}{last argument}  
	# Capturing in the following results in these associations
	# $1: \cmd[...]{...}{
	# $2: cmd
	# $3: last argument
	# $4: }  + trailing spaces
	### pre-0.3    if ( ( $token =~ m/^(\\([\w\d\*]+)(?:\[$brat0\]|\{$pat_n\})*\{)($pat_n)(\}\s*)$/so )
      if ( ( $word =~ m/^(\\([\w\d\*]+)(?:${extraspace}\[$brat0\]|${extraspace}\{$pat_n\})*${extraspace}\{)($pat_n)(\}\s*)$/so )
	   && (iscmd($2,\@TEXTCMDLIST,\@TEXTCMDEXCL)|| iscmd($2,\@MATHTEXTCMDLIST,\@MATHTEXTCMDEXCL))
           && ( !$cmdcomment || !iscmd($2,\@CONTEXT2CMDLIST, \@CONTEXT2CMDEXCL) )  ) {
	# Condition 1: word is a command? - if yes, $1,$2,.. will be set as above
        # Condition 2: word is a text command - we mark up the interior of the word. There is a separate check for MATHTEXTCMDLIST
        #              because for $mathmarkup=WHOLE, the commands should not be split in pass1 (ie. math mode commands are not in
        #              TEXTCMDLIST, but the interior of MATHTEXT commands should be highlighted in both deleted and added blocks
        # Condition 3: But if we are in a deleted block ($cmdcomment=1) and
        #            $2 (the command) is in context2, just treat it as an ordinary command (i.e. comment it open with $opencmd)
        # Because we do not want to disable this command
	# here we do not use $opencmd and $closecmd($opencmd is empty) 
	if ($cmd==1) {
	  push (@$retval,$closecmd) ;
	} elsif ($cmd==0) { 
	  push (@$retval,$close) ;
	}
        $command=$1; $commandword=$2; $closingbracket=$4;
	@argtext=splitlatex($3);   # split textual argument into tokens
	# and mark it up (but we do not need openmark and closemark)
        # insert command with initial arguments, marked-up final argument, and closing bracket
	if ( $cmdcomment && iscmd($commandword,\@CONTEXT1CMDLIST, \@CONTEXT1CMDEXCL) ) {
	  # context1cmd in a deleted environment; delete command itself but keep last argument, marked up
	  push (@$retval,$opencmd);
	  $command =~ s/\n/\n${opencmd}/sg ; # repeat opencmd at the beginning of each line
	  # argument, note that the additional comment character is included
          # to suppress linebreak after opening parentheses, which is important
          # for latexrevise
          push (@$retval,$command,"%\n{$AUXCMD\n",marktags("","",$open,$close,$opencmd,$closecmd,$comment,\@argtext),$closingbracket);
        } elsif ( iscmd($commandword,,\@MATHTEXTCMDLIST, \@MATHTEXTCMDEXCL) ) {
	  # MATHBLOCK pseudo command: consider all commands safe, except & and \\	
	  # Keep these commands even in deleted blocks, hence set $opencmd and $closecmd (5th and 6th argument of marktags) to 
	  # ""
	  local @SAFECMDLIST=(".*"); 
	  local @SAFECMDEXCL=('\\','\\\\',@UNSAFEMATHCMD);
	  push(@$retval,$command,marktags("","",$open,$close,"","",$comment,\@argtext)#@argtext
                       ,$closingbracket);
        } else {
	  # normal textcmd or context1cmd in an added block
	  push (@$retval,$command,marktags("","",$open,$close,$opencmd,$closecmd,$comment,\@argtext),$closingbracket);  
	}
	push (@$retval,$AUXCMD,"\n") if $cmdcomment ;
	$cmd=-1 ;
      } else {
	# ordinary command
	push (@$retval,$opencmd) if $cmd==-1 ;
	push (@$retval,$close,$opencmd) if $cmd==0 ;
	$word =~ s/\n/\n${opencmd}/sg if $cmdcomment ;   # if opencmd is a comment, repeat this at the beginning of every line
        ### print STDERR "MARKTAGS: Add command |$word|\n";
	push (@$retval,$word);
	$cmd=1;
      }
    } else {
      ###print STDERR "DEBUG MARKTAGS is an ordinary word or SAFECMD command \n" if $debug;
      # just an ordinary word or command in SAFECMD
      push (@$retval,$open) if $cmd==-1 ;
      push (@$retval,$closecmd,$open) if $cmd==1 ;
      ###TODO:  check here if it is a command in MBOXCMD list, and surround it with \mbox{...}
      ### $word =~ /^\\(?!\()(\\|[`'^"~=.]|[\w*@]+)/ &&  iscmd($1,\@MBOXCMDLIST,\@MBOXCMDEXCL))
      ### but actually this check has been carried out already so can simply check if word begins with backslash
      if ( $word =~ /^\\(?!\()(\\|[`'^"~=.]|[\w*@]+)(.*?)(\s*)$/s &&  iscmd($1,\@MBOXCMDLIST,\@MBOXCMDEXCL)) {
	# $word is a safe command in MBOXCMDLIST
	###print STDERR "DEBUG Mboxsafecmd detected:$word:\n" if $debug ;
	push(@$retval,"\\mbox{$AUXCMD\n\\" . $1 . $2 . $3 ."}\\hspace{0pt}$AUXCMD\n" );
      } else {
	# $word is a normal word or a safe command (not in MBOXCMDLIST)
	push (@$retval,$word);
      }
      $cmd=0;
    }
  }
  push (@$retval,$close) if $cmd==0;
  push (@$retval,$closecmd) if $cmd==1;

  push (@$retval,$closemark) if ($noncomment);
  return @$retval;
}

#used in preprocess
sub take_comments_and_enter_from_frac() {
      #*************take the \n and % between frac and {}***********
      #notice all of the substitution are made none global
      while( m/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)}(.*?)\\frac(([\s]*%[^\n]*?)*[\r\n|\r|\n])+\{(.*?)\\end\{\1}/s ) {
	# if there isn't any % or \n in the pattern $2 then there should be an \\end{...} in $2
	### print STDERR "Match the following in take_comments and_enter_from_frac(1):\n****$&****\n" if $debug;
	if( $2 !~ m/\\end\{$1}/s ) {
	  # take out % and \n from the next match only (none global)
		s/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)}(.*?)\\frac(([\s]*%[^\n]*?)*[\r\n|\r|\n])+\{(.*?)\\end\{\1}/\\begin{$1}$2\\frac{$5\\end{$1}/s;
	}
	else{
	  #there are no more % and \n in $2, we want to find the next one so we clear the begin-end from the pattern
		s/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)}(.*?)\\end\{\1}/MATHBLOCK$1\{$2\}MATHBLOCKEND/s;
	}
      }
      ###cleaning up
      while( s/MATHBLOCK($MATHENV|$MATHARRENV|SQUAREBRACKET)\{(.*?)\}MATHBLOCKEND/\\begin{$1}$2\\end{$1}/s ){}
      ###*************take the \n and % between frac and {}***********
      
      ###**********take the \n and % between {} and {} of the frac***************
      while( m/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)\}(.*?)\\frac\{(.*?)\\end\{\1\}/s ) {
	# if there isn't any more //frac before the first //end in the pattern $2 then there should be an \\end{...} in $2
	###print STDERR "Match the following in take_comments and_enter_from_frac(2):\n****$&****\n" if $debug;
        if( $2 !~ m/\\end\{$1\}/s ) {
          # from now on CURRFRAC is the frac we are looking at
          s/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)\}(.*?)\\frac\{(.*?)\\end\{\1\}/\\begin\{$1\}$2CURRFRAC\{$3\\end\{$1\}/s;
          while( m/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)\}(.*?)CURRFRAC\{(.*?)\\end\{\1\}/s ) {
             if( m/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)\}(.*?)CURRFRAC\{($pat_n)\}([\s]*(%[^\n]*?)*[\r\n|\r|\n])+[\s]*\{(.*?)\\end\{\1}/s ) {
                   s/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)\}(.*?)CURRFRAC\{($pat_n)\}([\s]*(%[^\n]*?)*[\r\n|\r|\n])+[\s]*\{(.*?)\\end\{\1\}/\\begin\{$1\}$2CURRFRAC\{$3\}\{$6\\end\{$1\}/s;
               } 
              else { # there is no comment or \n between the two brackets {}{}
              # change CURRFRAC to FRACSTART so we can change them all back to //frac{ when we finish
                   s/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)}(.*?)CURRFRAC\{(.*?)\\end\{\1}/\\begin{$1}$2FRACSTART\{$3\\end{$1}/s;
              }
            }
        }
        else{
          ###there are no more frac in $2, we want to find the next one so we clear the begin-end from the pattern
          s/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)}(.*?)\\end\{\1}/MATHBLOCK$1\{$2\}MATHBLOCKEND/s;
        }
        
      }
      ###cleaning up
      while( s/MATHBLOCK($MATHENV|$MATHARRENV|SQUAREBRACKET)\{(.*?)\}MATHBLOCKEND/\\begin{$1}$2\\end{$1}/s ){}
      s/FRACSTART/\\frac/g;
      ###***************take the \n and % between {} and {} of the frac*********************
}

# preprocess($string, ..)
# carry out the following pre-processing steps for all arguments:
# 1. Remove leading white-space
#    Change \{ to \QLEFTBRACE and \} to \QRIGHTBRACE and \& to \AMPERSAND
# #.   Change {,} in comments to \CLEFTBRACE, \CRIGHTBRACE
# 2. mark all first empty line (in block of several) with \PAR tokens
# 3. Convert all '\%' into '\PERCENTAGE ' and all '\$' into \DOLLAR to make parsing regular expressions easier
# 4. Convert all \verb|some verbatim text| commands (where | can be an arbitrary character)
#    into \verb{hash}  (also lstinline)
# 5. Convert \begin{verbatim} some verbatim text \end{verbatim} into \verbatim{hash}  (not only verbatim, all patterns matching VERBATIMENV)
# 6. Convert _n into \SUBSCRIPTNB{n} and _{nnn} into \SUBSCRIPT{nn}
# 7. Convert ^n into \SUPERSCRIPTNB{n} and ^{nnn} into \SUPERSCRIPT{nn}
# 8. a. Convert $$ $$ into \begin{DOLLARDOLLAR} \end{DOLLARDOLLAR}
#    b. Convert \[ \] into \begin{SQUAREBRACKET} \end{SQUAREBRACKET}
# 9. Convert all picture environmentent (\begin{PICTUREENV} .. \end{PICTUREENV} \PICTUREBLOCKenv
#     For --block-math-markup option -convert all \begin{MATH} .. \end{MATH}
#    into \MATHBLOCKmath{...} commands, where MATH/math is any valid math environment

# 10. Add final token STOP to the very end.  This is put in because the algorithm works better if the last token is identical.  This is removed again in postprocessing.
#
# NB: step 6 and 7 is likely to  convert some "_" inappropriately, e.g. in file
#     names or labels but it does not matter because they are converted back in the postprocessing step
# Returns: leading white space removed in step 1
sub preprocess {
  for (@_) { 


    # change in \verb and similar commands - note that I introduce an extra space here so that the 
    #       already hashed variants do not trigger again
    # transform \lstinline{...}
#    s/\\lstinline(\[$brat0\])?(\{(?:.*?)\})/"\\DIFlstinline". $1 ."{". tohash(\%verbhash,"$2") ."}"/esg;
#    s/\\lstinline(\[$brat0\])?((\S).*?\2)/"\\DIFlstinline". $1 ."{". tohash(\%verbhash,"$2") ."}"/esg;
    s/\\lstinline((?:\[$brat0\])?)(\{(?:.*?)\})/"\\DIFlstinline". $1 ."{". tohash(\%verbhash,"$2") ."}"/esg;
    s/\\lstinline((?:\[$brat0\])?)((\S).*?\3)/"\\DIFlstinline". $1 ."{". tohash(\%verbhash,"$2") ."}"/esg;
    s/\\(verb\*?|lstinline)(\S)(.*?)\2/"\\DIF${1}{". tohash(\%verbhash,"${2}${3}${2}") ."}"/esg;

    #    Change \{ to \QLEFTBRACE, \} to \QRIGHTBRACE, and \& to \AMPERSAND
    s/(?<!\\)\\\{/\\QLEFTBRACE /sg;
    s/(?<!\\)\\\}/\\QRIGHTBRACE /sg;
    s/(?<!\\)\\&/\\AMPERSAND /sg;
# replace {,} in comments with \\CLEFTBRACE,\\CRIGHTBRACE
    1 while s/((?<!\\)%.*)\{(.*)$/$1\\CLEFTBRACE $2/mg ;
    1 while s/((?<!\\)%.*)\}(.*)$/$1\\CRIGHTBRACE $2/mg ;
    s/\n(\s*?)\n((?:\s*\n)*)/\n$1\\PAR\n$2/g ;
    s/(?<!\\)\\%/\\PERCENTAGE /g ;  # (?<! is negative lookbehind assertion to prevent \\% from being converted
    s/(?<!\\)\\\$/\\DOLLAR /g ;  # (?<! is negative lookbehind assertion to prevent \\$ from being converted
    s/\\begin\{($VERBATIMENV)\}(.*?)\\end\{\1\}/"\\${1}{". tohash(\%verbhash,"${2}") . "}"/esg;
    # Convert _n or _\cmd into \SUBSCRIPTNB{n} or \SUBSCRIPTNB{\cmd} and _{nnn} into \SUBSCRIPT{nn}
    1 while s/(?<!\\)_(\s*([^{\\\s]|\\\w+))/\\SUBSCRIPTNB{$1}/g ;
    1 while s/(?<!\\)_(\s*{($pat_n)})/\\SUBSCRIPT$1/g ;
    # Convert ^n into \SUPERSCRIPTNB{n} and ^{nnn} into \SUPERSCRIPT{nn}
    1 while s/(?<!\\)\^(\s*([^{\\\s]|\\\w+))/\\SUPERSCRIPTNB{$1}/g ;
    1 while s/(?<!\\)\^(\s*{($pat_n)})/\\SUPERSCRIPT$1/g ;  
    # Convert  \sqrt{n} into \SQRT{n}  and  \sqrt nn into SQRTNB{nn}
    1 while s/(?<!\\)\\sqrt(\s*([^{\\\s]|\\\w+))/\\SQRTNB{$1}/g ;
    1 while s/(?<!\\)\\sqrt(\s*{($pat_n)})/\\SQRT$1/g ;
    # Convert $$ $$ into \begin{DOLLARDOLLAR} \end{DOLLARDOLLAR}
    s/\$\$(.*?)\$\$/\\begin{DOLLARDOLLAR}$1\\end{DOLLARDOLLAR}/sg;
    # Convert \[ \] into \begin{SQUAREBRACKET} \end{SQUAREBRACKET}
    s/(?<!\\)\\\[/\\begin{SQUAREBRACKET}/sg;
    s/\\\]/\\end{SQUAREBRACKET}/sg;
    # Convert all picture environmentent (\begin{PICTUREENV} .. \end{PICTUREENV} \PICTUREBLOCKenv
    s/\\begin\{($PICTUREENV)}(.*?)\\end\{\1}/\\PICTUREBLOCK$1\{$2\}/sg;
    #    For --block-math-markup option -convert all \begin{MATH} .. \end{MATH}
    #    into \MATHBLOCKMATH{...} commands, where MATH is any valid math environment
    #    Also convert all array environments into ARRAYBLOCK environments

    if ( $mathmarkup != FINE ) {
      s/\\begin\{($ARRENV)}(.*?)\\end\{\1}/\\ARRAYBLOCK$1\{$2\}/sg;
      
      take_comments_and_enter_from_frac();
      

      s/\\begin\{($MATHENV|$MATHARRENV|SQUAREBRACKET)\}(.*?)\\end\{\1\}/\\MATHBLOCK$1\{$2\}/sg;
    }

    # add final token " STOP"
    $_ .= " STOP"
  }
}

#hashstring=tohash(\%hash,$string)
# creates a hash value based on string and stores in %hash
sub tohash {
  my ($hash,$string)=@_;
  my (@arr,$val);
  my ($sum,$i)=(0,1);
  my ($hstr);

  @arr=unpack('c*',$string);

  while (1) {
    foreach $val (@arr) {
      $sum += $i*$val;
      $i++;
    }
    $hstr= "$sum";
    last unless (defined($hash->{$hstr}) && $string ne $hash->{$hstr});
    # else found a duplicate HASH need to repeat for a higher hash value
  }
  $hash->{$hstr}=$string;
  ###  print STDERR "Hash:$hstr: Content:$string:\n";
  return($hstr);
}

#string=fromhash(\%hash,$fromstring)
# restores string value stored in hash
#string=fromhash(\%hash,$fromstring,$prependstring)
# additionally begins each line with prependstring
sub fromhash {
  my ($hash,$hstr)=($_[0],$_[1]);
  my $retstr=$hash->{$hstr};
  if ( $#_ >= 2) {
    $retstr =~ s/^/$_[2]/mg;
  }
  return $retstr;
}


# postprocess($string, ..)
# carry out the following post-processing steps for all arguments:
# * Remove STOP token from the end
# * Replace \RIGHTBRACE by }
# *  change citation commands within comments to protect from processing (using marker CITEDIF)
# 1. Check all deleted blocks: 
#    a.where a deleted block contains a matching \begin and
#      \end environment (these will be disabled by a %DIFDELCMD statements), for selected environments enable
#      these commands again (such that for example displayed math in a deleted equation
#      is properly within math mode.  For math mode environments replace numbered equation
#      environments with their display only variety (so that equation numbers in new file and
#      diff file are identical).  Where the correct type of math environment cannot be determined
#      use a place holder MATHMODE
#    b.where one of the commands matching $COUNTERCMD is used as a DIFAUXCMD, add a statement
#      subtracting one from the respective counter to keep numbering consistent with new file
#    Replace all MATHMODE environment commands by the correct environment to achieve matching
#    pairs
#    c. Convert MATHBLOCKmath commands to their uncounted numbers (e.g. convert equation -> displaymath
#       (environments defined in $MATHENV will be replaced by $MATHREPL, and  environments in $MATHARRENV
#       will be replaced by $MATHARRREPL
#    d. If in-line math mode contains array environment, enclose the whole environment in \mbox'es
#    d. place \cite commands in mbox'es (for UNDERLINE style)
#
#   For added blocks:
#    c. If in-line math mode contains array environment, enclose the whole environment in \mbox'es
#    d. place \cite commands in mbox'es (for UNDERLINE style)
#     
# 2.   If --block-math-markup option set: Convert \MATHBLOCKmath{..} commands back to environments
#
#      Convert all PICTUREblock{..} commands back to the appropriate environments
# 3. Convert DIFadd, DIFdel, DIFaddbegin , ... into FL varieties
#    within floats (currently recognised float environments: plate,table,figure
#    plus starred varieties).
# 4. Remove empty %DIFDELCMD < lines 
# 4. Convert \begin{SQUAREBRACKET} \end{SQUAREBRACKET} into \[ \]
#    Convert \begin{DOLLARDOLLAR} \end{DOLLARDOLLAR} into $$ $$
# 5. Convert  \SUPERSCRIPTNB{n} into ^n  and  \SUPERSCRIPT{nn} into ^{nnn}
# 6. Convert  \SUBSCRIPTNB{n} into _n  and  \SUBCRIPT{nn} into _{nnn}
# 7. Expand hashes of verb and verbatim environments
# 8. Convert '\PERCENTAGE ' back into '\%' and '\DOLLAR ' into '\$'
# 9.. remove all \PAR tokens
# 10.  package specific processing:  endfloat: make sure \begin{figure} and \end{figure} are always
#      on a line by themselves, similarly for table environment
#  4, undo renaming of the \begin, \end,{,}  in comments
#    Change \QLEFTBRACE, \QRIGHTBRACE,\AMPERSAND to \{,\},\&
#
# Note have to manually synchronize substitution commands below and 
# DIF.. command names in the header
sub postprocess {
  my ($begin,$len,$cnt,$float,$delblock,$addblock);
  # second level blocks
  my ($begin2,$cnt2,$len2,$eqarrayblock,$mathblock);

  my (@textparts,@newtextparts,@liststack,$listtype,$listlast);

  for (@_) { 

    # change $'s in comments to something harmless
    1 while s/(%.*)\$/$1DOLLARDIF/mg ;

    # Remove final STOP token
    s/ STOP$//;
    # Replace \RIGHTBRACE by }    
    s/\\RIGHTBRACE/}/g;


    # Check all deleted blocks: where a deleted block contains a matching \begin and
    #    \end environment (these will be disabled by a %DIFDELCMD statements), enable
    #    these commands again (such that for example displayed math in a deleted equation
    #    is properly within math mode.  For math mode environments replace numbered equation
    #    environments with their display only variety (so that equation numbers in new file and
    #    diff file are identical
    while ( m/\\DIFdelbegin.*?\\DIFdelend/sg ) {
      $cnt=0;
      $len=length($&);
      $begin=pos($_) - $len;
      $delblock=$&;


      ### (.*?[^\n]?)\n? construct is necessary to avoid empty lines in math mode, which result in
      ### an error
      # displayed math environments
      if ($mathmarkup == FINE ) {
	$delblock=~ s/(\%DIFDELCMD < \s*\\begin\{((?:$MATHENV)|SQUAREBRACKET)\}.*?(?:$DELCMDCLOSE|\n))(.*?[^\n]?)\n?(\%DIFDELCMD < \s*\\end\{\2\})/\\begin{$MATHREPL}$AUXCMD\n$1$3\n\\end{$MATHREPL}$AUXCMD\n$4/sg;
	# also transform the opposite pair \end{displaymath} .. \begin{displaymath} but we have to be careful not to interfere with the results of the transformation in the line directly above
	### pre-0.42 obsolete version which did not work on eqnarray test      $delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\end\{($MATHENV)\}\s*?\n)(.*?[^\n]?)\n?(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\begin\{\2\})/$1\\end{$MATHREPL}$AUXCMD\n$3\n\\begin{$MATHREPL}$AUXCMD\n$4/sg;
	###0.5:      $delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\end\{((?:$MATHENV)|SQUAREBRACKET)\}\s*?(?:$DELCMDCLOSE|\n))(.*?[^\n]?)\n?(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\begin\{\2\})/\\end{MATHMODE}$AUXCMD\n$1$3\n\\begin{MATHMODE}$AUXCMD\n$4/sg;
	$delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\end\{((?:$MATHENV)|SQUAREBRACKET)\}.*?(?:$DELCMDCLOSE|\n))(.*?[^\n]?)\n?(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\begin\{\2\})/\\end\{MATHMODE\}$AUXCMD\n$1$3\n\\begin\{MATHMODE\}$AUXCMD\n$4/sg;
  
        # now look for unpaired %DIFDELCMD < \begin{MATHENV}; if found add \begin{$MATHREPL} and insert \end{$MATHREPL} 
        # just before end of block; again we use look-behind assertion to avoid matching constructions which have already been converted
        if ($delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\begin\{((?:$MATHENV)|SQUAREBRACKET)\}\s*?(?:$DELCMDCLOSE|\n))/$1\\begin{$MATHREPL}$AUXCMD\n/sg ) {
	  $delblock =~ s/(\\DIFdelend$)/\\end{$MATHREPL}$AUXCMD\n$1/s ;
        }
        # now look for unpaired %DIFDELCMD < \end{MATHENV}; if found add \end{MATHMODE} and insert \begin{MATHMODE} 
        # just before end of block; again we use look-behind assertion to avoid matching constructions which have already been converted
        if ($delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\end\{((?:$MATHENV)|SQUAREBRACKET)\}\s*?(?:$DELCMDCLOSE|\n))/$1\\end\{MATHMODE\}$AUXCMD\n/sg ) {
	  $delblock =~ s/(\\DIFdelend$)/\\begin\{MATHMODE\}$AUXCMD\n$1/s ;
	}


	### pre-0.42      # same as above for special case \[.\] (latex abbreviation for displaymath)
        ### pre-0.42      $delblock=~ s/(\%DIFDELCMD < \s*\\\[\s*?\n())(.*?[^\n]?)\n?(\%DIFDELCMD < \s*\\\])/$1\\\[$AUXCMD\n$3\n\\\]$AUXCMD\n$4/sg;
        ### pre-0.42      $delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\\]\s*?\n())(.*?[^\n]?)\n?(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\\[)/$1\\\]$AUXCMD\n$3\n\\\[$AUXCMD\n$4/sg;
        # equation array environment
        ###pre-0.3      $delblock=~ s/(\%DIFDELCMD < \s*\\begin\{($MATHARRENV)\}\s*?\n)(.*?)(\%DIFDELCMD < \s*\\end\{\2\})/$1\\begin{$MATHARRREPL}$AUXCMD\n$3\n\\end{$MATHARRREPL}$AUXCMD\n$4/sg;
        ###0.5      $delblock=~ s/(\%DIFDELCMD < \s*\\begin\{($MATHARRENV)\}\s*?(?:$DELCMDCLOSE|\n))(.*?[^\n]?)\n?(\%DIFDELCMD < \s*\\end\{\2\})/\\begin{$MATHARRREPL}$AUXCMD\n$1$3\n\\end{$MATHARRREPL}$AUXCMD\n$4/sg;
        $delblock=~ s/(\%DIFDELCMD < \s*\\begin\{($MATHARRENV)\}.*?(?:$DELCMDCLOSE|\n))(.*?[^\n]?)\n?(\%DIFDELCMD < \s*\\end\{\2\})/\\begin{$MATHARRREPL}$AUXCMD\n$1$3\n\\end{$MATHARRREPL}$AUXCMD\n$4/sg;
        ###  pre-0.42 obsolete version which did not work on eqnarray test     $delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\end\{($MATHARRENV)\}\s*?\n)(.*?[^\n]?)\n?(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\begin\{\2\})/$1\\end{$MATHARRREPL}$AUXCMD\n$3\n\\begin{$MATHARRREPL}$AUXCMD\n$4/sg;
        $delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\end\{($MATHARRENV)\}\s*?(?:$DELCMDCLOSE|\n))(.*?[^\n]?)\n?(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\begin\{\2\})/\\end{MATHMODE}$AUXCMD\n$1$3\n\\begin{MATHMODE}$AUXCMD\n$4/sg;

        # now look for unpaired %DIFDELCMD < \begin{MATHARRENV}; if found add \begin{$MATHARRREPL} and insert \end{$MATHARRREPL} 
        # just before end of block; again we use look-behind assertion to avoid matching constructions which have already been converted
        if ($delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\begin\{($MATHARRENV)\}\s*?(?:$DELCMDCLOSE|\n))/$1\\begin{$MATHARRREPL}$AUXCMD\n/sg ) {
           $delblock =~ s/(\\DIFdelend$)/\\end{$MATHARRREPL}$AUXCMD\n$1/s ;
        }
        # now look for unpaired %DIFDELCMD < \end{MATHENV}; if found add \end{MATHMODE} and insert \begin{MATHMODE} 
        # just before end of block; again we use look-behind assertion to avoid matching constructions which have already been converted
        if ($delblock=~ s/(?<!${AUXCMD}\n)(\%DIFDELCMD < \s*\\end\{($MATHARRENV)\}\s*?(?:$DELCMDCLOSE|\n))/$1\\end{MATHMODE}$AUXCMD\n/sg ) {
	  $delblock =~ s/(\\DIFdelend$)/\\begin{MATHMODE}$AUXCMD\n$1/s ;
        }

      # parse $delblock for deleted and reinstated eqnarray* environments - within those reinstate \\ and & commands
        while ( $delblock =~ m/\\begin\Q{$MATHARRREPL}$AUXCMD\E\n.*?\n\\end\Q{$MATHARRREPL}$AUXCMD\E\n/sg ) {
	  $cnt2=0;
	  $len2=length($&);
	  $begin2=pos($delblock) - $len2;
	  $eqarrayblock=$&;
	  # reinstate deleted & and \\ commands
	  $eqarrayblock=~ s/(\%DIFDELCMD < \s*(\&|\\\\)\s*?(?:$DELCMDCLOSE|\n))/$1$2$AUXCMD\n/sg ;
	  
	  substr($delblock,$begin2,$len2)=$eqarrayblock;
	  pos($delblock) = $begin2 + length($eqarrayblock);
	}
      } elsif ( $mathmarkup == COARSE || $mathmarkup == WHOLE ) {
#       Convert MATHBLOCKmath commands to their uncounted numbers (e.g. convert equation -> displaymath
#       (environments defined in $MATHENV will be replaced by $MATHREPL, and  environments in $MATHARRENV
#       will be replaced by $MATHARRREPL
	$delblock=~ s/\\MATHBLOCK($MATHENV)\{($pat_n)\}/\\MATHBLOCK$MATHREPL\{$2\}/sg;
	$delblock=~ s/\\MATHBLOCK($MATHARRENV)\{($pat_n)\}/\\MATHBLOCK$MATHARRREPL\{$2\}/sg;
      }
      # Reinstate completely deleted list environments. note that items within the 
      # environment will still be commented out.  They will be restored later
      $delblock=~ s/(\%DIFDELCMD < \s*\\begin\{($LISTENV)\}\s*?(?:\n|$DELCMDCLOSE))(.*?)(\%DIFDELCMD < \s*\\end\{\2\})/{
	   ###   # block within the search; replacement environment  
	   ###   "$1\\begin{$2}$AUXCMD\n". restore_item_commands($3). "\n\\end{$2}$AUXCMD\n$4";
	      "$1\\begin{$2}$AUXCMD\n$3\n\\end{$2}$AUXCMD\n$4";
	          }/esg;


#    b.where one of the commands matching $COUNTERCMD is used as a DIFAUXCMD, add a statement
#      subtracting one from the respective counter to keep numbering consistent with new file
      $delblock=~ s/\\($COUNTERCMD)((?:${extraspace}\[$brat0\]${extraspace}|${extraspace}\{$pat_n\})*\s*${AUXCMD}\n)/\\$1$2\\addtocounter{$1}{-1}${AUXCMD}\n/sg ;

#    bb. disable active labels within deleted blocks (as these are not safe commands, this should normally only
#        happen within deleted maths blocks
      $delblock=~ s/(?<!$DELCMDOPEN)(\\$LABELCMD(?:${extraspace})\{(?:[^{}])*\}[\t ]*)\n?/${DELCMDOPEN}$1${DELCMDCLOSE}/smg ;
      # previous line causes trouble as by issue #90 I might need to modify this


#     c. If in-line math mode contains array environment, enclose the whole environment in \mbox'es
      while ( $delblock =~ m/($math)(\s*)/sg ) {
#	      print STDERR "DEBUG Delblock Match math $& at ",pos,"\n";
	$cnt2=0;
	$len2=length($&);
	$begin2=pos($delblock) - $len2;
	$mathblock="%\n\\mbox{$AUXCMD\n$1\n}$AUXCMD\n";
        next unless ( $mathblock =~ /ARRAYBLOCK/ or $mathblock =~ m/\{$ARRENV\}/ );
	substr($delblock,$begin2,$len2)=$mathblock;
	pos($delblock) = $begin2 + length($mathblock);
      }
      # if MBOXINLINEMATH is set, protect inlined math environments with an extra mbox
      if ( $MBOXINLINEMATH ) {
	# note additional \newline after command is omitted from output if right at the end of deleted block (otherwise a spurious empty line is generated)
	$delblock=~s/($math)(?:[\s\n]*)?/\\mbox{$AUXCMD\n$1\n}$AUXCMD\n/sg;
      }
      ###if ( defined($packages{"listings"} and $latexdiffpreamble =~ /\\RequirePackage(?:\[$brat0\])?\{color\}/))   { 
      ###  #     change included verbatim environments
      ###  $delblock =~ s/\\DIFverb\{/\\DIFDIFdelverb\{/g;
      ###  $delblock =~ s/\\DIFlstinline/\\DIFDIFdellstinline/g;
      ###}
      # Mark deleted verbose commands
      $delblock =~ s/(${DELCMDOPEN}\\DIF((?:verb\*?|lstinline(?:\[$brat0\])?)\{([-\d]*?)\}\s*).*)$/%\n\\DIFDIFdel$2${AUXCMD}\n$1/gm;

#     splice in modified delblock
      substr($_,$begin,$len)=$delblock;
      pos = $begin + length($delblock);
    }

    ### print STDERR "<<<$_>>>\n" if $debug;


    # make the array modification in added blocks
    while ( m/\\DIFaddbegin.*?\\DIFaddend/sg ) {
      $cnt=0;
      $len=length($&);
      $begin=pos($_) - $len;
      $addblock=$&;
      while ( $addblock =~ m/($math)(\s*)/sg ) {
	$cnt2=0;
	$len2=length($&);
	$begin2=pos($addblock) - $len2;
	$mathblock="%\n\\mbox{$AUXCMD\n$1\n}$AUXCMD\n";
        next unless ( $mathblock =~ /ARRAYBLOCK/ or $mathblock =~ m/\{$ARRENV\}/) ;
	substr($addblock,$begin2,$len2)=$mathblock;
	pos($addblock) = $begin2 + length($mathblock);
      }
      # if MBOXINLINEMATH is set, protect inlined math environments with an extra mbox
      if ( $MBOXINLINEMATH ) {
	##$addblock=~s/($math)/\\mbox{$AUXCMD\n$1\n}$AUXCMD\n/sg;
	$addblock=~s/($math)(?:[\s\n]*)?/\\mbox{$AUXCMD\n$1\n}$AUXCMD\n/sg;
      }
      ###if ( defined($packages{"listings"} and $latexdiffpreamble =~ /\\RequirePackage(?:\[$brat0\])?\{color\}/))   { 
	# mark added verbatim commands
      $addblock =~ s/\\DIFverb/\\DIFDIFaddverb/g;
      $addblock =~ s/\\DIFlstinline/\\DIFDIFaddlstinline/g;
      ###}
#     splice in modified addblock
      substr($_,$begin,$len)=$addblock;
      pos = $begin + length($addblock);
    }

    # Go through whole text, and by counting list environment commands, find out when we are within a list environment.  
    # Within those restore deleted \item commands
    @textparts=split /(?<!$DELCMDOPEN)(\\(?:begin|end)\{$LISTENV\})/ ; 
    @liststack=();
    @newtextparts=map { 
      ### print STDERR ":::::::: $_\n";
      if ( ($listtype) = m/^\\begin\{($LISTENV)\}$/ ) {
	print STDERR "DEBUG: postprocess \\begin{$listtype}\n" if $debug;
	push @liststack,$listtype;
      } elsif ( ($listtype) = m/^\\end\{($LISTENV)\}$/ ) {
 	print STDERR "DEBUG: postprocess \\end{$listtype}\n" if $debug;
	if (scalar  @liststack > 0) {
 	  $listlast=pop(@liststack);
 	  ($listtype eq $listlast) or warn "Invalid nesting of list environments: $listlast environment closed by \\end{$listtype}.";
 	} else {
 	  warn "Invalid nesting of list environments: \\end{$listtype} encountered without matching \\begin{$listtype}.";
 	}
      } else {
	print STDERR "DEBUG: postprocess \@liststack=(",join(",",@liststack),")\n" if $debug;
	if (scalar  @liststack > 0 ) {
	  # we are within a list environment and should replace all item commands 
	  $_=restore_item_commands($_);
	}
	# else: we are outside a list environment and do not need to do anything
      }
      $_ } @textparts;     # end of map command
    # replace the main text with the modified version
    $_= join("",@newtextparts);




    # Replace MATHMODE environments from step 1a above by the correct Math environment

    # The next line is complicated.  The negative look-ahead insertion makes sure that no \end{$MATHENV} (or other mathematical
    # environments) are between the \begin{$MATHENV} and \end{MATHMODE} commands. This is necessary as the minimal matching 
    # is not globally minimal but only 'locally' (matching is beginning from the left side of the string)
    if ( $mathmarkup == FINE ) {
      1 while s/\\begin\{((?:$MATHENV)|(?:$MATHARRENV)|SQUAREBRACKET)}((?:.(?!(?:\\end\{(?:(?:$MATHENV)|(?:$MATHARRENV)|SQUAREBRACKET)}|\\begin\{MATHMODE})))*?)\\end\{MATHMODE}/\\begin{$1}$2\\end{$1}/s;
      1 while s/\\begin\{MATHMODE}((?:.(?!\\end\{MATHMODE}))*?)\\end\{((?:$MATHENV)|(?:$MATHARRENV)|SQUAREBRACKET)}/\\begin{$2}$1\\end{$2}/s;
      # convert remaining \begin{MATHMODE} \end{MATHMODE} (and not containing & or \\ )into MATHREPL environments
      s/\\begin\{MATHMODE\}((?:(.(?!(?<!\\)\&|\\\\))*)?)\\end\{MATHMODE\}/\\begin{$MATHREPL}$1\\end{$MATHREPL}/sg;
      # others into MATHARRREPL
      s/\\begin\{MATHMODE\}(.*?)\\end\{MATHMODE\}/\\begin{$MATHARRREPL}$1\\end{$MATHARRREPL}/sg;

      # now look for AUXCMD math-mode pairs which have only comments (or empty lines between them), and remove the added commands
      s/\\begin\{((?:$MATHENV)|(?:$MATHARRENV)|SQUAREBRACKET)}$AUXCMD\n((?:\s*%.[^\n]*\n)*)\\end{\1}$AUXCMD\n/$2/sg;       
    } else {
      #   math modes OFF,WHOLE,COARSE: Convert \MATHBLOCKmath{..} commands back to environments
      s/\\MATHBLOCK($MATHENV|$MATHARRENV|SQUAREBRACKET)\{($pat_n)\}/\\begin{$1}$2\\end{$1}/sg;
      # convert ARRAYBLOCK.. commands back to environments
      s/\\ARRAYBLOCK($ARRENV)\{($pat_n)\}/\\begin{$1}$2\\end{$1}/sg;
    }
    #  Convert all PICTUREblock{..} commands back to the appropriate environments
    s/\\PICTUREBLOCK($PICTUREENV)\{($pat_n)\}/\\begin{$1}$2\\end{$1}/sg;
#0.5:    # Remove all mark up within picture environments
#     while ( m/\\begin\{($PICTUREENV)\}.*?\\end\{\1\}/sg ) {
#       $cnt=0;
#       $len=length($&);
#       $begin=pos($_) - $len;
#       $float=$&;
#       $float =~ s/\\DIFaddbegin //g;
#       $float =~ s/\\DIFaddend //g;
#       $float =~ s/\\DIFadd\{($pat_n)\}/$1/g;
#       $float =~ s/\\DIFdelbegin //g;
#       $float =~ s/\\DIFdelend //g;
#       $float =~ s/\\DIFdel\{($pat_n)\}//g;
#       $float =~ s/$DELCMDOPEN.*//g;
#       substr($_,$begin,$len)=$float;
#       pos = $begin + length($float);
#     }
    # Convert DIFadd, DIFdel, DIFFaddbegin , ... into  varieties
    #    within floats (currently recognised float environments: plate,table,figure
    #    plus starred varieties).
    while ( m/\\begin\{($FLOATENV)\}.*?\\end\{\1\}/sg ) {
      $cnt=0;
      $len=length($&);
      $begin=pos($_) - $len;
      $float=$&;
      $float =~ s/\\DIFaddbegin /\\DIFaddbeginFL /g;
      $float =~ s/\\DIFaddend /\\DIFaddendFL /g;
      $float =~ s/\\DIFadd\{/\\DIFaddFL{/g;
      $float =~ s/\\DIFdelbegin /\\DIFdelbeginFL /g;
      $float =~ s/\\DIFdelend /\\DIFdelendFL /g;
      $float =~ s/\\DIFdel\{/\\DIFdelFL{/g;
      substr($_,$begin,$len)=$float;
      pos = $begin + length($float);
    }
    ### former location of undo renaming of \begin and \end in comments

    # remove empty DIFCMD < lines
    s/^\Q${DELCMDOPEN}\E\n//msg;

    # Expand hashes of verb and verbatim environments (note negative look behind assertion to not leak out of DIFDELCMD comments
    s/${DELCMDOPEN}\\($VERBATIMENV)\{([-\d]*?)\}/"${DELCMDOPEN}\\begin{${1}}".fromhash(\%verbhash,$2,$DELCMDOPEN)."${DELCMDOPEN}\\end{${1}}"/esg;
    s/\\($VERBATIMENV)\{([-\d]*?)\}/"\\begin{${1}}".fromhash(\%verbhash,$2)."\\end{${1}}"/esg;
    # remove all \PAR tokens (taking care to properly keep commented out PAR's
    # from introducing uncommented newlines - next line)
    s/(%DIF < )([^\n]*?)\\PAR\n/$1$2\n$1\n/sg;
    # convert PAR commands which are on a line by themselves
    s/\n(\s*?)\\PAR\n/\n\n/sg;
    # convert remaining PAR commands (which are preceded by non-white space characters, usually "}" ($ADDCLOSE)
    s/\\PAR\n/\n\n/sg;

    #  package specific processing: 
    if ( defined($packages{"endfloat"})) {
      #endfloat: make sure \begin{figure} and \end{figure} are always
      #      on a line by themselves, similarly for table environment
      print STDERR "endfloat package detected.\n" if $verbose ;
      # eliminate whitespace before and after
      s/^(\s*)(\\(?:begin|end)\{(?:figure|table)\})(\s*)$/$2/mg;
      # split lines with remaining characters before float environment conmmand
      s/^([^%]+)(\\(?:begin|end)\{(?:figure|table)\})/$1\n$2/mg;
      # split lines with remaining characters after float environment conmmand
      s/^((?:[^%]+)\\(?:begin|end)\{(?:figure|table)\}(?:\[[a-zA-Z]+\])?)(.+)((?:%.*)?)$/$1\n$2$3/mg;
    }

    # Convert '\PERCENTAGE ' back into '\%' (the final question mark catches a special situation where due to a latter pre-processing step the ' ' becomes separated	       
    s/\\PERCENTAGE ?/\\%/g;
    # Convert '\DOLLAR ' back into '\$'			       
    s/\\DOLLAR /\\\$/g;

    # undo renaming of the \begin and \end,{,}  and dollars in comments 
    1 while s/(%.*)DOLLARDIF/$1\$/mg ;
#   Convert \begin{SQUAREBRACKET} \end{SQUAREBRACKET} into \[ \]
    s/\\end\{SQUAREBRACKET\}/\\\]/sg;
    s/\\begin\{SQUAREBRACKET\}/\\\[/sg;
# 4. Convert \begin{DOLLARDOLLAR} \end{DOLLARDOLLAR} into $$ $$
    s/\\begin\{DOLLARDOLLAR\}(.*?)\\end\{DOLLARDOLLAR\}/\$\$$1\$\$/sg;
# 5. Convert  \SUPERSCRIPTNB{n} into ^n  and  \SUPERSCRIPT{nn} into ^{nnn}
    1 while s/\\SUPERSCRIPT(\s*\{($pat_n)\})/^$1/g ;
    1 while s/\\SUPERSCRIPTNB\{(\s*$pat0)\}/^$1/g ;
    # Convert  \SUBSCRIPNB{n} into _n  and  \SUBCRIPT{nn} into _{nnn}
    1 while s/\\SUBSCRIPT(\s*\{($pat_n)\})/_$1/g ;
    1 while s/\\SUBSCRIPTNB\{(\s*$pat0)\}/_$1/g ;
    # Convert  \SQRT{n} into \sqrt{n}  and  \SQRTNB{nn} into \sqrt nn
    1 while s/\\SQRT(\s*\{($pat_n)\})/\\sqrt$1/g ;
    1 while s/\\SQRTNB\{(\s*$pat0)\}/\\sqrt$1/g ;
 
    1 while s/(%.*)\\CRIGHTBRACE (.*)$/$1\}$2/mg ;
    1 while s/(%.*)\\CLEFTBRACE (.*)$/$1\{$2/mg ;


#    Change \QLEFTBRACE, \QRIGHTBRACE to \{,\}
    s/\\QLEFTBRACE /\\\{/sg;
    s/\\QRIGHTBRACE /\\\}/sg;
    s/\\AMPERSAND /\\&/sg;
    # Highligh added inline verbatim commands if possible
    if ( $latexdiffpreamble =~ /\\RequirePackage(?:\[$brat0\])?\{color\}/ )   { 
      # wrap added verb commands with color commands
      s/\\DIFDIFadd((?:verb\*?|lstinline(?:\[$brat0\])?)\{[-\d]*?\}[\s\n]*)/\{\\color{blue}$AUXCMD\n\\DIF$1%\n\}$AUXCMD\n/sg;
      s/\\DIFDIFdel((?:verb\*?|lstinline(?:\[$brat0\])?)\{[-\d]*?\}[\s\n]*$AUXCMD)/\{\\color{red}${AUXCMD}\n\\DIF$1\n\}${AUXCMD}/sg;
    } else {
      # currently if colour markup is not used just remove the added mark
      s/\\DIFDIFadd(verb\*?|lstinline)/\\DIF$1/sg;
      s/\\DIFDIFdel((?:verb\*?|lstinline(?:\[$brat0\])?)\{[-\d]*?\}[\s\n]*$AUXCMD\n)//sg;
    }
    # expand \verb and friends inline arguments
    s/\\DIF((?:DIFadd|DIFdel)?(?:verb\*?|lstinline(?:\[$brat0\])?))\{([-\d]*?)\}/"\\${1}". fromhash(\%verbhash,$2)/esg;
    # add basicstyle color{blue} to added lstinline commands
    # finally add the comment to the ones not having an optional argument before
    ###s/\\DIFaddlstinline(?!\[)/\\lstinline\n[basicstyle=\\color{blue}]$AUXCMD\n/g;

  return;
  }
}

# $out = restore_item_commands($listenviron)
# short helper function for post-process, which restores deleted \item commands in its argument (as DIFAUXCMDs)
sub restore_item_commands {
  my ($string)=@_ ;
  my ($itemarg,@itemargs);
  $string =~ s/(\%DIFDELCMD < \s*(\\$ITEMCMD)((?:<$abrat0>)?)((?:\[$brat0\])?)\s*((?:${cmdoptseq}\s*?)*)(?:\n|$DELCMDCLOSE))/
     # if \item has an []argument, then mark up the argument as deleted)
     if (length($4)>0) {
       # use substr to exclude square brackets at end points
       @itemargs=splitlatex(substr($4,1,length($4)-2));
       $itemarg="[".join("",marktags("","",$DELOPEN,$DELCLOSE,$DELCMDOPEN,$DELCMDCLOSE,$DELCOMMENT,\@itemargs))."]";
     } else {
       $itemarg="";
     }
     "$1$2$3$itemarg$AUXCMD\n";  ###.((length($5)>0) ? "%DIFDELCMD $5 $DELCMDCLOSE\n" : "")
     /sge;
  return($string);
}


# @auxlines=preprocess_preamble($oldpreamble,$newpreamble);
  # pre-process preamble by looking for commands used in \maketitle (title, author, date etc commands) 
  # if found then use a bodydiff to mark up content, and replace the corresponding commands 
  # in both preambles by marked up version to 'fool' the linediff (such that only body is marked
  # up.
  # A special case are e.g. author commands being added (or removed)
  # 1. If commands are added, then the entire content is marked up as new, but also the lines are marked as new in the linediff
  # 2. If commands are removed, then the linediff will mark the line as deleted.  The program returns 
  #    with $auxlines a text to be appended at the end of the preamble, which shows the respective fields as deleted
sub preprocess_preamble {
  my ($oldpreambleref,$newpreambleref)=(\$_[0],\$_[1]) ;
  my @auxlines=();
  # Remember to use $$oldpreambleref to refer to oldpreamble
  my ($titlecmd,$titlecmdpat);
  my (@oldtitlecommands,@newtitlecommands );
  my  %oldhash  = ();
  my  %newhash  = ();
  my ($line,$cmd,$optarg,$arg,$optargnew,$optargold,$optargdiff,$argold,$argnew,$argdiff,$auxline);

  # resuse context2cmdlist to define these commands to  look out for in preamble
  $titlecmd = "(?:".join("|",@CONTEXT2CMDLIST).")";
  # as context2cmdlist is stored as regex, e.g. ((?-xism:^title$), we need to remove ^- fo
  # resue in a more complex regex
  $titlecmd =~ s/[\$\^]//g; 
  # make sure to not match on comment lines:
  $titlecmdpat=qr/^(?:[^%\n]|\\%)*(\\($titlecmd)$extraspace(?:\[($brat0)\])?(?:\{($pat_n)\}))/ms;
  ###print STDERR "DEBUG:",$titlecmdpat,"\n";
  @oldtitlecommands= ( $$oldpreambleref =~ m/$titlecmdpat/g );
  @newtitlecommands= ( $$newpreambleref =~ m/$titlecmdpat/g );


  while ( @oldtitlecommands ) {
    $line=shift @oldtitlecommands;
    $cmd=shift @oldtitlecommands;
    $optarg=shift @oldtitlecommands;
    $arg=shift @oldtitlecommands;
  
    if ( defined($oldhash{$cmd})) {
      warn "$cmd is used twice in preamble of old file. Reverting to pure line diff mode for preamble.\n";
      return;
    }
    $oldhash{$cmd}=[ $line, $optarg, $arg ];
  }
  while ( @newtitlecommands ) {
    $line=shift @newtitlecommands;
    $cmd=shift @newtitlecommands;
    $optarg=shift @newtitlecommands;
    $arg=shift @newtitlecommands;
  
    if ( defined($newhash{$cmd})) {
      warn "$cmd is used twice in preamble of new file. Reverting to pure line diff mode for preamble.\n";
      return;
    }
    $newhash{$cmd}=[ $line, $optarg, $arg ];
  }
  foreach $cmd ( keys %newhash ) {
    if ( defined($newhash{$cmd}->[1])) {
       $optargnew=$newhash{$cmd}->[1];
    } else {
      $optargnew="";
    }
    if ( defined($oldhash{$cmd}->[1])) {
       $optargold=$oldhash{$cmd}->[1];
    } else {
      $optargold="";
    }

    if ( defined($oldhash{$cmd}->[2]) ) {
      $argold=$oldhash{$cmd}->[2];
    } else {
      $argold="";
    }
    $argnew=$newhash{$cmd}->[2];
    $argdiff="{" . join("",bodydiff($argold,$argnew)) ."}";
    if ( length $optargnew ) {
      $optargdiff="[".join("",bodydiff($optargold,$optargnew))."]" ;
      $optargdiff =~ s/\\DIFaddbegin /\\DIFaddbeginFL /g;
      $optargdiff =~ s/\\DIFaddend /\\DIFaddendFL /g;
      $optargdiff =~ s/\\DIFadd\{/\\DIFaddFL{/g;
      $optargdiff =~ s/\\DIFdelbegin /\\DIFdelbeginFL /g;
      $optargdiff =~ s/\\DIFdelend /\\DIFdelendFL /g;
      $optargdiff =~ s/\\DIFdel\{/\\DIFdelFL{/g;
    } else {
      $optargdiff="";
    }
    ### print STDERR "DEBUG s/\\Q$newhash{$cmd}->[0]\\E/\\$cmd$optargdiff$argdiff/s\n";
    # Note: \Q and \E force literal interpretation of what it between them but allow 
    #      variable interpolation, such that e.g. \title matches just that and not TAB-itle
    $$newpreambleref=~s/\Q$newhash{$cmd}->[0]\E/\\$cmd$optargdiff$argdiff/s;
    # replace this in old preamble if necessary
    if ( defined($oldhash{$cmd}->[0])) {
      $$oldpreambleref=~s/\Q$oldhash{$cmd}->[0]\E/\\$cmd$optargdiff$argdiff/s ;
    }
    ### print STDERR "DEBUG NEW PRE ".$$newpreambleref."\n";
  }

  foreach $cmd ( keys %oldhash ) {
    # if this has already been dealt with above can just skip
    next if defined($newhash{$cmd}) ;
    $argold=$oldhash{$cmd}->[2];
    $argdiff="{" . join("",bodydiff($argold,"")) ."}";
    if ( defined($oldhash{$cmd}->[1])) {
      $optargold=$oldhash{$cmd}->[1];
      $optargdiff="[".join("",bodydiff($optargold,""))."]" ;
      $optargdiff =~ s/\\DIFdelbegin /\\DIFdelbeginFL /g;
      $optargdiff =~ s/\\DIFdelend /\\DIFdelendFL /g;
      $optargdiff =~ s/\\DIFdel\{/\\DIFdelFL{/g;
    } else {
      $optargdiff="";
    }
    $auxline = "\\$cmd$optargdiff$argdiff";
    $auxline =~s/$/$AUXCMD/sg;
    push @auxlines,$auxline;
  }
  # add auxcmd comment to highlight added lines
  return(@auxlines);
}



# @diffs=linediff(\@seq1, \@seq2)
# mark up lines like this
#%DIF mm-mmdnn
#%< old deleted line(s)
#%DIF -------
#%DIF mmann-nn
#new appended line %< 
#%DIF -------
# Future extension: mark change explicitly
# Assumes: traverse_sequence traverses deletions before insertions in changed sequences
#          all line numbers relative to line 0 (first line of real file)
sub linediff {
  my $seq1 = shift ;
  my $seq2 = shift ;

  my $block = [];
  my $retseq = [];
  my @begin=('','',''); # dummy initialisation
  my $instring ; 

  my $discard = sub { @begin=('d',$_[0],$_[1]) unless scalar @$block ; 
                      push(@$block, "%DIF < " . $seq1->[$_[0]]) };
  my $add = sub { if (! scalar  @$block) {
		    @begin=('a',$_[0],$_[1]) ;}
		  elsif ( $begin[0] eq 'd' ) {
                    $begin[0]='c'; $begin[2]=$_[1];
		    push(@$block, "%DIF -------") }
                  push(@$block,  $seq2->[$_[1]] . " %DIF > " ) };
  my $match = sub { if ( scalar @$block ) {
                      if ( $begin[0] eq 'd' && $begin[1]!=$_[0]-1) {
			$instring = sprintf "%%DIF %d-%dd%d",$begin[1],$_[0]-1,$begin[2]; }
		      elsif ( $begin[0] eq 'a' && $begin[2]!=$_[1]-1) {
			$instring = sprintf "%%DIF %da%d-%d",$begin[1],$begin[2],$_[1]-1; }
		      elsif ( $begin[0] eq 'c' ) {
			$instring = sprintf "%%DIF %sc%s",
			                     ($begin[1]==$_[0]-1) ? "$begin[1]" : $begin[1]."-".($_[0]-1)  , 
			                     ($begin[2]==$_[1]-1) ? "$begin[2]" : $begin[2]."-".($_[1]-1)  ; }
		      else {
			$instring = sprintf "%%DIF %d%s%d",$begin[1],$begin[0],$begin[2]; }
		      push @$retseq, $instring,@$block, "%DIF -------" ; 
		      $block = []; 
		    }
		    push @$retseq, $seq2->[$_[1]]
		  };
  # key function: remove multiple spaces (such that insertion or deletion of redundant white space is not reported)
  my $keyfunc = sub { join("  ",split(" ",shift())) };

  traverse_sequences($seq1,$seq2, { MATCH=>$match, DISCARD_A=>$discard, DISCARD_B=>$add }, $keyfunc );
  push @$retseq, @$block if scalar @$block; 

  return wantarray ? @$retseq : $retseq ;
}



# init_regex_arr_data(\@array,"TOKEN INIT")
# scans DATA file handel for line "%% TOKEN INIT" line
# then appends each line not beginning with % into array (as a quoted regex)
# This is used for command lists and configuration variables, but the processing is slightly 
# different: 
# For lists, the regular expression is extended to include beginning (^) and end ($) markers, to require full-string matching
# For configuration variables (and all others), simply an unadorned list is copied
sub init_regex_arr_data {
  my ($arr,$token)=@_;
  my $copy=0;
  my ($mode);
  if ($token =~ m/COMMANDS/ ) { 
    $mode=0;
  } else {
    $mode=1;
  }

  while (<DATA>) {
    if ( m/^%%BEGIN $token\s*$/ ) {
      $copy=1; 
      next;
    } elsif ( m/^%%END $token\s*$/ )  {
      last; }
    chomp;
    if ( $mode==0 ) {
      push (@$arr,qr/^$_$/) if ( $copy && !/^%/ ) ;
    } elsif ($mode==1) {
      push (@$arr,"$_") if ( $copy && !/^%/ ) ;
    }
  }
  seek DATA,0,0;    # rewind DATA handle to file begin
}


# init_regex_arr_ext(\@array,$arg)
# appends array with regular expressions.
# if arg is a file name, then read in list of regular expressions from that file
# (one expression per line)
# Otherwise treat arg as a comma separated list of regular expressions
sub init_regex_arr_ext {
  my ($arr,$arg)=@_;
  if ( -f $arg ) {
    init_regex_arr_file($arr,$arg);
  } else {
    init_regex_arr_list($arr,$arg);
  }
}

# init_regex_arr_file(\@array,$fname)
# appends array with regular expressions.
# Read in list of regular expressions from $fname
# (one expression per line)
sub init_regex_arr_file {
  my ($arr,$fname)=@_;
  open(FILE,"$fname") or die ("Couldn't open $fname: $!");
  while (<FILE>) {
    chomp;
    next if /^\s*#/ || /^\s*%/ || /^\s*$/ ;
    push (@$arr,qr/^$_$/);
  }
  close(FILE);
}

# init_regex_arr_list(\@array,$arg)
# appends array with regular expressions.
# read from comma separated list of regular expressions ($arg)
sub init_regex_arr_list {
  my ($arr,$arg)=@_;
  my $regex;
  ###    print STDERR "DEBUG init_regex_arr_list arg >$arg<\n" if $debug;
  foreach $regex (split(qr/(?<!\\),/,$arg)) {
    $regex =~ s/\\,/,/g;
    push (@$arr,qr/^$regex$/);
  }
}


#exetime() returns time since last execution of this command
#exetime(1) resets this time
my $lasttime=-1;   # global variable for persistence
sub exetime {
  my $reset=0;
  my $retval;
  if ((scalar @_) >=1) {
    $reset=shift;
  }
  if ($reset) {
    $lasttime=times();
  }
  else {
    $retval=times()-$lasttime;
    $lasttime=$lasttime+$retval;
    return($retval);
  }
}


sub usage {
  die <<"EOF"; 
Usage: $0 [options] old.tex new.tex > diff.tex

Compares two latex files and writes tex code to stdout, which has the same
format as new.tex but has all changes relative to old.tex marked up or commented.

--type=markupstyle
-t markupstyle         Add code to preamble for selected markup style
                       Available styles: UNDERLINE CTRADITIONAL TRADITIONAL CFONT FONTSTRIKE INVISIBLE 
                                         CHANGEBAR CCHANGEBAR CULINECHBAR CFONTCBHBAR BOLD PDFCOMMENT
                       [ Default: UNDERLINE ]

--subtype=markstyle
-s markstyle           Add code to preamble for selected style for bracketing
                       commands (e.g. to mark changes in  margin)
                       Available styles: SAFE MARGIN DVIPSCOL COLOR ZLABEL ONLYCHANGEDPAGE (LABEL)*
                       [ Default: SAFE ]
                       * LABEL subtype is deprecated

--floattype=markstyle
-f markstyle           Add code to preamble for selected style which 
                       replace standard marking and markup commands within floats
                       (e.g., marginal remarks cause an error within floats
                       so marginal marking can be disabled thus)
                       Available styles: FLOATSAFE IDENTICAL
                       [ Default: FLOATSAFE ]

--encoding=enc
-e enc                 Specify encoding of old.tex and new.tex. Typical encodings are
                       ascii, utf8, latin1, latin9.  A list of available encodings can be 
                       obtained by executing 
                       perl -MEncode -e 'print join ("\\n",Encode->encodings( ":all" )) ;'
                       [Default encoding is utf8 unless the first few lines of the preamble contain
                       an invocation "\\usepackage[..]{inputenc} in which case the 
                       encoding chosen by this command is asssumed. Note that ASCII (standard
                       latex) is a subset of utf8]

--preamble=file
-p file                Insert file at end of preamble instead of auto-generating
                       preamble.  The preamble must define the following commands
                       \\DIFaddbegin,\\DIFaddend,\\DIFadd{..},
                       \\DIFdelbegin,\\DIFdelend,\\DIFdel{..},
                       and varieties for use within floats
                       \\DIFaddbeginFL,\\DIFaddendFL,\\DIFaddFL{..},
                       \\DIFdelbeginFL,\\DIFdelendFL,\\DIFdelFL{..}
                       (If this option is set -t, -s, and -f options
                       are ignored.)

--exclude-safecmd=exclude-file
--exclude-safecmd="cmd1,cmd2,..."
-A exclude-file 
--replace-safecmd=replace-file
--append-safecmd=append-file
--append-safecmd="cmd1,cmd2,..."
-a append-file         Exclude from, replace or append to the list of regex
                       matching commands which are safe to use within the 
                       scope of a \\DIFadd or \\DIFdel command.  The file must contain
                       one Perl-RegEx per line (Comment lines beginning with # or % are
                       ignored). A literal comma within the comma-separated list must be
                       escaped thus "\\,",   Note that the RegEx needs to match the whole of 
                       the token, i.e., /^regex\$/ is implied and that the initial
                       "\\" of the command is not included. The --exclude-safecmd
                       and --append-safecmd options can be combined with the --replace-safecmd 
                       option and can be used repeatedly to add cumulatively to the lists.

--exclude-textcmd=exclude-file 
--exclude-textcmd="cmd1,cmd2,..."
-X exclude-file
--replace-textcmd=replace-file
--append-textcmd=append-file
--append-textcmd="cmd1,cmd2,..."
-x append-file         Exclude from, replace or append to the list of regex
                       matching commands whose last argument is text.  See
                       entry for --exclude-safecmd directly above for further details.

--replace-context1cmd=replace-file
--append-context1cmd=append-file
--append-context1cmd="cmd1,cmd2,..."
                       Replace or append to the list of regex matching commands
                       whose last argument is text but which require a particular
                       context to work, e.g. \\caption will only work within a figure
                       or table.  These commands behave like text commands, except when 
                       they occur in a deleted section, when they are disabled, but their
                       argument is shown as deleted text.

--replace-context2cmd=replace-file
--append-context2cmd=append-file
--append-context2cmd="cmd1,cmd2,..."
                       As corresponding commands for context1.  The only difference is that
                       context2 commands are completely disabled in deleted sections, including
                       their arguments.

--exclude-mboxsafecmd=exclude-file
--exclude-mboxsafecmd="cmd1,cmd2,..."
--append-mboxsafecmd=append-file
--append-mboxsafecmd="cmd1,cmd2,..."
                       Define safe commands, which additionally need to be protected by encapsulating
                       in an \\mbox{..}. This is sometimes needed to get around incompatibilities 
                       between external packages and the ulem package, which is  used for highlighting
                       in the default style UNDERLINE as well as CULINECHBAR CFONTSTRIKE
                       


--config var1=val1,var2=val2,...
-c var1=val1,..        Set configuration variables.
-c configfile           Available variables: 
                          ARRENV (RegEx)
                          COUNTERCMD (RegEx)
                          FLOATENV (RegEx)
                          ITEMCMD (RegEx)
                          LISTENV (RegEx)
                          MATHARRENV (RegEx)
                          MATHARRREPL (String)
                          MATHENV (RegEx)
                          MATHREPL (String)
                          MINWORDSBLOCK (Integer)
                          PICTUREENV (RegEx)
                          SCALEDELGRAPHICS (Float)
                       This option can be repeated.

--add-to-config  varenv1=pattern1,varenv2=pattern2
                       For configuration variables containing a regular expression (essentially those ending
                       in ENV, and COUNTERCMD) this provides an alternative way to modify the configuration 
                       variables. Instead of setting the complete pattern, with this option it is possible to add an
                       alternative pattern. varenv must be one of the variables listed above that take a regular
                       expression as argument, and pattern is any regular expression (which might need to be 
                       protected from the shell by quotation). Several patterns can be added at once by using semi-colons
                       to separate them, e.g. --add-to-config "LISTENV=myitemize;myenumerate,COUNTERCMD=endnote"

--packages=pkg1,pkg2,..
                       Tell latexdiff that .tex file is processed with the packages in list 
                       loaded.  This is normally not necessary if the .tex file includes the
                       preamble, as the preamble is automatically scanned for \\usepackage commands.
                       Use of the --packages option disables automatic scanning, so if for any
                       reason package specific parsing needs to be switched off, use --packages=none.
                       The following packages trigger special behaviour:
                       endfloat hyperref amsmath apacite siunitx cleveref glossaries mhchem chemformula/chemmacros
                       [ Default: scan the preamble for \\usepackage commands to determine
                         loaded packages.]

--show-preamble        Print generated or included preamble commands to stdout.

--show-safecmd         Print list of regex matching and excluding safe commands.

--show-textcmd         Print list of regex matching and excluding commands with text argument.

--show-config          Show values of configuration variables

--show-all             Show all of the above

   NB For all --show commands, no old.tex or new.tex file needs to be given, and no 
      differencing takes place.

Other configuration options:

--allow-spaces         Allow spaces between bracketed or braced arguments to commands
                       [Default requires arguments to directly follow each other without 
                                intervening spaces]

--math-markup=level    Determine granularity of markup in displayed math environments:
                      Possible values for level are (both numerical and text labels are acceptable):
                      off or 0: suppress markup for math environments.  Deleted equations will not 
                               appear in diff file. This mode can be used if all the other modes 
                               cause invalid latex code.
                      whole or 1: Differencing on the level of whole equations. Even trivial changes
                               to equations cause the whole equation to be marked changed.  This 
                               mode can be used if processing in coarse or fine mode results in 
                               invalid latex code.
                      coarse or 2: Detect changes within equations marked up with a coarse
                               granularity; changes in equation type (e.g.displaymath to equation) 
                               appear as a change to the complete equation. This mode is recommended
                               for situations where the content and order of some equations are still
                               being changed. [Default]
                      fine or 3: Detect small change in equations and mark up and fine granularity.
                               This mode is most suitable, if only minor changes to equations are
                               expected, e.g. correction of typos. 

--graphics-markup=level   Change highlight style for graphics embedded with \\includegraphics commands
                      Possible values for level:
                      none,off or 0: no highlighting for figures
                      new-only or 1: surround newly added or changed figures with a blue frame [Default]
                      both or 2:     highlight new figures with a blue frame and show deleted figures 
                                at reduced scale, and crossed out with a red diagonal cross. Use configuration
                                variable SCALEDELGRAPHICS to set size of deleted figures.
                      Note that changes to the optional parameters will make the figure appear as changed 
                      to latexdiff, and this figure will thus be highlighted.

--disable-citation-markup 
--disable-auto-mbox    Suppress citation markup and markup of other vulnerable commands in styles 
                       using ulem (UNDERLINE,FONTSTRIKE, CULINECHBAR)
                       (the two options are identical and are simply aliases)

--enable-citation-markup
--enforce-auto-mbox    Protect citation commands and other vulnerable commands in changed sections 
                       with \\mbox command, i.e. use default behaviour for ulem package for other packages
                       (the two options are identical and are simply aliases)

Miscelleneous options

--label=label
-L label               Sets the labels used to describe the old and new files.  The first use
                       of this option sets the label describing the old file and the second
                       use of the option sets the label for the new file.
                       [Default: use the filename and modification dates for the label]

--no-label             Suppress inclusion of old and new file names as comment in output file

--visible-label         Include old and new filenames (or labels set with --label option) as 
                       visible output

--flatten              Replace \\input and \\include commands within body by the content
                       of the files in their argument.  If \\includeonly is present in the
                       preamble, only those files are expanded into the document. However, 
                       no recursion is done, i.e. \\input and \\include commands within 
                       included sections are not expanded.  The included files are assumed to 
                       be located in the same directories as the old and new master files,
                       respectively, making it possible to organise files into old and new directories.
                       --flatten is applied recursively, so inputted files can contain further
                       \\input statements.

--help
-h                     Show this help text.

--ignore-warnings      Suppress warnings about inconsistencies in length between input
                       and parsed strings and missing characters. 

--verbose
-V                     Output various status information to stderr during processing.
                       Default is to work silently.

--version              Show version number.

EOF
}

=head1 NAME

latexdiff - determine and markup differences between two latex files

=head1 SYNOPSIS

B<latexdiff> [ B<OPTIONS> ] F<old.tex> F<new.tex> > F<diff.tex>

=head1 DESCRIPTION

Briefly, I<latexdiff> is a utility program to aid in the management of
revisions of latex documents. It compares two valid latex files, here
called C<old.tex> and C<new.tex>, finds significant differences
between them (i.e., ignoring the number of white spaces and position
of line breaks), and adds special commands to highlight the
differences.  Where visual highlighting is not possible, e.g. for changes
in the formatting, the differences are
nevertheless marked up in the source.

The program treats the preamble differently from the main document.
Differences between the preambles are found using line-based
differencing (similarly to the Unix diff command, but ignoring white
spaces).  A comment, "S<C<%DIF E<gt>>>" is appended to each added line, i.e. a 
line present in C<new.tex> but not in C<old.tex>.  Discarded lines 
 are deactivated by prepending "S<C<%DIF E<lt>>>". Changed blocks are preceded  by
comment lines giving information about line numbers in the original files.  Where there are insignificant
differences, the resulting file C<diff.tex> will be similar to
C<new.tex>.  At the end of the preamble, the definitions for I<latexdiff> markup commands are inserted.
In differencing the main body of the text, I<latexdiff> attempts to
satisfy the following guidelines (in order of priority):

=over 3

=item 1

If both C<old.tex> and C<new.tex> are valid LaTeX, then the resulting
C<diff.tex> should also be valid LateX. (NB If a few plain TeX commands
are used within C<old.tex> or C<new.tex> then C<diff.tex> is not
guaranteed to work but usually will).

=item 2

Significant differences are determined on the level of
individual words. All significant differences, including differences
between comments should be clearly marked in the resulting source code
C<diff.tex>.

=item 3

If a changed passage contains text or text-producing commands, then
running C<diff.tex> through LateX should produce output where added
and discarded passages are highlighted.

=item 4

Where there are insignificant differences, e.g. in the positioning of
line breaks, C<diff.tex> should follow the formatting of C<new.tex>

=back

For differencing the same algorithm as I<diff> is used but words
instead of lines are compared.  An attempt is made to recognize
blocks which are completely changed such that they can be marked up as a unit.
Comments are differenced line by line
but the number of spaces within comments is ignored. Commands including
all their arguments are generally compared as one unit, i.e., no mark-up
is inserted into the arguments of commands.  However, for a selected
number of commands (for example, C<\caption> and all sectioning
commands) the last argument is known to be text. This text is
split into words and differenced just as ordinary text (use options to
show and change the list of text commands, see below). As the
algorithm has no detailed knowledge of LaTeX, it assumes all pairs of
curly braces immediately following a command (i.e. a sequence of
letters beginning with a backslash) are arguments for that command.
As a restriction to condition 1 above it is thus necessary to surround
all arguments with curly braces, and to not insert
extraneous spaces.  For example, write 

  \section{\textem{This is an emphasized section title}}

and not

  \section {\textem{This is an emphasized section title}}

or

  \section\textem{This is an emphasized section title}

even though all varieties are the same to LaTeX (but see
B<--allow-spaces> option which allows the second variety).

For environments whose content does not conform to standard LaTeX or
where graphical markup does not make sense all markup commands can be
removed by setting the PICTUREENV configuration variable, set by
default to C<picture> and C<DIFnomarkup> environments; see B<--config>
option).  The latter environment (C<DIFnomarkup>) can be used to
protect parts of the latex file where the markup results in illegal
markup. You have to surround the offending passage in both the old and
new file by C<\begin{DIFnomarkup}> and C<\end{DIFnomarkup}>. You must
define the environment in the preambles of both old and new
documents. I prefer to define it as a null-environment,

C<\newenvironment{DIFnomarkup}{}{}>

but the choice is yours.  Any markup within the environment will be
removed, and generally everything within the environment will just be
taken from the new file.

It is also possible to difference files which do not have a preamble. 
 In this case, the file is processed in the main document
mode, but the definitions of the markup commands are not inserted.

All markup commands inserted by I<latexdiff> begin with "C<\DIF>".  Added
blocks containing words, commands or comments which are in C<new.tex>
but not in C<old.tex> are marked by C<\DIFaddbegin> and C<\DIFaddend>.
Discarded blocks are marked by C<\DIFdelbegin> and C<\DIFdelend>.
Within added blocks all text is highlighted with C<\DIFadd> like this:
C<\DIFadd{Added text block}>
Selected `safe' commands can be contained in these text blocks as well
(use options to show and change the list of safe commands, see below).
All other commands as well as braces "{" and "}" are never put within
the scope of C<\DIFadd>.  Added comments are marked by prepending
"S<C<%DIF E<gt> >>".

Within deleted blocks text is highlighted with C<\DIFdel>.  Deleted
comments are marked by prepending "S<C<%DIF E<lt> >>".  Non-safe command
and curly braces within deleted blocks are commented out with 
"S<C<%DIFDELCMD E<lt> >>".



=head1 OPTIONS

=head2 Preamble

The following options determine the visual markup style by adding the appropriate
command definitions to the preamble. See the end of this section for a description of 
available styles.

=over 4

=item B<--type=markupstyle> or
B<-t markupstyle>

Add code to preamble for selected markup style. This option defines
C<\DIFadd> and C<\DIFdel> commands.
Available styles: 

C<UNDERLINE CTRADITIONAL TRADITIONAL CFONT FONTSTRIKE INVISIBLE 
CHANGEBAR CCHANGEBAR CULINECHBAR CFONTCBHBAR BOLD PDFCOMMENT>

[ Default: C<UNDERLINE> ]

=item B<--subtype=markstyle> or
B<-s markstyle> 

Add code to preamble for selected style for bracketing
commands (e.g. to mark changes in  margin). This option defines
C<\DIFaddbegin>, C<\DIFaddend>, C<\DIFdelbegin> and C<\DIFdelend> commands.
Available styles: C<SAFE MARGIN COLOR DVIPSCOL  ZLABEL ONLYCHANGEDPAGE (LABEL)*>

[ Default: C<SAFE> ]
* Subtype C<LABEL> is deprecated

=item B<--floattype=markstyle> or
B<-f markstyle>

Add code to preamble for selected style which 
replace standard marking and markup commands within floats
(e.g., marginal remarks cause an error within floats
so marginal marking can be disabled thus). This option defines all 
C<\DIF...FL> commands.
Available styles: C<FLOATSAFE TRADITIONALSAFE IDENTICAL>

[ Default: C<FLOATSAFE> ]

=item B<--encoding=enc> or 
B<-e enc>

Specify encoding of old.tex and new.tex. Typical encodings are
C<ascii>, C<utf8>, C<latin1>, C<latin9>.  A list of available encodings can be 
obtained by executing 

C<perl -MEncode -e 'print join ("\n",Encode->encodings( ":all" )) ;' >

[Default encoding is utf8 unless the first few lines of the preamble contain
an invocation C<\usepackage[..]{inputenc}> in which case the 
encoding chosen by this command is asssumed. Note that ASCII (standard
latex) is a subset of utf8]

=item B<--preamble=file> or
B<-p file>

Insert file at end of preamble instead of generating
preamble.  The preamble must define the following commands
C<\DIFaddbegin, \DIFaddend, \DIFadd{..},
\DIFdelbegin,\DIFdelend,\DIFdel{..},>
and varieties for use within floats
C<\DIFaddbeginFL, \DIFaddendFL, \DIFaddFL{..},
\DIFdelbeginFL, \DIFdelendFL, \DIFdelFL{..}>
(If this option is set B<-t>, B<-s>, and B<-f> options
are ignored.)

=item B<--packages=pkg1,pkg2,..> 

Tell latexdiff that .tex file is processed with the packages in list
loaded.  This is normally not necessary if the .tex file includes the
preamble, as the preamble is automatically scanned for C<\usepackage> commands.
Use of the B<--packages> option disables automatic scanning, so if for any
reason package specific parsing needs to be switched off, use B<--packages=none>.
The following packages trigger special behaviour:

=over 8

=item C<amsmath> 

Configuration variable MATHARRREPL is set to C<align*> (Default: C<eqnarray*>). (Note that many of the 
amsmath array environments are already recognised by default as such)

=item C<endfloat> 

Ensure that C<\begin{figure}> and C<\end{figure}> always appear by themselves on a line.

=item C<hyperref>

Change name of C<\DIFadd> and C<\DIFdel> commands to C<\DIFaddtex> and C<\DIFdeltex> and 
define new C<\DIFadd> and C<\DIFdel> commands, which provide a wrapper for these commands,
using them for the text but not for the link defining command (where any markup would cause
errors).

=item C<apacite>

Redefine the commands recognised as citation commands.

=item C<siunitx>

Treat C<\SI> as equivalent to citation commands (i.e. protect with C<\mbox> if markup style uses ulem package.

=item C<cleveref>

Treat C<\cref,\Cref>, etc as equivalent to citation commands (i.e. protect with C<\mbox> if markup style uses ulem package.

=item C<glossaries>

Define most of the glossaries commands as safe, protecting them with \mbox'es where needed

=item C<mhchem>

Treat C<\ce> as a safe command, i.e. it will be highlighted (note that C<\cee> will not be highlighted in equations as this leads to processing errors)

=item C<chemformula> or C<chemmacros>

Treat C<\ch> as a safe command outside equations, i.e. it will be highlighted (note that C<\ch> will not be highlighted in equations as this leads to processing errors)


=back

[ Default: scan the preamble for C<\usepackage> commands to determine
  loaded packages. ]



=item B<--show-preamble>

Print generated or included preamble commands to stdout.

=back

=head2 Configuration

=over 4

=item B<--exclude-safecmd=exclude-file> or
B<-A exclude-file> or  B<--exclude-safecmd="cmd1,cmd2,...">

=item B<--replace-safecmd=replace-file>

=item B<--append-safecmd=append-file> or 
B<-a append-file> or B<--append-safecmd="cmd1,cmd2,...">

Exclude from, replace or append to the list of regular expressions (RegEx)
matching commands which are safe to use within the 
scope of a C<\DIFadd> or C<\DIFdel> command.  The file must contain
one Perl-RegEx per line (Comment lines beginning with # or % are
ignored).  Note that the RegEx needs to match the whole of 
the token, i.e., /^regex$/ is implied and that the initial
"\" of the command is not included. 
The B<--exclude-safecmd> and B<--append-safecmd> options can be combined with the -B<--replace-safecmd> 
option and can be used repeatedly to add cumulatively to the lists.
 B<--exclude-safecmd>
and B<--append-safecmd> can also take a comma separated list as input. If a
comma for one of the regex is required, escape it thus "\,". In most cases it
will be necessary to protect the comma-separated list from the shell by putting
it in quotation marks.

=item B<--exclude-textcmd=exclude-file> or
B<-X exclude-file> or B<--exclude-textcmd="cmd1,cmd2,...">

=item B<--replace-textcmd=replace-file>

=item B<--append-textcmd=append-file> or 
B<-x append-file> or B<--append-textcmd="cmd1,cmd2,...">

Exclude from, replace or append to the list of regular expressions
matching commands whose last argument is text.  See
entry for B<--exclude-safecmd> directly above for further details.


=item B<--replace-context1cmd=replace-file> 

=item B<--append-context1cmd=append-file> or

=item B<--append-context1cmd="cmd1,cmd2,...">

Replace or append to the list of regex matching commands
whose last argument is text but which require a particular
context to work, e.g. C<\caption> will only work within a figure
or table.  These commands behave like text commands, except when 
they occur in a deleted section, when they are disabled, but their
argument is shown as deleted text.

=item B<--replace-context2cmd=replace-file> 

=item B<--append-context2cmd=append-file> or

=item B<--append-context2cmd="cmd1,cmd2,...">

As corresponding commands for context1.  The only difference is that
context2 commands are completely disabled in deleted sections, including
their arguments.


=item B<--exclude-mboxsafecmd=exclude-file> or B<--exclude-mboxsafecmd="cmd1,cmd2,...">

=item B<--append-mboxsafecmd=append-file> or B<--append-mboxsafecmd="cmd1,cmd2,...">

Define safe commands, which additionally need to be protected by encapsulating
in an C<\mbox{..}>. This is sometimes needed to get around incompatibilities 
between external packages and the ulem package, which is  used for highlighting
in the default style UNDERLINE as well as CULINECHBAR CFONTSTRIKE





=item B<--config var1=val1,var2=val2,...> or B<-c var1=val1,..>

=item B<-c configfile>

Set configuration variables.  The option can be repeated to set different
variables (as an alternative to the comma-separated list).
Available variables (see below for further explanations): 

C<ARRENV> (RegEx)

C<COUNTERCMD> (RegEx)

C<FLOATENV> (RegEx)

C<ITEMCMD> (RegEx)

C<LISTENV>  (RegEx)

C<MATHARRENV> (RegEx)

C<MATHARRREPL> (String)

C<MATHENV> (RegEx)

C<MATHREPL> (String)

C<MINWORDSBLOCK> (Integer)

C<PICTUREENV> (RegEx)

C<SCALEDELGRAPHICS> (Float)

=item B<--add-to-config varenv1=pattern1,varenv2=pattern2,...>

For configuration variables, which are a regular expression (essentially those ending
in ENV, and COUNTERCMD, see list above) this provides an alternative way to modify the configuration 
variables. Instead of setting the complete pattern, with this option it is possible to add an
alternative pattern. C<varenv> must be one of the variables listed above that take a regular
expression as argument, and pattern is any regular expression (which might need to be 
protected from the shell by quotation). Several patterns can be added at once by using semi-colons
to separate them, e.g. C<--add-to-config "LISTENV=myitemize;myenumerate,COUNTERCMD=endnote">

=item B<--show-safecmd>

Print list of RegEx matching and excluding safe commands.

=item B<--show-textcmd>

Print list of RegEx matching and excluding commands with text argument.

=item B<--show-config>

Show values of configuration variables.

=item B<--show-all>

Combine all --show commands.

NB For all --show commands, no C<old.tex> or C<new.tex> file needs to be specified, and no 
differencing takes place.

=back

=head2 Other configuration options:

=over 4

=item B<--allow-spaces>

Allow spaces between bracketed or braced arguments to commands.  Note
that this option might have undesirable side effects (unrelated scope
might get lumpeded with preceding commands) so should only be used if the
default produces erroneous results.  (Default requires arguments to
directly follow each other without intervening spaces).

=item B<--math-markup=level>   

Determine granularity of markup in displayed math environments:               
Possible values for level are (both numerical and text labels are acceptable):

C<off> or C<0>: suppress markup for math environments.  Deleted equations will not 
appear in diff file. This mode can be used if all the other modes 
cause invalid latex code.

C<whole> or C<1>: Differencing on the level of whole equations. Even trivial changes
to equations cause the whole equation to be marked changed.  This 
mode can be used if processing in coarse or fine mode results in 
invalid latex code.

C<coarse> or C<2>: Detect changes within equations marked up with a coarse
granularity; changes in equation type (e.g.displaymath to equation) 
appear as a change to the complete equation. This mode is recommended
for situations where the content and order of some equations are still
being changed. [Default]

C<fine> or C<3>: Detect small change in equations and mark up at fine granularity.
This mode is most suitable, if only minor changes to equations are
expected, e.g. correction of typos. 

=item B<--graphics-markup=level>

 Change highlight style for graphics embedded with C<\includegraphics> commands.

Possible values for level:

C<none>, C<off> or C<0>: no highlighting for figures

C<new-only> or C<1>: surround newly added or changed figures with a blue frame [Default if graphicx package loaded]

C<both> or C<2>:     highlight new figures with a blue frame and show deleted figures at reduced 
scale, and crossed out with a red diagonal cross. Use configuration
variable SCALEDELGRAPHICS to set size of deleted figures.

Note that changes to the optional parameters will make the figure appear as changed 
to latexdiff, and this figure will thus be highlighted

=item B<--disable-citation-markup> or B<--disable-auto-mbox>

Suppress citation markup and markup of other vulnerable commands in styles 
using ulem (UNDERLINE,FONTSTRIKE, CULINECHBAR)
(the two options are identical and are simply aliases)

=item B<--enable-citation-markup> or B<--enforce-auto-mbox>

Protect citation commands and other vulnerable commands in changed sections 
with C<\mbox> command, i.e. use default behaviour for ulem package for other packages
(the two options are identical and are simply aliases)

=back

=head2 Miscellaneous

=over 4

=item B<--verbose> or B<-V>

Output various status information to stderr during processing.
Default is to work silently.

=item B<--driver=type>

Choose driver for changebar package (only relevant for styles using
   changebar: CCHANGEBAR CFONTCHBAR CULINECHBAR CHANGEBAR). Possible
drivers are listed in changebar manual, e.g. pdftex,dvips,dvitops
  [Default: dvips]

=item B<--ignore-warnings>

Suppress warnings about inconsistencies in length between input and
parsed strings and missing characters.  These warning messages are
often related to non-standard latex or latex constructions with a
syntax unknown to C<latexdiff> but the resulting difference argument
is often fully functional anyway, particularly if the non-standard
latex only occurs in parts of the text which have not changed.

=item B<--label=label> or
B<-L label>

Sets the labels used to describe the old and new files.  The first use
of this option sets the label describing the old file and the second
use of the option sets the label for the new file, i.e. set both
labels like this C<-L labelold -L labelnew>.
[Default: use the filename and modification dates for the label]

=item B<--no-label>

Suppress inclusion of old and new file names as comment in output file

=item B<--visible-label>

Include old and new filenames (or labels set with C<--label> option) as 
visible output.

=item B<--flatten>

Replace C<\input> and C<\include> commands within body by the content
of the files in their argument.  If C<\includeonly> is present in the
preamble, only those files are expanded into the document. However, 
no recursion is done, i.e. C<\input> and C<\include> commands within 
included sections are not expanded.  The included files are assumed to 
 be located in the same directories as the old and new master files,
respectively, making it possible to organise files into old and new directories. 
--flatten is applied recursively, so inputted files can contain further
C<\input> statements.

Use of this option might result in prohibitive processing times for
larger documents, and the resulting difference document
no longer reflects the structure of the input documents.

=item B<--help> or
B<-h>

Show help text

=item B<--version>

Show version number

=back



=head2 Predefined styles 

=head2 Major types

The major type determine the markup of plain text and some selected latex commands outside floats by defining the markup commands C<\DIFadd{...}> and C<\DIFdel{...}> .

=over 10

=item C<UNDERLINE>

Added text is wavy-underlined and blue, discarded text is struck out and red
(Requires color and ulem packages).  Overstriking does not work in displayed math equations such that deleted parts of equation are underlined, not struck out (this is a shortcoming inherent to the ulem package).

=item C<CTRADITIONAL>

Added text is blue and set in sans-serif, and a red footnote is created for each discarded 
piece of text. (Requires color package)

=item C<TRADITIONAL>

Like C<CTRADITIONAL> but without the use of color.

=item C<CFONT>

Added text is blue and set in sans-serif, and discarded text is red and very small size.

=item C<FONTSTRIKE>

Added tex is set in sans-serif, discarded text small and struck out

=item C<CCHANGEBAR>

Added text is blue, and discarded text is red.  Additionally, the changed text is marked with a bar in the margin (Requires color and changebar packages).

=item C<CFONTCHBAR>

Like C<CFONT> but with additional changebars (Requires color and changebar packages).

=item C<CULINECHBAR>

Like C<UNDERLINE> but with additional changebars (Requires color, ulem and changebar packages).

=item C<CHANGEBAR>

No mark up of text, but mark margins with changebars (Requires changebar package).

=item C<INVISIBLE>

No visible markup (but generic markup commands will still be inserted.

=item C<BOLD>

Added text is set in bold face, discarded is not shown.

=item C<PDFCOMMENT>

The pdfcomment package is used to underline new text, and mark deletions with a PDF comment. Note that this markup might appear differently or not at all based on the pdf viewer used. The viewer with best support for pdf markup is probably acroread. This style is only recommended if the number of differences is small. 

=back

=head2 Subtypes

The subtype defines the commands that are inserted at the begin and end of added or discarded blocks, irrespectively of whether these blocks contain text or commands (Defined commands: C<\DIFaddbegin, \DIFaddend, \DIFdelbegin, \DIFdelend>) 

=over 10

=item C<SAFE>

No additional markup (Recommended choice)

=item C<MARGIN>

Mark beginning and end of changed blocks with symbols in the margin nearby (using
the standard C<\marginpar> command - note that this sometimes moves somewhat
from the intended position.

=item C<COLOR>

An alternative way of marking added passages in blue, and deleted ones in red.
(It is recommeneded to use instead the main types to effect colored markup,
although in some cases coloring with dvipscol can be more complete, for example 
with citation commands).

=item C<DVIPSCOL>

An alternative way of marking added passages in blue, and deleted ones in red. Note
that C<DVIPSCOL> only works with the dvips converter, e.g. not pdflatex.
(it is recommeneded to use instead the main types to effect colored markup,
although in some cases coloring with dvipscol can be more complete).


=item C<ZLABEL>

can be used to highlight only changed pages, but requires post-processing. It is recommend to not call this option manually but use C<latexdiff-vc> with C<--only-changes> option. Alternatively, use the script given within preamble of diff files made using this style.

=item C<ONLYCHANGEDPAGE> 

also highlights changed pages, without the need for post-processing, but might not work reliably if
there is floating material (figures, tables).

=item C<LABEL> 

is similar to C<ZLABEL>, but does not need the zref package and works less reliably (deprecated).

=back

=head2 Float Types

Some of the markup used in the main text might cause problems when used within 
floats (e.g. figures or tables).  For this reason alternative versions of all
markup commands are used within floats. The float type defines these alternative commands.

=over 10

=item C<FLOATSAFE>

Use identical markup for text as in the main body, but set all commands marking the begin and end of changed blocks to null-commands.  You have to choose this float type if your subtype is C<MARGIN> as C<\marginpar> does not work properly within floats.

=item C<TRADITIONALSAFE>

Mark additions the same way as in the main text.  Deleted environments are marked by angular brackets \[ and \] and the deleted text is set in scriptscript size. This float type should always be used with the C<TRADITIONAL> and  C<CTRADITIONAL> markup types as the \footnote command does not work properly in floating environments.

=item C<IDENTICAL>

Make no difference between the main text and floats.

=back


=head2 Configuration Variables

=over 10

=item C<ARRENV>

If a match to C<ARRENV> is found within an inline math environment within a deleted or added block, then the inlined math 
is surrounded by C<\mbox{>...C<}>.  This is necessary as underlining does not work within inlined array environments.

[ Default: C<ARRENV>=S<C<(?:array|[pbvBV]matrix)> >

=item C<COUNTERCMD>

If a command in a deleted block which is also in the textcmd list matches C<COUNTERCMD> then an
additional command C<\addtocounter{>F<cntcmd>C<}{-1}>, where F<cntcmd> is the matching command, is appended in the diff file such that the numbering in the diff file remains synchronized with the
numbering in the new file.

[ Default: C<COUNTERCMD>=C<(?:footnote|part|section|subsection> ...

C<|subsubsection|paragraph|subparagraph)>  ]

=item C<FLOATENV>

Environments whose name matches the regular expression in C<FLOATENV> are 
considered floats.  Within these environments, the I<latexdiff> markup commands
are replaced by their FL variaties.

[ Default: S<C<(?:figure|table|plate)[\w\d*@]*> >]

=item C<ITEMCMD>

Commands representing new item line with list environments.

[ Default: \C<item> ]

=item C<LISTENV>

Environments whose name matches the regular expression in C<LISTENV> are list environments.

[ Default: S<C<(?:itemize|enumerate|description)> >]

=item C<MATHENV>,C<MATHREPL>

If both \begin and \end for a math environment (environment name matching C<MATHENV> or \[ and \])
are within the same deleted block, they are replaced by a \begin and \end commands for C<MATHREPL>
rather than being commented out.

[ Default: C<MATHENV>=S<C<(?:displaymath|equation)> >, C<MATHREPL>=S<C<displaymath> >]

=item C<MATHARRENV>,C<MATHARRREPL>

as C<MATHENV>,C<MATHREPL> but for equation arrays

[ Default: C<MATHARRENV>=S<C<eqnarray\*?> >, C<MATHREPL>=S<C<eqnarray> >]

=item C<MINWORDSBLOCK>

Minimum number of tokens required to form an independent block. This value is
used in the algorithm to detect changes of complete blocks by merging identical text parts of less than C<MINWORDSBLOCK> to the preceding added and discarded parts.

[ Default: 3 ]

=item C<PICTUREENV>

Within environments whose name matches the regular expression in C<PICTUREENV>
all latexdiff markup is removed (in pathologic cases this might lead to
inconsistent markup but this situation should be rare).

[ Default: S<C<(?:picture|DIFnomarkup)[\w\d*@]*> >]

=item C<SCALEDELGRAPHICS>

If C<--graphics-markup=both> is chosen, C<SCALEDELGRAPHICS> is the factor, by which deleted figures will be scaled (i.e. 0.5 implies they are shown at half linear size).

[ Default: 0.5 ]

=back

=head1 COMMON PROBLEMS AND FAQ

=over 10

=item Citations result in overfull boxes

There is an incompatibility between the C<ulem> package, which C<latexdiff> uses for underlining and striking out in the UNDERLINE style,
the default style, and the way citations are generated. In order to be able to mark up citations properly, they are enclosed with an C<\mbox> 
command. As mboxes cannot be broken across lines, this procedure frequently results in overfull boxes, possibly obscuring the content as it extends beyond the right margin.  The same occurs for some other packages (e.g., siunitx). If this is a problem, you have two possibilities.

1. Use C<CFONT> type markup (option C<-t CFONT>): If this markup is chosen, then changed citations are no longer marked up
with the wavy line (additions) or struck out (deletions), but are still highlighted in the appropriate color, and deleted text is shown with a different font. Other styles not using the C<ulem> package will also work. 

2. Choose option C<--disable-citation-markup> which turns off the marking up of citations: deleted citations are no longer shown, and
added citations are shown without markup. (This was the default behaviour of latexdiff at versions 0.6 and older)

For custom packages you can define the commands which need to be protected by C<\mbox> with C<--append-mboxsafecmd> and C<--excludemboxsafecmd> options
(submit your lists of command as feature request at github page to set the default behaviour of future versions, see section 6)

=item Changes in complicated mathematical equations result in latex processing errors

Try options C<--math-markup=whole>.   If even that fails, you can turn off mark up for equations with C<--math-markup=off>.

=item How can I just show the pages where changes had been made

Use options -C<-s ZLABEL>  (some postprocessing required) or C<-s ONLYCHANGEDPAGE>. C<latexdiff-vc --ps|--pdf> with C<--only-changes> option takes care of
the post-processing for you (requires zref package to be installed).

=back

=head1 BUGS

=over 10

=item Option allow-spaces not implemented entirely consistently. It breaks
the rules that number and type of white space does not matter, as
different numbers of inter-argument spaces are treated as significant.

=back

Please submit bug reports using the issue tracker of the github repository page I<https://github.com/ftilmann/latexdiff.git>, 
or send them to I<tilmann -- AT -- gfz-potsdam.de>.  Include the version number of I<latexdiff>
(from comments at the top of the source or use B<--version>).  If you come across latex
files that are error-free and conform to the specifications set out
above, and whose differencing still does not result in error-free
latex, please send me those files, ideally edited to only contain the
offending passage as long as that still reproduces the problem. If your 
file relies on non-standard class files, you must include those.  I will not
look at examples where I have trouble to latex the original files.

=head1 SEE ALSO

L<latexrevise>, L<latexdiff-vc>

=head1 PORTABILITY

I<latexdiff> does not make use of external commands and thus should run
on any platform  supporting Perl 5.6 or higher.  If files with encodings 
other than ASCII or UTF-8 are processed, Perl 5.8 or higher is required.

The standard version of I<latexdiff> requires installation of the Perl package
C<Algorithm::Diff> (available from I<www.cpan.org> - 
I<http://search.cpan.org/~nedkonz/Algorithm-Diff-1.15>) but a stand-alone
version, I<latexdiff-so>, which has this package inlined, is available, too.
I<latexdiff-fast> requires the I<diff> command to be present.

=head1 AUTHOR

Version 1.2.1
Copyright (C) 2004-2017 Frederik Tilmann

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License Version 3

Contributors of fixes and additions: V. Kuhlmann, J. Paisley, N. Becker, T. Doerges, K. Huebner, 
T. Connors, Sebastian Gouezel and many others.
Thanks to the many people who sent in bug reports, feature suggestions, and other feedback.

=cut

__END__
%%BEGIN SAFE COMMANDS
% Regex matching commands which can safely be in the
% argument of a \DIFadd or \DIFdel command (leave out the \)
arabic
dashbox
emph
fbox
framebox
hspace\*?
math.*
makebox
mbox
pageref
ref
symbol
raisebox
rule
text.*
shortstack
usebox
dag
ddag
copyright
pounds
S
P
oe
OE
ae
AE
aa
AA
o
O
l
L
frac
ss
sqrt
ldots
cdots
vdots
ddots
alpha
beta
gamma
delta
epsilon
varepsilon
zeta
eta
theta
vartheta
iota
kappa
lambda
mu
nu
xi
pi
varpi
rho
varrho
sigma
varsigma
tau
upsilon
phi
varphi
chi
psi
omega
Gamma
Delta
Theta
Lambda
Xi
Pi
Sigma
Upsilon
Phi
Psi
Omega
ps
mp
times
div
ast
star
circ
bullet
cdot
cap
cup
uplus
sqcap
vee
wedge
setminus
wr
diamond
(?:big)?triangle.*
lhd
rhd
unlhd
unrhd
oplus
ominus
otimes
oslash
odot
bigcirc
d?dagger
amalg
leq
prec
preceq
ll
(?:sq)?su[bp]set(?:eq)?
in
vdash
geq
succ(?:eq)?
gg
ni
dashv
equiv
sim(?:eq)?
asymp
approx
cong
neq
doteq
propto
models
perp
mid
parallel
bowtie
Join
smile
frown
.*arrow
(?:long)?mapsto
.*harpoon.*
leadsto
aleph
hbar
imath
jmath
ell
wp
Re
Im
mho
prime
emptyset
nabla
surd
top
bot
angle
forall
exists
neg
flat
natural
sharp
backslash
partial
infty
Box
Diamond
triangle
clubsuit
diamondsuit
heartsuit
spadesuit
sum
prod
coprod
int
oint
big(?:sq)?c[au]p
bigvee
bigwedge
bigodot
bigotimes
bigoplus
biguplus
(?:arc)?(?:cos|sin|tan|cot)h?
csc
arg
deg
det
dim
exp
gcd
hom
inf
ker
lg
lim
liminf
limsup
ln
log
max
min
Pr
sec
sup
[Hclbkdruvt]
[`'^"~=.]
_
AMPERSAND
(SUPER|SUB)SCRIPTNB
(SUPER|SUB)SCRIPT
SQRT
SQRTNB
PERCENTAGE
DOLLAR
%%END SAFE COMMANDS

%%BEGIN TEXT COMMANDS
% Regex matching commands with a text argument (leave out the \)
addcontents.*
cc
closing
chapter
dashbox
emph
encl
fbox
framebox
footnote
footnotetext
framebox
part
(sub){0,2}section\*?
(sub)?paragraph\*?
makebox
mbox
opening
parbox
raisebox
savebox
sbox
shortstack
signature
text.*
value
underline
sqrt
(SUPER|SUB)SCRIPT
%%END TEXT COMMANDS 

%%BEGIN CONTEXT1 COMMANDS
% Regex matching commands with a text argument (leave out the \), which will fail out of context. These commands behave like text commands, except when they occur in a deleted section, where they are disabled, but their argument is shown as deleted text.
caption
%%END CONTEXT1 COMMANDS 

%%BEGIN CONTEXT2 COMMANDS
% Regex matching commands with a text argument (leave out the \), which will fail out of context.  As corresponding commands for context1.  The only difference is that context2 commands are completely disabled in deleted sections, including their arguments.
title
author
date
institute
%%END CONTEXT2 COMMANDS 

%% CONFIGURATION variabe defaults
%%BEGIN LISTENV CONFIG
itemize
description
enumerate
%%END LISTENV CONFIG

%%BEGIN FLOATENV CONFIG
figure[\w\d*@]*
table[\w\d*@]*
plate[\w\d*@]*
%%END FLOATENV CONFIG

%%BEGIN PICTUREENV CONFIG
picture[\w\d*@]*
tikzpicture[\w\d*@]*
DIFnomarkup
%%END PICTUREENV CONFIG

%%BEGIN MATHENV CONFIG
equation[*]?
displaymath
DOLLARDOLLAR
%%END MATHENV CONFIG

%%BEGIN MATHARRENV CONFIG
eqnarray[*]?
align[*]?
alignat[*]?
gather[*]?
multline[*]?
flalign[*]?
%%END MATHARRENV CONFIG

%%BEGIN ARRENV CONFIG
aligned
array
[pbvBV]?matrix
smallmatrix
cases
split
%%END ARRENV CONFIG

%%BEGIN COUNTERCMD CONFIG
footnote
part
chapter
section
subsection
subsubsection
paragraph
subparagraph
%%END COUNTERCMD CONFIG

%%BEGIN VERBATIMENV CONFIG
verbatim[*]?
lstlisting
comment
%%END VERBATIMENV CONFIG

%%% TYPES (Commands for highlighting changed blocks)

%DIF UNDERLINE PREAMBLE
\RequirePackage[normalem]{ulem}
\RequirePackage{color}\definecolor{RED}{rgb}{1,0,0}\definecolor{BLUE}{rgb}{0,0,1}
\providecommand{\DIFadd}[1]{{\protect\color{blue}\uwave{#1}}}
\providecommand{\DIFdel}[1]{{\protect\color{red}\sout{#1}}}                     
%DIF END UNDERLINE PREAMBLE

%DIF CTRADITIONAL PREAMBLE
\RequirePackage{color}\definecolor{RED}{rgb}{1,0,0}\definecolor{BLUE}{rgb}{0,0,1}
\RequirePackage[stable]{footmisc}
\DeclareOldFontCommand{\sf}{\normalfont\sffamily}{\mathsf}
\providecommand{\DIFadd}[1]{{\protect\color{blue} \sf #1}}
\providecommand{\DIFdel}[1]{{\protect\color{red} [..\footnote{removed: #1} ]}}
%DIF END CTRADITIONAL PREAMBLE

%DIF TRADITIONAL PREAMBLE
\RequirePackage[stable]{footmisc}
\DeclareOldFontCommand{\sf}{\normalfont\sffamily}{\mathsf}
\providecommand{\DIFadd}[1]{{\sf #1}}
\providecommand{\DIFdel}[1]{{[..\footnote{removed: #1} ]}}
%DIF END TRADITIONAL PREAMBLE

%DIF CFONT PREAMBLE
\RequirePackage{color}\definecolor{RED}{rgb}{1,0,0}\definecolor{BLUE}{rgb}{0,0,1}
\DeclareOldFontCommand{\sf}{\normalfont\sffamily}{\mathsf}
\providecommand{\DIFadd}[1]{{\protect\color{blue} \sf #1}}
\providecommand{\DIFdel}[1]{{\protect\color{red} \scriptsize #1}}
%DIF END CFONT PREAMBLE

%DIF FONTSTRIKE PREAMBLE
\RequirePackage[normalem]{ulem}
\DeclareOldFontCommand{\sf}{\normalfont\sffamily}{\mathsf}
\providecommand{\DIFadd}[1]{{\sf #1}}
\providecommand{\DIFdel}[1]{{\footnotesize \sout{#1}}}
%DIF END FONTSTRIKE PREAMBLE

%DIF CCHANGEBAR PREAMBLE
\RequirePackage[dvips]{changebar}
\RequirePackage{color}\definecolor{RED}{rgb}{1,0,0}\definecolor{BLUE}{rgb}{0,0,1}
\providecommand{\DIFadd}[1]{\protect\cbstart{\protect\color{blue}#1}\protect\cbend}
\providecommand{\DIFdel}[1]{\protect\cbdelete{\protect\color{red}#1}\protect\cbdelete}
%DIF END CCHANGEBAR PREAMBLE

%DIF CFONTCHBAR PREAMBLE
\RequirePackage[dvips]{changebar}
\RequirePackage{color}\definecolor{RED}{rgb}{1,0,0}\definecolor{BLUE}{rgb}{0,0,1}
\providecommand{\DIFadd}[1]{\protect\cbstart{\protect\color{blue}\sf #1}\protect\cbend}
\providecommand{\DIFdel}[1]{\protect\cbdelete{\protect\color{red}\scriptsize #1}\protect\cbdelete}
%DIF END CFONTCHBAR PREAMBLE

%DIF CULINECHBAR PREAMBLE
\RequirePackage[normalem]{ulem}
\RequirePackage[dvips]{changebar}
\RequirePackage{color}
\providecommand{\DIFadd}[1]{\protect\cbstart{\protect\color{blue}\uwave{#1}}\protect\cbend}
\providecommand{\DIFdel}[1]{\protect\cbdelete{\protect\color{red}\sout{#1}}\protect\cbdelete}
%DIF END CULINECHBAR PREAMBLE

%DIF CHANGEBAR PREAMBLE
\RequirePackage[dvips]{changebar}
\providecommand{\DIFadd}[1]{\protect\cbstart{#1}\protect\cbend}
\providecommand{\DIFdel}[1]{\protect\cbdelete}
%DIF END CHANGEBAR PREAMBLE

%DIF INVISIBLE PREAMBLE
\providecommand{\DIFadd}[1]{#1}
\providecommand{\DIFdel}[1]{}
%DIF END INVISIBLE PREAMBLE

%DIF BOLD PREAMBLE
\DeclareOldFontCommand{\bf}{\normalfont\bfseries}{\mathbf}
\providecommand{\DIFadd}[1]{{\bf #1}}
\providecommand{\DIFdel}[1]{}
%DIF END BOLD PREAMBLE

%DIF PDFCOMMENT PREAMBLE
\RequirePackage{pdfcomment} %DIF PREAMBLE
\providecommand{\DIFadd}[1]{\pdfmarkupcomment[author=ADD:,markup=Underline]{#1}{}}
\providecommand{\DIFdel}[1]{\pdfcomment[icon=Insert,author=DEL:,hspace=12pt]{#1}}
%DIF END PDFCOMMENT PREAMBLE

%% SUBTYPES (Markers for beginning and end of changed blocks)

%DIF SAFE PREAMBLE
\providecommand{\DIFaddbegin}{}
\providecommand{\DIFaddend}{}
\providecommand{\DIFdelbegin}{}
\providecommand{\DIFdelend}{}
%DIF END SAFE PREAMBLE

%DIF MARGIN PREAMBLE
\providecommand{\DIFaddbegin}{\protect\marginpar{a[}}
\providecommand{\DIFaddend}{\protect\marginpar{]}}
\providecommand{\DIFdelbegin}{\protect\marginpar{d[}}
\providecommand{\DIFdelend}{\protect\marginpar{]}}
%DIF END MARGIN PREAMBLE

%DIF DVIPSCOL PREAMBLE
%Note: only works with dvips converter
\RequirePackage{color}
\RequirePackage{dvipscol}
\providecommand{\DIFaddbegin}{\protect\nogroupcolor{blue}}
\providecommand{\DIFaddend}{\protect\nogroupcolor{black}}
\providecommand{\DIFdelbegin}{\protect\nogroupcolor{red}}
\providecommand{\DIFdelend}{\protect\nogroupcolor{black}}
%DIF END DVIPSCOL PREAMBLE

%DIF COLOR PREAMBLE
\RequirePackage{color}
\providecommand{\DIFaddbegin}{\protect\color{blue}}
\providecommand{\DIFaddend}{\protect\color{black}}
\providecommand{\DIFdelbegin}{\protect\color{red}}
\providecommand{\DIFdelend}{\protect\color{black}}
%DIF END COLOR PREAMBLE

%DIF LABEL PREAMBLE
% To show only pages with changes (pdf) (external program pdftk needs to be installed)
% (only works for simple documents with non-repeated page numbers, otherwise use ZLABEL)
% pdflatex diff.tex
% pdflatex diff.tex
%pdftk diff.pdf cat \
%`perl -lne '\
% if (m/\\newlabel{DIFchg[b](\d*)}{{.*}{(.*)}}/) { $start{$1}=$2; print $2}\
% if (m/\\newlabel{DIFchg[e](\d*)}{{.*}{(.*)}}/) { \
%      if (defined($start{$1})) { \
%         for ($j=$start{$1}; $j<=$2; $j++) {print "$j";}\
%      } else { \
%         print "$2"\
%      }\
% }' diff.aux \
% | uniq \
% | tr  \\n ' '` \
% output diff-changedpages.pdf
% To show only pages with changes (dvips/dvipdf)
% dvips -pp `\
% [ put here the perl script from above]
% | uniq | tr -s \\n ','`
\typeout{Check comments in preamble of output for instructions how to show only pages where changes have been made}
\newcount\DIFcounterb
\global\DIFcounterb 0\relax
\newcount\DIFcountere
\global\DIFcountere 0\relax
\providecommand{\DIFaddbegin}{\global\advance\DIFcounterb 1\relax\label{DIFchgb\the\DIFcounterb}}
\providecommand{\DIFaddend}{\global\advance\DIFcountere 1\relax\label{DIFchge\the\DIFcountere}}
\providecommand{\DIFdelbegin}{\global\advance\DIFcounterb 1\relax\label{DIFchgb\the\DIFcounterb}}
\providecommand{\DIFdelend}{\global\advance\DIFcountere 1\relax\label{DIFchge\the\DIFcountere}}
%DIF END LABEL PREAMBLE

%DIF ZLABEL PREAMBLE
% To show only pages with changes (pdf) (external program pdftk needs to be installed)
% (uses zref for reference to absolute page numbers)
% pdflatex diff.tex
% pdflatex diff.tex
%pdftk diff.pdf cat \
%`perl -lne 'if (m/\\zref\@newlabel{DIFchgb(\d*)}{.*\\abspage{(\d*)}}/ ) { $start{$1}=$2; print $2 } \
%  if (m/\\zref\@newlabel{DIFchge(\d*)}{.*\\abspage{(\d*)}}/) { \
%      if (defined($start{$1})) { \
%         for ($j=$start{$1}; $j<=$2; $j++) {print "$j";}\
%      } else { \
%         print "$2"\
%      }\
% }' diff.aux \
% | uniq \
% | tr  \\n ' '` \
% output diff-changedpages.pdf
% To show only pages with changes (dvips/dvipdf)
% latex diff.tex
% latex diff.tex
% dvips -pp `perl -lne 'if (m/\\newlabel{DIFchg[be]\d*}{{.*}{(.*)}}/) { print $1 }' diff.aux | uniq | tr -s \\n ','` diff.dvi 
\typeout{Check comments in preamble of output for instructions how to show only pages where changes have been made}
\usepackage[user,abspage]{zref}
\newcount\DIFcounterb
\global\DIFcounterb 0\relax
\newcount\DIFcountere
\global\DIFcountere 0\relax
\providecommand{\DIFaddbegin}{\global\advance\DIFcounterb 1\relax\zlabel{DIFchgb\the\DIFcounterb}}
\providecommand{\DIFaddend}{\global\advance\DIFcountere 1\relax\zlabel{DIFchge\the\DIFcountere}}
\providecommand{\DIFdelbegin}{\global\advance\DIFcounterb 1\relax\zlabel{DIFchgb\the\DIFcounterb}}
\providecommand{\DIFdelend}{\global\advance\DIFcountere 1\relax\zlabel{DIFchge\the\DIFcountere}}
%DIF END ZLABEL PREAMBLE

%DIF ONLYCHANGEDPAGE PREAMBLE
\RequirePackage{atbegshi}
\RequirePackage{etoolbox}
\RequirePackage{zref}
% redefine label command to write immediately to aux file - page references will be lost
\makeatletter \let\oldlabel\label% Store \label 
\renewcommand{\label}[1]{% Update \label to write to the .aux immediately 
\zref@wrapper@immediate{\oldlabel{#1}}} 
\makeatother 
\newbool{DIFkeeppage}
\newbool{DIFchange}
\boolfalse{DIFkeeppage}
\boolfalse{DIFchange}
\AtBeginShipout{%
  \ifbool{DIFkeeppage}
        {\global\boolfalse{DIFkeeppage}}  % True DIFkeeppage
         {\ifbool{DIFchange}{\global\boolfalse{DIFkeeppage}}{\global\boolfalse{DIFkeeppage}\AtBeginShipoutDiscard}} % False DIFkeeppage
}
\providecommand{\DIFaddbegin}{\global\booltrue{DIFkeeppage}\global\booltrue{DIFchange}}
\providecommand{\DIFaddend}{\global\booltrue{DIFkeeppage}\global\boolfalse{DIFchange}}
\providecommand{\DIFdelbegin}{\global\booltrue{DIFkeeppage}\global\booltrue{DIFchange}}
\providecommand{\DIFdelend}{\global\booltrue{DIFkeeppage}\global\boolfalse{DIFchange}}
%DIF END ONLYCHANGEDPAGE PREAMBLE

%% FLOAT TYPES 

%DIF FLOATSAFE PREAMBLE
\providecommand{\DIFaddFL}[1]{\DIFadd{#1}}
\providecommand{\DIFdelFL}[1]{\DIFdel{#1}}
\providecommand{\DIFaddbeginFL}{}
\providecommand{\DIFaddendFL}{}
\providecommand{\DIFdelbeginFL}{}
\providecommand{\DIFdelendFL}{}
%DIF END FLOATSAFE PREAMBLE

%DIF IDENTICAL PREAMBLE
\providecommand{\DIFaddFL}[1]{\DIFadd{#1}}
\providecommand{\DIFdelFL}[1]{\DIFdel{#1}}
\providecommand{\DIFaddbeginFL}{\DIFaddbegin}
\providecommand{\DIFaddendFL}{\DIFaddend}
\providecommand{\DIFdelbeginFL}{\DIFdelbegin}
\providecommand{\DIFdelendFL}{\DIFdelend}
%DIF END IDENTICAL PREAMBLE

%DIF TRADITIONALSAFE PREAMBLE
% procidecommand color to make this work for TRADITIONAL and CTRADITIONAL
\providecommand{\color}[1]{}
\providecommand{\DIFaddFL}[1]{\DIFadd{#1}}
\providecommand{\DIFdel}[1]{{\protect\color{red}[..{\scriptsize {removed: #1}} ]}}
\providecommand{\DIFaddbeginFL}{}
\providecommand{\DIFaddendFL}{}
\providecommand{\DIFdelbeginFL}{}
\providecommand{\DIFdelendFL}{}
%DIF END TRADITIONALSAFE PREAMBLE

% see:
%  http://tex.stackexchange.com/questions/47351/can-i-redefine-a-command-to-contain-itself 

%DIF HIGHLIGHTGRAPHICS PREAMBLE
\RequirePackage{settobox}
\RequirePackage{letltxmacro}
\newsavebox{\DIFdelgraphicsbox}
\newlength{\DIFdelgraphicswidth}
\newlength{\DIFdelgraphicsheight}
% store original definition of \includegraphics
\LetLtxMacro{\DIFOincludegraphics}{\includegraphics}
\newcommand{\DIFaddincludegraphics}[2][]{{\color{blue}\fbox{\DIFOincludegraphics[#1]{#2}}}}
\newcommand{\DIFdelincludegraphics}[2][]{%
\sbox{\DIFdelgraphicsbox}{\DIFOincludegraphics[#1]{#2}}%
\settoboxwidth{\DIFdelgraphicswidth}{\DIFdelgraphicsbox}
\settoboxtotalheight{\DIFdelgraphicsheight}{\DIFdelgraphicsbox}
\scalebox{\DIFscaledelfig}{%
\parbox[b]{\DIFdelgraphicswidth}{\usebox{\DIFdelgraphicsbox}\\[-\baselineskip] \rule{\DIFdelgraphicswidth}{0em}}\llap{\resizebox{\DIFdelgraphicswidth}{\DIFdelgraphicsheight}{%
\setlength{\unitlength}{\DIFdelgraphicswidth}%
\begin{picture}(1,1)%
\thicklines\linethickness{2pt}
{\color[rgb]{1,0,0}\put(0,0){\framebox(1,1){}}}%
{\color[rgb]{1,0,0}\put(0,0){\line( 1,1){1}}}%
{\color[rgb]{1,0,0}\put(0,1){\line(1,-1){1}}}%
\end{picture}%
}\hspace*{3pt}}}
}
\LetLtxMacro{\DIFOaddbegin}{\DIFaddbegin}
\LetLtxMacro{\DIFOaddend}{\DIFaddend}
\LetLtxMacro{\DIFOdelbegin}{\DIFdelbegin}
\LetLtxMacro{\DIFOdelend}{\DIFdelend}
\DeclareRobustCommand{\DIFaddbegin}{\DIFOaddbegin \let\includegraphics\DIFaddincludegraphics}
\DeclareRobustCommand{\DIFaddend}{\DIFOaddend \let\includegraphics\DIFOincludegraphics}
\DeclareRobustCommand{\DIFdelbegin}{\DIFOdelbegin \let\includegraphics\DIFdelincludegraphics}
\DeclareRobustCommand{\DIFdelend}{\DIFOaddend \let\includegraphics\DIFOincludegraphics}
\LetLtxMacro{\DIFOaddbeginFL}{\DIFaddbeginFL}
\LetLtxMacro{\DIFOaddendFL}{\DIFaddendFL}
\LetLtxMacro{\DIFOdelbeginFL}{\DIFdelbeginFL}
\LetLtxMacro{\DIFOdelendFL}{\DIFdelendFL}
\DeclareRobustCommand{\DIFaddbeginFL}{\DIFOaddbeginFL \let\includegraphics\DIFaddincludegraphics}
\DeclareRobustCommand{\DIFaddendFL}{\DIFOaddendFL \let\includegraphics\DIFOincludegraphics}
\DeclareRobustCommand{\DIFdelbeginFL}{\DIFOdelbeginFL \let\includegraphics\DIFdelincludegraphics}
\DeclareRobustCommand{\DIFdelendFL}{\DIFOaddendFL \let\includegraphics\DIFOincludegraphics}
%DIF END HIGHLIGHTGRAPHICS PREAMBLE

%% SPECIAL PACKAGE PREAMBLE COMMANDS

% Standard \DIFadd and \DIFdel are redefined as \DIFaddtex and \DIFdeltex
% when hyperref package is included.
%DIF HYPERREF PREAMBLE
\providecommand{\DIFadd}[1]{\texorpdfstring{\DIFaddtex{#1}}{#1}}
\providecommand{\DIFdel}[1]{\texorpdfstring{\DIFdeltex{#1}}{}}
%DIF END HYPERREF PREAMBLE

%DIF LISTINGS PREAMBLE
\lstdefinelanguage{codediff}{
  moredelim=**[is][\color{red}]{*!----}{----!*},
  moredelim=**[is][\color{blue}]{*!++++}{++++!*}
}
\lstdefinestyle{codediff}{
	belowcaptionskip=.25\baselineskip,
	language=codediff,
	basicstyle=\ttfamily,
	columns=fullflexible,
	keepspaces=true,
}
%DIF END LISTINGS PREAMBLE
