#!/usr/bin/perl

use warnings;
use strict;
use NetAddr::IP;

# Term::ANSIColor doesn't work on windows without Win32 Console
if( $^O eq 'MSWin32' ){{
  eval { require Win32::Console::ANSI; } or last;
}}
use Term::ANSIColor;			# I like colors
use Benchmark;					# in case we need to optimize

# start timer
my $t0 = new Benchmark;
#--------------------------------

# the database of networks we know of
my %nets = (
'10.1.0.0/16' => 'CORP WAN',
'172.28.117.0/24' => 'VLAN 388 - DMZ Servers',
'192.168.1.0/24' => 'VLAN 400 - Guest Wireless',
);

my %data;		# will contain deduped ips
my %unknowns;	# if we want to see the unknown IP, deduped
my $unknowns	= 0;	# contains unknown Ips
my $lines 		= 0;	# just a counter


# this sub converts a decimal IP to a dotted IP
sub dec2ip ($) { join '.', unpack 'C4', pack 'N', shift; }
 
# this sub converts a dotted IP to a decimal IP
sub ip2dec ($) { unpack N => pack CCCC => split /\./ => shift; }

	# build unique list from __DATA__
	while (<DATA>) {

		# tested: finds multiple (all on each line)
		if (m/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}[\/-][0-9]{1,2}|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/g) { 
			my $ip = $1;
			chomp $ip;
			$ip = ip2dec($ip);
			$data{$ip}++;
			$lines++;
		}
	}

print color ('yellow'), "
------------------
 IP to Net Mapper
------------------
Mapping $lines IP to Known Networks...

GIVEN IP\tFITS IN THIS NETWORK\n", color("reset");

	# build  network only map from input side.
	foreach my $ips (sort keys %data){
		my $found = 0;

		# build ip object
		my $ip = NetAddr::IP->new($ips);
		$ips = dec2ip($ips);

		# loop over data hash and check every key to see where it fits
		# FIXME: what happens if it fits in an overlap?
		foreach my $cidr (keys %nets) {

			# define net object
			my $network  = NetAddr::IP->new($cidr);
			if ($ip->within($network)) {

				$found++;
				print color ('green'),"$ips\t$cidr ($nets{$cidr})\n", color('reset');

			}
		}
		# these ips were not found, so... handle
		unless ($found) {
			#print "$ips\tUNKNOWN NETWORK\n";
			$unknowns++;
			$unknowns{$ips}++;
		}
	}


# we want a list to munge and parse later, give it to us
my $unique_ip = keys %data;
	if ($unknowns) {
		foreach my $unknown (sort keys %unknowns) {
		print color('red'),"$unknown\t0.0.0.0 (UNKNOWN)\n", color('reset');
	}
}

# print stats:
print color ('yellow'),"
------------------
      DONE!
------------------
     INPUT: $lines
 UNIQUE IP: $unique_ip
UNKNOWN IP: $unknowns
";


my $t1 = new Benchmark; my $td = timediff($t1,$t0);
print "\ntook '",timestr($td), "' seconds\n", color("reset");

# sample data
__DATA__
10.1.11.181
10.1.12.210
172.28.117.216
172.28.117.58
192.168.1.90
192.168.1.91
192.168.1.91
192.168.1.91
192.168.1.91
22.22.22.22