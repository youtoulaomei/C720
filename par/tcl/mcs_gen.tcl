set FILENAME  bhd_c720_top
set TARNAME  bhd_c720_top
set NORFLASH S29GL01GS11DHIV10-BPI-X16-128M

#TIME STAMP
set fp [open " TIMESTAMP.txt" w+]
set tm [clock format [clock seconds]]
puts $fp $tm
puts $fp $NORFLASH
close $fp

#FILE NAME
#file copy -force ./$FILENAME.bit ./$TARNAME.bit
#file copy -force ./$FILENAME.bin ./$TARNAME.bin
#flash config mode
set CFGMODE bpix16
#flash volume 32MBytes
set FLASHVOLUME 32
write_cfgmem -format mcs -interface $CFGMODE -size $FLASHVOLUME -loadbit "up 0x0 ./$FILENAME.bit" -force -file ./$FILENAME.mcs














