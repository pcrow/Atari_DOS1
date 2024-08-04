#
# Makefile to generate different sources
# I don't expect people to actually run this, but it's here to document my
# process that I used for disassembling, modifying the syntax, and assembling.
#

all: test

dos1dos.asm: dos1_nodup.bin dos1dos.labels
	echo dos1dos.asm is now modified by hand
	# disasm --addr=0700 --noundoc --syntax=noscreencode,indent=1t --lfile=dos1dos.labels dos1_nodup.bin > dos1dos.asm

dos1dos-clean.asm: dos1dos.asm
	sed -e 's/\t...*\t.*\t/&;/' -e 's/\t=*\t[^.].*\t/&;/' -e 's/\t=* [^.].*\t/&;/' -e 's/\t[*]=.*\t/&;/' -e 's/HILO/;&/' -e 's/[.]IF/;&/' -e 's/[.]END/;&/' -e 's/[.]TITLE/;&/' -e 's/[.]PAGE/;&/' -e 's/^&/;&/' -e "s/#'\(.\)/#"'"\1"/' -e "s/'0/"'"0"/' -e "s/\t'\(.\)/\t"'"\1"/' -e 's/ASL\tA/ASL/' -e 's/LSR\tA/LSR/' -e 's/ROL\tA/ROL/' -e 's/ROR\tA/ROR/' -e 's@.dbyte\t\([^\t;]*\)@.byte (\1)/256,-256*((\1)/256)+(\1)\t;&@' dos1dos.asm > dos1dos-clean.asm

dos1dos.bin: dos1dos-clean.asm
	xa -E -XMASM -P dos1dos.lst -o dos1dos.bin dos1dos-clean.asm

test: dos1dos.bin dos1.bin
	cmp --verbose dos1_nodup.bin dos1dos.bin && echo DOS portion exact match
	cmp --verbose dos1orig.bin dos1.bin && echo Full version exact match

dos1dup-clean.asm: dos1dup.asm
	cat dos1dup.asm | sed -e 's/\t...*\t.*\t/&;/' -e 's/\t=*\t[^.].*\t/&;/' -e 's/\t[*]=.*\t/&;/' -e 's/HILO/;&/' -e 's/[.]IF/;&/' -e 's/[.]END/;&/' -e 's/[.]TITLE/;&/' -e 's/^&/;&/' -e '104,107s/^/;/' -e "s/#'\(.\)/#"'"\1"/' -e "s/'0/"'"0"/' -e 's/ASL\tA/ASL/' -e 's/PER\t/PER_\t/' -e 's/PER$$/&_/' > dos1dup-clean.asm

dos1combined.asm: dos1dos-clean.asm dos1dup-clean.asm
	cat dos1dos-clean.asm dos1dup-clean.asm > dos1combined.asm
	sed -i $$(xa -E -XMASM -o /dev/null dos1combined.asm |& grep 'Label already defined error' | sed -e 's/.*:line //' -e 's/:.*//' -e 's@.*@-e &s/^/;/@') dos1combined.asm

dos1.bin: dos1combined.asm
	xa -E -XMASM -P dos1combined.lst -o dos1.bin dos1combined.asm

dos1modified.bin: dos1modified.asm
	xa -E -XMASM -P dos1modified.lst -o dos1modified.bin dos1modified.asm
