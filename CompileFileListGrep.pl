#!/bin/env perl

use Getopt::Long;
use Pod::Usage;

my $man = 0;
my $help = 0 ;
my $debug = 0;

my $logType = ""; # vcs or xrun, internal variable, set by me.

# used for log type set, need same with you script soft link name.
my $vcsProgName = "vgrep";
my $xrunProgName = "xgrep";

my $fileListPath = "./";
my $fileListName = $fileListPath.".tmpFileList.txt";
my $fileListArray;

my $compLog;
my $grepOptions;

# set your default grep options for this variable.
my $defaultGrepOptions = " --color ";

################################################################################
# main process
################################################################################

GetOptions('help|?' => \$help,
            man => \$man,
            'debug' => \$debug,
            "compLog=s" => \$compLog,
            "grepOptions=s" => \$grepOptions,
            )
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;


if (defined($compLog)) {
    if ( -r $compLog) {
        $logType = &setLogType();
        &parseCompLog($logType, $compLog, \@fileListArray);
        &writeFileList($fileListName, \@fileListArray);
    } else {
        die "\nerror: cannot read $compLog\n\n";
    }
} elsif ( -r $fileListName ) {
    &readFileList($fileListName, \@fileListArray);
} else {
    die "\ncannot read fileList, Please give me a compLog\n\n";
}

if ( $#fileListArray >= 0 ) {
    system "grep $defaultGrepOptions $grepOptions @fileListArray";
    print "\ngrep options \n\tdefault is [\033[31m$defaultGrepOptions\033[0m]\n\tuser    is [\033[31m$grepOptions\033[0m]\n\n" if $debug;
} else {
    die "\nerror: fileList is empty\n\n";
}

################################################################################
# subroutine
################################################################################

sub setLogType {
    my $_progName = `basename $0`; chomp $_progName;

    if ($_progName eq $vcsProgName) {
        return "vcs";
    } elsif ($_progName eq $xrunProgName) {
        return "xrun";
    } else {
        die "\nerror: Can not known this log type.\n\n";
    }
}

sub parseCompLog {
    my $_logType = shift;
    my $_compLog = shift;
    my $_fileLists = shift;

    open (FD, "$_compLog") or die "\nerror: $!\n\n";

    if ($_logType eq "xrun") {
        while (<FD>) {
            if (/^file: (\S+)$/) {
                push (@{$_fileLists}, $1);
            } elsif (/^Include: (\S+) \((\S+):(\d+)\)$/) {
                push (@{$_fileLists}, $1);
            }
        }
    } elsif ($_logType eq "vcs") {
        while (<FD>) {
            if (/^Parsing design file '(\S+)'$/) {
                push (@{$_fileLists}, $1);
            } elsif (/^Parsing included file '(\S+)'\.$/) {
                push (@{$_fileLists}, $1);
            }
        }
    }

    close (FD) or die "\nerror: $!\n\n";

    if ($#{$_fileLists} < 0) {
        die "\nerror: fileLists is empty, cannot get filelist from $compLog\n\n";
    }
}

sub writeFileList {
    my $_fileListName = shift;
    my $_fileLists = shift;
    open (FD, ">$_fileListName") or die "\nerror: $!\n\n";
    foreach $item (@{$_fileLists}) {
        print FD "$item\n";
    }
    close (FD) or die "\nerror: $!\n\n";
}

sub readFileList {
    my $_fileListName = shift;
    my $_fileLists = shift;
    open (FD, "$_fileListName") or die "\nerror: $!\n\n";
    while (<FD>) {
        chomp;
        push (@{$_fileLists}, $_);
    }
    close (FD) or die "\nerror: $!\n\n";
}

__END__

=head1 NAME

xgrep|vgrep - A grep wrapper to search strings from your compile file list for xrun or vcs user.

=head1 SYNOPSIS

xgrep|vgrep [options]

 Options:
   -compLog or -c       your compile log path
   -grepOptions or -g   options to grep command
   -help or -h          brief help message
   -man or -m           full documentation

=head1 OPTIONS

=over 8

=item B<-compLog or -c>

This program will parse this compile log to get file list.

=item B<-grepOptions or -g>

Options to grep command which you want.

=item B<-help or -h>

Print a brief help message and exits.

=item B<-man or -m>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<xgrep> or B<vgrep> will parse your compile log to get a file list, then search strings from files which in this list.

=head1 EXAMPLE

B<parse compile log and search>

xgrep -c xrun.log   -g ' "class uvm_component" '

B<parse compile log>

vgrep -c vcs.log

B<search strings>

xgrep -g ' -n "class uvm_component" '

=head1 COPYRIGHT

Copyright 2024 RookieICer

Email to me <Rookie_ICer@163.com>

=cut

