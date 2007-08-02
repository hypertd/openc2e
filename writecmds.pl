#!/usr/bin/perl

use strict;
use warnings;

use YAML;
use IO::String;
use POSIX qw(strftime);

my %tdisp = (
	'float' => 'CI_NUMERIC',
	'integer' => 'CI_NUMERIC',
	'string' => 'CI_STRING',
	'agent' => 'CI_AGENT',
	'bytestring' => 'CI_BYTESTR',
	'variable' => 'CI_VARIABLE',
	'any' => 'CI_OTHER',
	'anything' => 'CI_OTHER',
	'condition' => undef,
	'comparison' => undef,
	'decimal' => 'CI_NUMERIC',
	'decimal variable' => 'CI_OTHER',
	'byte-string' => 'CI_BYTESTR',
	'label' => undef,
	'vector' => 'CI_VECTOR',
	'bareword' => 'CI_BAREWORD',
	'token' => 'CI_BAREWORD',
	'subcommand' => 'CI_SUBCOMMAND',
);

# zero-tolerance policy
$SIG{__WARN__} = sub { die $_[0] };

my $data = YAML::LoadFile($ARGV[0]);

my $disp_id = 1;
my %disp_tbl;
my @init_funcs;

print qq{// THIS IS AN AUTOMATICALLY GENERATED FILE\n};
print qq{// DO NOT EDIT\n};
print qq{// Generated at }, strftime("%c", localtime(time)), qq{\n};
print qq{\n\n};
print qq{#include <string>\n};
print qq{#include "cmddata.h"\n};
print qq{#include "caosVM.h"\n};
print qq{#include "openc2e.h"\n};
print qq{\n\n};

foreach my $variant_name (sort keys %{$data->{variants}}) {
	my $variant = $data->{variants}{$variant_name};
	for my $key (keys %$variant) {
		$variant->{$key}{key} = $key;
	}
	my @cmds = values %$variant;

	inject_ns(\@cmds);
	writelookup(\@cmds);
	checkdup(\@cmds, "$variant_name commands");
	sortname(\@cmds);

	printarr(\@cmds, $variant_name, "${variant_name}_cmds");

	printinit($variant_name, "${variant_name}_cmds");
}

printdispatch();

print "void registerAutoDelegates() {\n";
for my $f(@init_funcs) {
	print "\t$f();\n";
}
print "}\n";


exit 0;

sub printinit {
	my ($variant, $cmdarr, $exparr) = @_;
	print "static void init_$variant() {\n";
	print qq{\tdialects["$variant"] = boost::shared_ptr<Dialect>(new Dialect($cmdarr, std::string("$variant")));\n};
	print "}\n";
	push @init_funcs, "init_$variant";
}

sub printdispatch {
	print "#ifdef VCPP_BROKENNESS\n";
	print "void dispatchCAOS(class caosVM *vm, int idx) {\n";
	print "\tswitch (idx) {\n";
	for my $impl (keys %disp_tbl) {
		print "\t\tcase $disp_tbl{$impl}: vm->$impl(); break;\n";
	}
	print qq{\t\tdefault: throw caosException(std::string("Unknown dispatchCAOS index: ") + idx);\n};
	print "\t}\n";
	print "}\n";
	print "#endif\n";
}

sub writelookup {
	my $cmds = shift;

	for my $cmd (@$cmds) {
		my $prefix = 'expr ';
		if ($cmd->{type} eq 'command') {
			$prefix = 'cmd ';
		}
		$cmd->{lookup_key} = $prefix . lc($cmd->{name});
	}
}


sub printarr {
	my ($cmds, $variant, $arrname) = @_;
	my $strbuf = '';
	my $buf = IO::String->new($strbuf);
	print $buf "static const struct cmdinfo $arrname\[\] = {\n";
	my $idx = 0;
	for my $cmd (@$cmds) {
		my $argp = 'NULL';
		if (defined $cmd->{arguments}) {
			my $args = '';
			for my $arg (@{$cmd->{arguments}}) {
				my $type = $tdisp{$arg->{type}};
				if (!defined $type) {
					undef $args;
					last;
				}
				$args .= "$type, ";
			}
			if (defined $args) {
				print "static const enum ci_type ${arrname}_t_$cmd->{key}\[\] = { ";
				print $args;
				print "CI_END };\n";
				$argp = "${arrname}_t_$cmd->{key}";
			}
		}

		print $buf "\t{ // $idx $cmd->{key}\n";
		$idx++;
		
		print $buf "#ifndef VCPP_BROKENNESS\n";
		unless (defined($cmd->{implementation})) {
			$cmd->{implementation} = 'caosVM::dummy_cmd';
		}
		print $buf "\t\t&$cmd->{implementation}, // handler\n";
		print $buf "#else\n";
		unless (defined($disp_tbl{$cmd->{implementation}})) {
			$disp_tbl{$cmd->{implementation}} = $disp_id++;
		}
		printf $buf "\t\t%d, // handler_idx\n", $disp_tbl{$cmd->{implementation}};
		print $buf "#endif\n";

		print $buf qq{\t\t"$cmd->{lookup_key}", // lookup_key\n};
		print $buf qq{\t\t"$cmd->{key}", // key\n};
		print $buf qq{\t\t"}, lc $cmd->{match}, qq{", // name\n};
		print $buf qq{\t\t"$cmd->{name}", // fullname\n};
		print $buf qq{\t\t"}, cescape($cmd->{description}), qq{", // docs\n};
		print $buf "\t\t", scalar(@{$cmd->{arguments}}), ", // argc\n";
		print $buf "\t\t", ($cmd->{type} eq 'command' ? 0 : 1), ", // retc\n";
		print $buf "\t\t$argp, // argtypes\n";
		
		my $cost = $cmd->{evalcost}{$variant};
		$cost = $cmd->{evalcost}{default} unless defined $cost;
		print $buf "\t\t$cost // evalcost\n";
		print $buf "\t},\n";

	}
	print $buf "\t{ NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0 }\n";

	print $buf "};\n";
	print $strbuf;
}
sub sortname {
	my $cmds = shift;
	@$cmds = sort { $a->{lookup_key} cmp $b->{lookup_key} } @$cmds;
}

sub inject_ns {
	my $cmds = shift;
	my %ns;
	for my $cmd (@$cmds) {
		$ns{$cmd->{namespace}}++ if defined $cmd->{namespace};
	}
	for my $ns (keys %ns) {
		next if $ns eq 'face'; # hack
		my $key = 'k_' . uc $ns;
		$key =~ s/[^a-zA-Z0-9_]//g;
		push @$cmds, {
			arguments => [ {
				name => "cmd",
				type => "subcommand",
			} ],
			category => "internal",
			description => "",
			evalcost => { default => 0 },
			filename => "",
			implementation => undef,
			match => uc $ns,
			name => lc $ns,
			pragma => {},
			status => 'internal',
			key => $key,
			type => 'command',
			syntaxstring => (uc $ns) . " (command/expr) subcommand (subcommand)\n",
		};
	}
}

sub checkdup {
	my ($cmds, $desc) = @_;
	my %mark;
	for my $cmd (@$cmds) {
		if (!defined $cmd->{lookup_key}) {
			print STDERR "No name for $cmd->{key}\n";
			exit 1;
		}
		if ($mark{$cmd->{lookup_key}}++) {
			print STDERR "Duplicate command in $desc: $cmd->{lookup_key}\n";
			exit 1;
		}
	}
}



our %cescapes;
BEGIN { %cescapes = (
	"\n" => "\\n",
	"\r" => "\\r",
	"\t" => "\\t",
	"\\" => "\\\\",
	"\"" => "\\\"",
); }

sub cescape {
	my $str = shift;
	if (!defined $str) { return ""; }
	my $ces = join "", keys %cescapes;
	$str =~ s/([\Q$ces\E])/$cescapes{$1}/ge;
	return $str;
}
# vim: set noet: 
