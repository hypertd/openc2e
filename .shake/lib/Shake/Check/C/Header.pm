# vim: set ts=4 sw=4 noexpandtab si ai sta tw=100:
# This module is copyrighted, see end of file for details.
package Shake::Check::C::Header;
use strict;
use warnings;
use Fatal 'unlink';
use File::Temp 'mkstemps';
use File::Spec;
use Shake::Check;
use base 'Shake::Check';

our $VERSION = 0.01;

sub initialize {
	my ($self, $header, %args) = @_;
	$self->{header} = $header;
	$self->{cflags} = $args{cflags} || '';
	$self->{compiler} = $args{compiler} or die "Test requires a C compiler";
}

sub msg {
	my ($self) = @_;

	return "checking for $self->{header}";
}

sub can_cache { 1 }

sub shortname {
	my ($self) = @_;
	my $name = $self->{header};
	$name =~ s/\.h(pp)?$//;
	$name =~ s/[^.\w]/_/g;
	return $name;
}

sub run {
	my ($self) = @_;
	my $cc = $self->{compiler};
	my $flags = $self->{cflags};
	my $devnull = do {
		if ($^O eq 'cygwin') {
			# I smell the stench of Cygwin...
			"nul";
		} else {
			File::Spec->devnull
		}
	};
	my ($fh, $srcfile) = mkstemps("c-header-XXXXX", ".c");
	print $fh "#include <$self->{header}>\n";
	close $fh;
	my $status = system($cc, split(/\s+/, $flags), '-E', '-o', $devnull, $srcfile);
	unlink($srcfile);

	if ($status != 0) {
		return undef;
	} else {
		return "found";
	}
}

1;