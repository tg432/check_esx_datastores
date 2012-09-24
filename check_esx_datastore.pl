#!/usr/bin/env perl -w
# 
# Copyright 2012 Torge Gipp. 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the Free Software Foundation.

use strict; 
use warnings; 
use VMware::VIRuntime; 
use Date::Parse; 
use Getopt::Long; 
use Nagios::Plugin; 
my $warning; 
my $hostname; 
my $critical; 
my $username;
my $password;
my @warnings;
my @criticals;
# Don't verify SSL-Cert
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

my $np = Nagios::Plugin->new(
	shortname => "CHECK_ESX_DATASTORES"
);

#$np = Nagios::Plugin->new(  
#     usage => "Usage: %s  -H <host> -u <username> -p <passord>"
#       . " -c <critical>> -w <warning>",
#   );
   
# Get Commandline-Options
GetOptions ('H=s' => \$hostname, 'w=i' => \$warning, 'c=i' => \$critical, 'u=s' => \$username, 'p=s' => \$password); 

for my $var ($hostname, $warning, $critical, $username, $password) { # Die if required Variables are not defined.
    $np->nagios_die("Not properly initialized\n") unless defined($var) and length $var;
}

# Environment-Vars
$ENV{'VI_SERVER'} = $hostname; 
$ENV{'VI_USERNAME'} = $username; 
$ENV{'VI_PASSWORD'} = $password; 
Opts::parse(); 
Opts::validate(); 
Util::connect();

# Fetch all Datastores
my $datastores = Vim::find_entity_views(
    view_type => 'Datastore', );

foreach my $datas (@{$datastores}) {
	my $ds = $datas->name;
	#my $datastore_name = $datas->name;
    my $disk_capacity = $datas->summary->capacity / 1073741824;
    my $disk_free = $datas->summary->freeSpace / 1073741824;
    my $disk_uncommitted = $datas->summary->uncommitted;
    my $disk_usage =  $disk_capacity - $disk_free;
    if (defined $disk_uncommitted) {
      $disk_uncommitted /= 1073741824;
    }
    else {
      $disk_uncommitted = 0;
    }
    my $disk_provisioned = $disk_capacity - $disk_free + $disk_uncommitted;
    my ($disk_usage_percentage, $disk_percent); 
    eval { $disk_usage_percentage = $disk_usage / $disk_capacity;
      $disk_percent = $disk_usage_percentage * 100;
    };
	if ($disk_percent > $critical){
		$criticals[scalar(@criticals)] = {
			'ds' => $ds,
			'size' => $disk_capacity,
			'percent' => $disk_percent,
		}
	} elsif ($disk_percent > $warning){
		$warnings[scalar(@warnings)] = {
			'ds' => $ds,
			'size' => $disk_capacity,
			'percent' => $disk_percent,
		}
	}
}
Util::disconnect();
my $count_crit = scalar(grep {defined $_} @criticals);
my $count_warn = scalar(grep {defined $_} @warnings);
my $ecode = 0;

if ($count_warn > 0){
	map {
		printf "WARNING:\n%-20sSize: %-30s Used: %s\n",
		$_->{'ds'}, $_->{'size'}, $_->{'percent'}
	} @warnings;
	$ecode = 1;
}
if ($count_crit > 0){
	map {
		printf "CRITICAL:\n%-20sSize: %-30s Used: %s\n",
		$_->{'ds'}, $_->{'size'}, $_->{'percent'}
	} @criticals;
	$ecode = 2;
}
if ($ecode == 1){
	$np->nagios_exit(WARNING, "Speichernutzung auf Datastore > 80%");
} elsif ($ecode == 2){
	$np->nagios_exit(CRITICAL, "Speichernutzung auf Datastore > 90%");
} elsif ($ecode == 0){
	$np->nagios_exit(OK, "Ausreichend Speicherplatz vorhanden");
}else{
	$np->nagios_exit(UNKNOWN, "Status UNBEKANNT");
}
exit $ecode

