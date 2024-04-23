# GAMMA-insar

This GAMMA RS script is for DInSAR analysis for StripMap observation mode datasets

## Requirements

GAMMA Software Modules:

The GAMMA software is grouped into four main modules:
- Modular SAR Processor (MSP)
- Interferometry, Differential Interferometry and Geocoding (ISP/DIFF&GEO)
- Land Application Tools (LAT)
- Interferometric Point Target Analysis (IPTA)

The user need to install the GAMMA Remote Sensing software beforehand depending on your OS.

For more information: https://gamma-rs.ch/uploads/media/GAMMA_Software_information.pdf

## Process step

Pre-processing: input SLC datasets into "input_files_orig" dir.

Note: it should be processed orderly from the top (part_XX).

It needs to change the mark "off" to "on" when processing.

- part00_unzip="off"
- part01_makeslc="off"
- part02_convertdem="off"
- part03_regist="off"
- part04_interp="off"
- part05_orthodem="off" # you can change the oversampling values in gc_map2 command
- part06_diff="off"
- part07_filter="off"
- part08_unw="off"
- part09_ortho="off"
- part10_demaux="off"
- part11_ionospherechk="off"
