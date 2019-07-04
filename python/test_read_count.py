import unittest
import spidev
import RPi.GPIO as GPIO

RESET_PIN = 12
SPI_BYTES = 12 # change this to match FPGA design
SPI_HZ = 2000000
SPI_DEV = 0
SPI_CS = 1
REG_RD_CNT = 0x7E

class SPITest(unittest.TestCase):

    def setUp(self):
        GPIO.setwarnings(False)
        GPIO.setmode(GPIO.BOARD)
        GPIO.setup(RESET_PIN, GPIO.OUT)
        GPIO.output(RESET_PIN, False)

        self.spi = spidev.SpiDev()
        self.spi.open(SPI_DEV,SPI_CS)
        self.spi.max_speed_hz=SPI_HZ
        self.spi.mode = 0
        self.spi_bytes = SPI_BYTES

    def reset(self):
        GPIO.output(RESET_PIN, True) 
        GPIO.output(RESET_PIN, False) 

    def test_read_count(self):
        self.reset()
        val = self.read_reg(REG_RD_CNT)
        self.assertEqual(val, 0)
        val = self.read_reg(REG_RD_CNT)
        self.assertEqual(val, 1)

    def read_reg(self, reg):
        data = [ reg | 0b10000000] + [0] * self.spi_bytes # set top bit for a read
        val = self.spi.xfer2(data) 
        return val[self.spi_bytes] # return last byte read

if __name__ == '__main__':
    unittest.main()
