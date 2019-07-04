PROJ = spislave
PIN_DEF = icoboard.pcf
DEVICE = hx8k
PACKAGE = ct256

# $@: The filename representing the target.
# $%: The filename element of an archive member specification.
# $<: The filename of the first prerequisite.
# $?: The names of all prerequisites that are newer than the target, separated by spaces.
# $^: The filenames of all the prerequisites, separated by spaces. This list has duplicate filenames removed since for most uses, such as compiling, copying, etc., duplicates are not wanted.

SRC = top.v spi_slave.v pulse.v

all: $(PROJ).rpt $(PROJ).bin

%.blif %.json: $(SRC)
	yosys -l spislave.log -p 'synth_ice40 -top top -json spislave.json -blif $@' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --freq 30 --hx8k --asc $@ --pcf $< --json spislave.json

#%.asc: $(PIN_DEF) %.blif
#	arachne-pnr --device 8k --package $(PACKAGE) -p $^ -o $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

lint:
	verilator --lint-only top.v spi_slave.v

prog: $(PROJ).bin
	icoprog -p < $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json

.SECONDARY:
.PHONY: all prog clean
