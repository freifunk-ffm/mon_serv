#!/usr/bin/perl
use strict;
my $dir = '/var/lib/collectd/rrd';
my $pattern = "(\w+)\.nodes\.kbu\.freifunk\.net";
my $url = 'http://localhost/nodes/add_macs';


my @params = ();
opendir(DIR, $dir) or die $!;
while (my $file = readdir(DIR)) {
	if($file =~ /$pattern/){
		push(@params,"-F mac[]=$1");
	} 
}
my $param_str = join @params, " ";
print "curl $param_str $url";