#!/usr/bin/perl -w


use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use File::Basename;


my %opts=();

GetOptions(\%opts, "help|h", "long-help",
	"perlbin=s", "perldoc=s", "builddir=s", "target=s", "man") or pod2usage();
pod2usage(1) if $opts{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opts{'long-help'};

=head1 NAME

gnupod_build.pl - fixup gnupod files before installing them

=head1 SYNOPSIS

gnupod_build.pl [options] <file>

 Options:
   --help            brief help message
   --perlbin         path to perl binary
   --perldoc         path to perldoc binary
   --builddir        build directory
   --target          target directory within build directory
   --man             also create man page

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--perlbin fullpath>

Change the perl binary used by all gnupod scripts
in their #! line. (default: /usr/bin/perl)

=item B<--perldoc fullpath>

Use a different perldoc program than the one in your
$PATH to generate the man pages.

=item B<--builddir path>

Use a different build directory. Default is './build'.

=item B<--target path>

Change target directory within build directory. Default is 'bin'.

=item B<--man>

Also build a man page for B<file>.

=back

=head1 DESCRIPTION

B<gnupod_build> will 'fixup' the gnupod scripts and modules in regard
to pod templates and otherwise prepare them for installation.
The result will be dumped into the build directory.
This script is licensed under the same terms as GNUpod (The GNU GPL v.2 or later...)

=head1 AUTHOR

Heinrich Langos <henrik dash gnupod at prak dot org>

=cut


unless ( defined($opts{perlbin}) ) 		{ $opts{perlbin} = '/usr/bin/perl'; };
unless ( defined($opts{perldoc}) ) 		{ $opts{perldoc} = 'perldoc'; };
unless ( defined($opts{builddir}) ) 	{ $opts{builddir} = 'build'; };
unless ( defined($opts{target}) ) 		{ $opts{target} = 'bin'; };

# Check if everything looks okay..

if (int(@ARGV) != 1 ) { die "Expected 1 arguments, got ".int(@ARGV)." instead.\n" ; }

my $SRC=$ARGV[0];

if (! -r $SRC ) { die "Can't read source file.\n" ; }

my $VINSTALL = `cat .gnupod_version`; #Version of this release

if (! $VINSTALL) { die "File .gnupod_version does not exist, did you run configure?\n" ; }


install_script($SRC , $opts{builddir}."/".$opts{target}."/".basename($SRC));

if ($opts{man}) { 
	extract_man($opts{builddir}."/".$opts{target}."/".basename($SRC), $opts{builddir}."/man/".basename($SRC).".1");}


###################################
# extract man pages from perldoc
sub extract_man {
	my($file, $dest) = @_;
	print " > $file --> $dest\n";
	# here and now generate man pages from the ncp'ed scripts
	# and put them into our own man dir so they get copied later
	system($opts{perldoc}, "--center", "User commands" , "--release", "$VINSTALL", "$file", "$dest");
	#or die("Failed to create man pages from script $file.");
}


# native (or naive? ;) ) copy
sub ncp {
	my($source, $dest) = @_;
	open(SOURCE, "$source") or die "Could not read $source: $!\n";
	open(TARGET, ">$dest") or die "Could not write $dest: $!\n";
	my $firstline=1;
	while(<SOURCE>) {
		if ($firstline == 1) {
			$_ =~ s/^#!\/usr\/bin\/perl/#!$opts{perlbin}/;
			$firstline = 0;
		}
		$_ =~ s/###__VERSION__###/$VINSTALL/;
		if (/^###___PODINSERT (.*?)___###/) {
			open(INSERT, "$1") or die "Could not read podinsert $1: $!\n";
			while (<INSERT>) {
				print TARGET $_;
			}
			close INSERT;
		} else {
			print TARGET $_;
		}
	}
	close(SOURCE); close(TARGET);
	return undef;
}


########################################################
# Install source from src/*
sub install_script {
	my ($file, $dest) = @_;
	print " > $file --> $dest\n";
	ncp($file, $dest);
	chmod(0755, $dest);
}

#sub _recmkdir {
#	my($dir) = @_;
#	my $step = undef;
#	foreach(split(/\//,$dir)) {
#		$step .= $_."/";
#		next if -e $step;
#		mkdir($step, 0755) or die "_recmkdir($dir): Failed to create $step: $!\n";
#	}
#	return $step;
#}
