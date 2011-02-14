#!/usr/bin/perl -w
#
# Copyright 2006-2011 Nexenta Systems, Inc.  All rights reserved.
# Use is subject to license terms.
#

# Constants for $devs array
my $VENDOR_ID		= 0;
my $DEVICE_ID		= 1;
my $SUBSYSTEM_VENDOR_ID	= 2;
my $SUBSYSTEM_ID	= 3;
my $CLASS_CODE		= 4;
my $PCICLASS_1		= 5;
my $PCICLASS_2		= 6;
my $VENDOR_NAME		= 7;
my $DEVICE_NAME		= 8;
my $CLASS_NAME		= 9;
my $DRIVER_NAME		= 10;

my @MISSING_DRIVERS = split('\n',
'pci1274,1371 audioens Solaris
pci1274,5880 audioens Solaris
pci1022,2000 pcn Solaris
pci103c,104c pcn Solaris
pci1022,2020 pcscsi Solaris
pci1014,2e chs Solaris
pci10b8,5 spwr Solaris
pci9005,cf cadp160 Solaris
pci9005,8f cadp160 Solaris
pci9005,c0 cadp160 Solaris
pci9005,80 cadp160 Solaris
pci103c,1028 hpfc Solaris
pci103c,102a hpfc Solaris
pci1148,9821 sk98sol Solaris
pci1148,9822 sk98sol Solaris
pci1148,9841 sk98sol Solaris
pci1148,9842 sk98sol Solaris
pci1148,9843 sk98sol Solaris
pci1148,9844 sk98sol Solaris
pci1148,9861 sk98sol Solaris
pci1148,9862 sk98sol Solaris
pci1259,2970 sk98sol Solaris
pci1259,2971 sk98sol Solaris
pci1259,2972 sk98sol Solaris
pci1259,2975 sk98sol Solaris
pci1259,2976 sk98sol Solaris
pci1259,2977 sk98sol Solaris
pci1148,4000 skfp Solaris
pci1148,5521 skfp Solaris
pci1148,5522 skfp Solaris
pci1148,5541 skfp Solaris
pci1148,5543 skfp Solaris
pci1148,5544 skfp Solaris
pci1148,5821 skfp Solaris
pci1148,5822 skfp Solaris
pci1148,5841 skfp Solaris
pci1148,5843 skfp Solaris
pci1148,5844 skfp Solaris
pcie11,b03b skfp Solaris
pcie11,b03c skfp Solaris
pcie11,b03d skfp Solaris
pcie11,b03e skfp Solaris
pcie11,b03f skfp Solaris
pci9005,a180 cadp Solaris
pci9005,e100 cadp Solaris
pci9005,f500 cadp Solaris
pci9005,5f cadp Solaris
pci9005,1f cadp Solaris
pci9005,a100 cadp Solaris
pci9005,2180 cadp Solaris
pcie11,a2f7 cpqhpc Solaris
pcie11,a2fa cpqhpc Solaris
pcie11,a2f8 cpqhpc Solaris
pcie11,a2f9 cpqhpc Solaris
pcie11,a0f7 cpqhpc Solaris
pci10df,f0a5 emlxs Solaris
pci10df,f800 emlxs Solaris
pci10df,f900 emlxs Solaris
pci10df,f980 emlxs Solaris
pci10df,fa00 emlxs Solaris
pci10df,fc00 emlxs Solaris
pci10df,fc10 emlxs Solaris
pci10df,fc20 emlxs Solaris
pci10df,fd00 emlxs Solaris
pci10df,fe00 emlxs Solaris
pciex10df,fc20 emlxs Solaris
pciex10df,fe00 emlxs Solaris
pci1077,2200 qlc Solaris
pci1077,2300 qlc Solaris
pci1077,2312 qlc Solaris
pci1077,132 qlc Solaris
pci1077,2422 qlc Solaris
pciex1077,2432 qlc Solaris
pci1077,2432 qlc Solaris
pci17d3,1110 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1120 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1130 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1160 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1170 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1210 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1220 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1230 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1260 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci17d3,1270 arcmsr ftp://60.248.88.208/RaidCards/AP_Drivers/Solaris/
pci14e4,1 bcme http://www.broadcom.com/
pci14e4,1644 bcme http://www.broadcom.com/
pci14e4,1645 bcme http://www.broadcom.com/
pci14e4,1646 bcme http://www.broadcom.com/
pci14e4,1647 bcme http://www.broadcom.com/
pci14e4,1648 bcme http://www.broadcom.com/
pci14e4,164d bcme http://www.broadcom.com/
pci14e4,1653 bcme http://www.broadcom.com/
pci14e4,1654 bcme http://www.broadcom.com/
pci14e4,165d bcme http://www.broadcom.com/
pci14e4,166d bcme http://www.broadcom.com/
pci14e4,1696 bcme http://www.broadcom.com/
pci14e4,16a6 bcme http://www.broadcom.com/
pci14e4,16a7 bcme http://www.broadcom.com/
pci14e4,16a8 bcme http://www.broadcom.com/
pci14e4,16c6 bcme http://www.broadcom.com/
pci14e4,16c7 bcme http://www.broadcom.com/
pci14e4,170d bcme http://www.broadcom.com/
pci14e4,1676 bcme http://www.broadcom.com/
pci14e4,167c bcme http://www.broadcom.com/
pci14e4,1677 bcme http://www.broadcom.com/
pci14e4,167d bcme http://www.broadcom.com/
pci14e4,167e bcme http://www.broadcom.com/
pci14e4,1658 bcme http://www.broadcom.com/
pci14e4,1659 bcme http://www.broadcom.com/
pci14e4,169d bcme http://www.broadcom.com/
pci14e4,16f7 bcme http://www.broadcom.com/
pci14e4,16fd bcme http://www.broadcom.com/
pci14e4,16fe bcme http://www.broadcom.com/
pci14e4,16dd bcme http://www.broadcom.com/
pci14e4,1600 bcme http://www.broadcom.com/
pci14e4,1601 bcme http://www.broadcom.com/
pci14e4,1668 bcme http://www.broadcom.com/
pci14e4,1669 bcme http://www.broadcom.com/
pci14e4,1678 bcme http://www.broadcom.com/
pci14e4,1679 bcme http://www.broadcom.com/
pci14e4,166a bcme http://www.broadcom.com/
pci14e4,166b bcme http://www.broadcom.com/
pci14e4,167b bcme http://www.broadcom.com/
pci14e4,1673 bcme http://www.broadcom.com/
pci14e4,2 bcme http://www.broadcom.com/
pci14e4,3 bcme http://www.broadcom.com/
pci14e4,5 bcme http://www.broadcom.com/
pci14e4,6 bcme http://www.broadcom.com/
pci14e4,7 bcme http://www.broadcom.com/
pci14e4,8 bcme http://www.broadcom.com/
pci14e4,8008 bcme http://www.broadcom.com/
pci14e4,8009 bcme http://www.broadcom.com/
pci14e4,9 bcme http://www.broadcom.com/
pci14e4,a bcme http://www.broadcom.com/
pci14e4,c bcme http://www.broadcom.com/
pci173b,3e8 bcme http://www.broadcom.com/
pcie11,c1 bcme http://www.broadcom.com/
pcie11,7c bcme http://www.broadcom.com/
pcie11,85 bcme http://www.broadcom.com/
pcie11,ca bcme http://www.broadcom.com/
pcie11,cb bcme http://www.broadcom.com/
pcie11,bb bcme http://www.broadcom.com/
pci1000,621 itmpt http://www.lsilogic.com
pci1000,622 itmpt http://www.lsilogic.com
pci1000,624 itmpt http://www.lsilogic.com
pci1000,626 itmpt http://www.lsilogic.com
pci1000,628 itmpt http://www.lsilogic.com
pci1000,640 itmpt http://www.lsilogic.com
pci1000,642 itmpt http://www.lsilogic.com
pci1000,646 itmpt http://www.lsilogic.com
pci1000,56 itmpt http://www.lsilogic.com
pci1000,58 itmpt http://www.lsilogic.com
pci1000,30 itmpt http://www.lsilogic.com
pci1000,50 itmpt http://www.lsilogic.com
pci1000,54 itmpt http://www.lsilogic.com
pci1148,9e00 skge http://www.skd.de/
pci1148,5021 skge http://www.skd.de/
pci1148,5041 skge http://www.skd.de/
pci1148,5043 skge http://www.skd.de/
pci1148,5051 skge http://www.skd.de/
pci1148,5061 skge http://www.skd.de/
pci1148,5071 skge http://www.skd.de/
pci1148,5081 skge http://www.skd.de/
pci1148,9821 skge http://www.skd.de/
pci1148,9822 skge http://www.skd.de/
pci1148,9841 skge http://www.skd.de/
pci1148,9842 skge http://www.skd.de/
pci1148,9843 skge http://www.skd.de/
pci1148,9844 skge http://www.skd.de/
pci1148,9861 skge http://www.skd.de/
pci1148,9862 skge http://www.skd.de/
pci1148,9871 skge http://www.skd.de/
pci1148,9872 skge http://www.skd.de/
pci1259,2970 skge http://www.skd.de/
pci1259,2971 skge http://www.skd.de/
pci1259,2972 skge http://www.skd.de/
pci1259,2975 skge http://www.skd.de/
pci1259,2976 skge http://www.skd.de/
pci1259,2977 skge http://www.skd.de/
pci1148,121 skge http://www.skd.de/
pci1148,221 skge http://www.skd.de/
pci1148,321 skge http://www.skd.de/
pci1148,421 skge http://www.skd.de/
pci1148,621 skge http://www.skd.de/
pci1148,721 skge http://www.skd.de/
pci1148,821 skge http://www.skd.de/
pci1148,921 skge http://www.skd.de/
pci1148,1121 skge http://www.skd.de/
pci1148,1221 skge http://www.skd.de/
pci1148,3221 skge http://www.skd.de/
pci1259,2916 skge http://www.skd.de/
pci1259,2973 skge http://www.skd.de/
pci1259,2974 skge http://www.skd.de/
pci11ab,4320 yukonx http://www.marvell.com
pci11ab,4340 yukonx http://www.marvell.com
pci11ab,4341 yukonx http://www.marvell.com
pci11ab,4342 yukonx http://www.marvell.com
pci11ab,4343 yukonx http://www.marvell.com
pci11ab,4344 yukonx http://www.marvell.com
pci11ab,4345 yukonx http://www.marvell.com
pci11ab,4346 yukonx http://www.marvell.com
pci11ab,4347 yukonx http://www.marvell.com
pci11ab,4350 yukonx http://www.marvell.com
pci11ab,4351 yukonx http://www.marvell.com
pci11ab,4360 yukonx http://www.marvell.com
pci11ab,4361 yukonx http://www.marvell.com
pci11ab,4362 yukonx http://www.marvell.com
');

# Devices infomation
my (@devs, $devnum);

sub remove_duplicates()
{
	my ($i, $j);

	# if vendor_id or device_id not found => delete invalid node
	if ( ! exists($devs[$devnum][$DEVICE_ID]) || ! exists($devs[$devnum][$VENDOR_ID]) ) {
		for ($j=0; $j<8; ++$j ) {
			delete $devs[$devnum][$j] ;
		}
		$devnum-- ;
		return ;
	}

	# if found duplicate, delete the latest one.
	for ($i=0; $i<$devnum; $i++) {
		if ( ($devs[$i][$VENDOR_ID] eq $devs[$devnum][$VENDOR_ID]) && 
		     ($devs[$i][$DEVICE_ID] eq $devs[$devnum][$DEVICE_ID]) ) {
			for ($j=0; $j<8; ++$j ) {
				delete $devs[$devnum][$j] ;
			}
			$devnum-- ;
			return ;
		}
	}

	return;
}

sub read_devs()
{
	my @tmp1;
	my @tmp2;
	my ($ret, $found, $pci_node, $line, $arrnum, $i);

	if (!open(FD, "prtconf -pv |")) {
		die "Internal error, could not execute prtconf!\n" ;
	}

	$devnum = 0;
	$found = 0;
	$pci_node = 0;
	while ( $line = <FD> ) {

		if ( $line =~ /^[ \t]*Node / ) { 
			$found = 1;
		}
		elsif ( $line =~ /^[ \t]*$/ ) {
			if ( $found != 0 ) {
				$found = 0;
				if ( $pci_node != 0 ) {
					$pci_node = 0;
					remove_duplicates() ;
					++$devnum;
				}
			}
		}
		elsif ( $line =~ /compatible:/ ) {
			if ( $found != 0 ) {	
				@tmp1 = split (/'/, $line);
				$arrnum = @tmp1 ;	
				for ( $i=3; $i<$arrnum; $i=$i+2) {
					if ( $tmp1[$i] =~ /pciclass/ ) {
						@tmp2 = split (/,/, $tmp1[$i]); 
						if ( !defined $devs[$devnum][$PCICLASS_1] || $devs[$devnum][$PCICLASS_1] eq "" ) {
							$devs[$devnum][$PCICLASS_1] = $tmp2[1] ;
						} else {
							$devs[$devnum][$PCICLASS_2] = $tmp2[1] ;
						}		
					}
				}
			}
		}
		elsif ( $line =~ /device-id:/ ) {
			if ( $found != 0 ) {
				$pci_node = 1 ;
				@tmp1 = split (/:  /, $line) ;
				$devs[$devnum][$DEVICE_ID] = substr($tmp1[1], 4, 4) ;
			}
		}
		elsif ( $line =~ /subsystem-id:/ ) {
			if ( $found != 0 ) {
				$pci_node = 1 ;
				@tmp1 = split (/:  /, $line) ;
				$devs[$devnum][$SUBSYSTEM_ID] = substr($tmp1[1], 4, 4) ;
			}
		}
		elsif ( $line =~ /subsystem-vendor-id:/ ) {
			if ( $found != 0 ) {
				$pci_node = 1 ;
				@tmp1 = split (/:  /, $line) ;
				$devs[$devnum][$SUBSYSTEM_VENDOR_ID] = substr($tmp1[1], 4, 4) ;
			}
		}
		elsif ( $line =~ / vendor-id:/ ) {
			if ( $found != 0 ) {
				$pci_node = 1 ;
				@tmp1 = split (/:  /, $line) ;
				$devs[$devnum][$VENDOR_ID] = substr($tmp1[1], 4, 4) ;
			}
		}
		elsif ( $line =~ /class-code:/ ) { 
			if ( $found != 0 ) {
				$pci_node = 1 ;
				@tmp1 = split (/:/, $line) ;
				my $str1 = substr($tmp1[1], 2, 4);
				my $str2 = substr($tmp1[1], 6, 4);
				$devs[$devnum][$CLASS_CODE] = $str1 . $str2 ;
			}
		}
	}

	if ( $pci_node == 1 ) {
		remove_duplicates() ;
		$devnum++;
	}

	close (FD);

	# post-processing
	for ($i=0; $i<$devnum; ++$i) {
    		my $line;

		my $vname="Unknown vendor";
		my $dname="Unknown device";

    		open(FD, "/var/lib/misc/pci.ids") or
			open(FD, "/usr/share/misc/pci.ids") or
				open(FD, "/usr/share/pci.ids") or
					die "Can not open pci.ids";
		my @lines = <FD>;
    		close (FD);

		$found = 0;
		for $line (@lines) {
			if ( $line =~ /^$devs[$i][$VENDOR_ID]/ ) {
				$vname = substr ($line, 6);
				chomp ($vname) ;
				$found = 1 ;
			}
			elsif ( $line =~ /^[0-9][a-f]*/ ) {
				if ( $found == 1 ) {
					last;
				}
			}
			elsif ( $line =~ /^\t$devs[$i][$DEVICE_ID]/ ) {
				if ( $found == 1 ) {
					$dname = substr ($line, 7);	
					chomp ($dname) ;
					last;
				}
			}
		}

		$devs[$i][$VENDOR_NAME] = $vname;
		$devs[$i][$DEVICE_NAME] = $dname;

		# nvidia nic fixups
		$devs[$i][$DEVICE_ID] =~ s/^0+//;
		if ( $devs[$i][$VENDOR_ID] eq "10de" ) {
			for ("86", "8c", "56", "57", "37", "38", "df", "1c3", "372", "373", "268", "269", "3ee", "3ef", "450", "451", "452", "453", "eb") {
				if ( $_ eq $devs[$i][$DEVICE_ID] ) {
					$devs[$i][$CLASS_CODE] = "00020000";
				}
			}
		}

		# skip bridges
		next if ($devs[$i][$CLASS_CODE] =~ /^00060[01234]|^000680|^0005|^000c05|^0008|^000380/);

		my $code_1=substr($devs[$i][$CLASS_CODE], 2, 2);
		my $code_2=substr($devs[$i][$CLASS_CODE], 4, 2);
    		my $cname="Unknown";
		if ( $code_1 eq "01" ) {
			$cname="Storage";
		} elsif ($code_1 eq "02" ) {
			$cname="Network";
		} elsif ($code_1 eq "03" ) {
			$cname="Video";
		} elsif ($code_1 eq "04" || $code_1 eq "09") {
			$cname="Multimedia";
		} elsif ($code_1 eq "0d" ) {
			$cname="Wireless";
		} elsif ($code_1 eq "0c" ) {
			if ( $code_2 eq "03" ) {
				$cname="USB";
			} elsif ( $code_2 eq "00" ) {
				$cname="Firewire";
			} elsif ( $code_2 eq "04" ) {
				$cname="Storage";
			}
		} elsif ($code_1 eq "06" ) {
			if ( $code_2 eq "07" ) {
				$cname="PCMCIA";
			}
		} elsif ($code_1 eq "07" ) {
			if ( $code_2 eq "03" ) {
				$cname="Modem";
			}
		}

		$devs[$i][$CLASS_NAME] = $cname;

		my $pci_ids = "pci$devs[$i][$VENDOR_ID]\,$devs[$i][$DEVICE_ID]";
		my $pci_ids_2 = $pci_ids; $pci_ids_2 =~ s/pci0?(.*),0?(.*)/pci$1,$2/;

		my $pciex_ids = "pciex$devs[$i][$VENDOR_ID]\,$devs[$i][$DEVICE_ID]";
		my $pciex_ids_2 = $pciex_ids; $pciex_ids_2 =~ s/pciex0?(.*),0?(.*)/pciex$1,$2/;

		my $pci_subids = '';
		my $pci_subids_2 = '';
		my $pciex_subids = '';
		my $pciex_subids_2 = '';
		my $pci_fullids = '';
		my $pci_fullids_2 = '';

		if (defined $devs[$i][$SUBSYSTEM_VENDOR_ID] && defined $devs[$i][$SUBSYSTEM_ID]) {
			$pci_subids = "pci$devs[$i][$SUBSYSTEM_VENDOR_ID]\,$devs[$i][$SUBSYSTEM_ID]";
			$pci_subids_2 = $pci_subids; $pci_subids_2 =~ s/pci0?(.*),0?(.*)/pci$1,$2/;

			$pciex_subids = "pciex$devs[$i][$SUBSYSTEM_VENDOR_ID]\,$devs[$i][$SUBSYSTEM_ID]";
			$pciex_subids_2 = $pciex_subids; $pciex_subids_2 =~ s/pciex0?(.*),0?(.*)/pciex$1,$2/;

			$pci_fullids = "pci$devs[$i][$VENDOR_ID]\,$devs[$i][$DEVICE_ID]\.$devs[$i][$SUBSYSTEM_VENDOR_ID]\.$devs[$i][$SUBSYSTEM_ID]";
			$pci_fullids_2 = $pci_fullids; $pci_fullids_2 =~ s/pci0?(.*),0?(.*)\.0?(.*)\.0?(.*)/pci$1,$2.$3.$4/;
		}

		my $pciclass_1 = substr($devs[$i][$CLASS_CODE], 2);
		$pciclass_1 = "pciclass,$pciclass_1";

		my $pciclass_2 = substr($devs[$i][$CLASS_CODE], 2, 4);
		$pciclass_2 = "pciclass,$pciclass_2";

		unless (open (FD, "/etc/driver_aliases")) {
			die "Error: cannot open file: /etc/driver_aliases\n";
		}

		my $drvname;
		@lines = <FD>;
		close (FD);

		for $line (@lines) {
			chomp ($line);

			($drvname) = $line =~ /^(\S+)\s+\"$pci_ids(\.\d+)?\"/;
			($drvname) = $line =~ /^(\S+)\s+\"$pci_ids_2(\.\d+)?\"/ if (!defined $drvname);

			($drvname) = $line =~ /^(\S+)\s+\"$pciex_ids(\.\d+)?\"/ if (!defined $drvname);
			($drvname) = $line =~ /^(\S+)\s+\"$pciex_ids_2(\.\d+)?\"/ if (!defined $drvname);

			($drvname) = $line =~ /^(\S+)\s+\"$pci_subids\"/ if (!defined $drvname);
			($drvname) = $line =~ /^(\S+)\s+\"$pci_subids_2\"/ if (!defined $drvname);

			($drvname) = $line =~ /^(\S+)\s+\"$pciex_subids\"/ if (!defined $drvname);
			($drvname) = $line =~ /^(\S+)\s+\"$pciex_subids_2\"/ if (!defined $drvname);

			($drvname) = $line =~ /^(\S+)\s+\"$pci_fullids\"/ if (!defined $drvname);
			($drvname) = $line =~ /^(\S+)\s+\"$pci_fullids_2\"/ if (!defined $drvname);

			($drvname) = $line =~ /^(\S+)\s+\"$pciclass_1\"/ if (!defined $drvname);
			($drvname) = $line =~ /^(\S+)\s+\"$pciclass_2\"/ if (!defined $drvname);

			if (defined $drvname) {
				if ( $line =~ /^pciclass,0180/ ) { # fixups
					if ( $devs[$i][$VENDOR_ID] != 1095 or not $devs[$i][$DEVICE_ID] =~ /3112|3114|3512/ ) {
						$drvname = undef;
						next ;
					}
				}
				last;
			}
		}

		if (!defined $drvname) {
			$drvname = "pci-ide" if ($pciclass_1 =~ /pciclass,0101/ || $pciclass_1 =~ /pciclass,0180/ ||
						 $pciclass_2 =~ /pciclass,0101/ || $pciclass_2 =~ /pciclass,0180/);
		}

		$devs[$i][$DRIVER_NAME] = defined $drvname ? $drvname : '';
	}
}

sub usage_d {
	my ($errmsg) = @_;
	print "Error: $errmsg\n" if ($errmsg);
	print <<EOF;
Usage: hwdisco -d '"pci#,#" "pci#,#" ...' <32bit-drv> [64bit-drv] [config]

   pci#,#	PCI/PCIe/PC-X ids to bind with the driver. Example:
                '"pcie11,85" "pcie11,ca"'

   32bit-drv	32-bit driver binary file name. Required and must be
                locally available. Read /DRIVER-INSTALL.txt for more
                details on how it could be copied over, etc

   64bit-drv	64-bit driver binary file name. Optional. Must be locally
                available if specified

   config       driver configuration file. Optional. Must be locally
                available if specified

Enable third-party driver. Kernel module installation will be attempted and
installer will be prepared to make sure the driver will be enabled after
installation is completed.
EOF
	exit 1;
}

sub usage_p {
	my ($errmsg) = @_;
	print "Error: $errmsg\n" if ($errmsg);
	print <<EOF;
Usage: hwdisco -p <SVR4-package>

   SVR4-pacakge		SVR4 compliant package file name. Must be locally
                        available. Read /DRIVER-INSTALL.txt for more
                        details on how it could be copied over, etc

Enable third-party driver. SVR4 compliant package installation will be
attempted at installation time.
EOF
	exit 1;
}

if (defined $ARGV[0] && $ARGV[0] eq "-p") {
	my ($pkg) = ($ARGV[1]);
	usage_p("At least SVR4-package must be specified") if (!$pkg);
	usage_p("No $pkg file found") if (! -f $pkg);
	my ($pkgname) = $pkg =~ /\/?(\S+)$/;
	my $dest = "/.drv-queue";
	print "Queueing $pkgname package-installation job for Nexenta installer ...\n";
	system("mkdir -p $dest/var/tmp 2>/dev/null");
	system("cp -f $pkg $dest/var/tmp");
	system("echo pkgadd -d /var/tmp/$pkg >> $dest/queue");
	print "New job successfully queued. Verify content of $dest/queue.\n";
	exit 0;
}

if (defined $ARGV[0] && $ARGV[0] eq "-d") {
	my ($pciids, $drv1, $drv2, $cfg) = ($ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4]);
	usage_d("At least PCI ids and 32bit driver must be specified") if (!$pciids || !$drv1);
	usage_d("No $drv1 file found") if (! -f $drv1);
	usage_d("No $drv2 file found") if ($drv2 && ! -f $drv2);
	usage_d("No $cfg file found") if ($cfg && ! -f $cfg);
	my ($drv) = $drv1 =~ /\/?(\S+)$/;
	print "Enabling driver $drv. Please wait ...\n";
	system("cp -f $drv1 /kernel/drv");
	system("cp -f $cfg /kernel/drv") if ($cfg);
	system("rem_drv $drv 2>/dev/null");
	if (system("add_drv -i '$pciids' -m '* 0644 root sys' $drv") != 0) {
		print "Error: unable to add driver to the system\n";
		exit 1;
	}
	print "Successfully enabled:\n";
	system("modinfo | egrep ' $drv '");
	my $dest = "/.drv-queue";
	print "Queueing $drv driver-installation job for Nexenta installer ...\n";
	mkdir $dest if (! -d $dest);
	system("mkdir -p $dest/kernel/drv/amd64 2>/dev/null");
	system("cp -f $drv1 $dest/kernel/drv");
	system("cp -f $drv2 $dest/kernel/drv/amd64") if ($drv2);
	system("cp -f $cfg $dest/kernel/drv") if ($cfg);
	my $queue_cmd = "add_drv -b /etc/.. -i '$pciids' -m '* 0644 root sys' $drv";
	$queue_cmd =~ s/\"/\\\"/g;
	$queue_cmd =~ s/\'/\\\'/g;
	system("echo rem_drv $drv 2\\\>/dev/null >> $dest/queue");
	system("echo $queue_cmd >> $dest/queue");
	print "New job successfully queued. Verify content of $dest/queue.\n";
	exit 0;
}

read_devs();

if (defined $ARGV[0] && $ARGV[0] eq "-a") {
	printf "%-12s %-10s %s\n", "TYPE", "DRIVER", "DEVICE NAME";
	printf "============ ========== =================================================\n";
	for ($i=0; $i<$devnum; ++$i) {
		next if (!defined $devs[$i][$CLASS_NAME]);
		if ($devs[$i][$DRIVER_NAME] eq '') {
			printf "%-12s %-10s %s\n", $devs[$i][$CLASS_NAME], "Unknown", $devs[$i][$DEVICE_NAME];
		} else {
			printf "%-12s %-10s %s\n", $devs[$i][$CLASS_NAME], $devs[$i][$DRIVER_NAME], $devs[$i][$DEVICE_NAME];
		}
	}
	exit 0;
}

my $i;
my $have_unknown = 0;
for ($i=0; $i<$devnum; ++$i) {
	next if (!defined $devs[$i][$CLASS_NAME]);
	$have_unknown = 1 if ($devs[$i][$DRIVER_NAME] eq '');
}

if ($have_unknown) {
	printf "%-12s %s\n", "TYPE", "DEVICE NAME/REASON";
	printf "============ ==========================================================\n";
	for ($i=0; $i<$devnum; ++$i) {
		next if (!defined $devs[$i][$CLASS_NAME]);
		if ($devs[$i][$DRIVER_NAME] eq '') {
			my $pci_ids = "pci$devs[$i][$VENDOR_ID]\,$devs[$i][$DEVICE_ID]";

			printf "%-12s %s\n", $devs[$i][$CLASS_NAME], $devs[$i][$DEVICE_NAME];

			my ($loc, $drv);
			for my $line (@MISSING_DRIVERS) {
				if ($line =~ /^$pci_ids\s+(\S+)\s+(\S+)/) {
					$drv = $1;
					$loc = $2;
					last;
				}
			}

			if (defined $loc) {
				$loc = "http://www.sun.com" if ($loc eq "Solaris");
				printf "%-13s%s", "", "Driver '$drv' for device '$pci_ids' is not currently\n";
				printf "%-13s%s", "", "available. The driver can be downloaded from $loc.\n";
			} else {
				printf "%-13s%s", "", "Driver for device '$pci_ids' is not available.\n";
			}
		}
	}
	exit 1;
}

exit 0;
