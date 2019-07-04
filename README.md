# registers not re-setting to 0 correctly

Raspberry pi reads 8 bit registers via hardware SPI from Icoboard (Lattice ICE HX8K).
FPGA SPI slave module written by Eric Brombaugh.

After a reset, read_count register is set to 0. Every read, this counter is incremented.

The test is:

* reset FPGA
* make SPI read of read_count register
* check read_count is 0

In a test of 500 repeats, 24 failed with read_count = 3, and 4 failed with read_count = 2.

# scope shots

* yellow - reset
* purple - spi clock
* green - MISO
* cyan - (read_count != 0)

## read count = 0 after reset

When read count is 0

![read count = 0](images/20190704_120019.png)

When read count is 3

![read count = 3](images/20190704_115922.png)

Close up on reset transition to low when read_count is read != 0

![reset goes low and read_count is not 0](images/20190704_120843.png)

# test results

register is read with a simple python script: [test_read_count.py](python/test_read_count.py)

    rm test.results ; for i in $(seq 500); do echo $i;  python test_read_count.py >> test.results 2>&1 ; done

    grep -i assertion test.results  | sort | uniq -c
    4 AssertionError: 2 != 0
    24 AssertionError: 3 != 0

