OUTDIR := output
RADIX := $(OUTDIR)/disc
BIN := $(RADIX).bin
LOADER := $(RADIX).bas
DISK := $(RADIX).dsk

SOURCES := hello.asm dma.asm
ORG := 1200

default: $(DISK)

$(BIN): $(OUTDIR) $(SOURCES)
	rasm hello.asm -o $(RADIX)

$(LOADER): $(OUTPUT)
	echo "10 MEMORY &$(ORG)\n20 LOAD \"disc.bin\", &$(ORG)\n30 CALL &$(ORG)" | perl -p -e 's/\n/\r/' > $@

$(DISK): $(BIN) $(LOADER)
	idsk $@ -n
	idsk $@ -i $(OUTDIR)/disc.bas -t 0
	idsk $@ -i $(OUTDIR)/disc.bin -t 1 -e $(ORG)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)

run: $(DISK)
	ace -autoRunFile disc.bas $(DISK)

.PHONY: clean run default

