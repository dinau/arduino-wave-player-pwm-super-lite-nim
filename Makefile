.PHONY: clean w hex

all:
	@nim make

clean:
	@nim clean

w: all
	@nim w

hex: all
	@nim hex
