import machine
from time import sleep_ms

Enable = 0x04 #Set Entry Mode
RS = 0x01 # Register select bit
Width = 20

class lcd:
   #initializes objects and lcd
   def __init__(self, i2cParam, ADDR):
      self.i2c = i2cParam
      self.address=ADDR
      self.BKLIGHT=0x08 #Set Backlight ON
      self.lcd_write(0x03)
      self.lcd_write(0x03)
      self.lcd_write(0x03)
      self.lcd_write(0x02)

      self.lcd_write(0x20 | 0x08 | 0x04 | 0x00) #Set Functions 2Line,5x8,4Bit Mode
      self.lcd_write(0x08 | 0x04) #Turn Display On
      self.lcd_write(0x01) #Clear Screen
      self.lcd_write(0x04 | 0x02) #Set Entry Mode Left -> Right
      sleep_ms(300)

   def lcd_strobe(self, data):
      self.i2c.writeto(self.address,bytes([data | Enable | self.BKLIGHT]))
      sleep_ms(1)
      self.i2c.writeto(self.address,bytes([(data & ~Enable) | self.BKLIGHT]))
      sleep_ms(1)

   def lcd_write_four_bits(self, data):
      self.i2c.writeto(self.address,bytes([data | self.BKLIGHT]))
      self.lcd_strobe(data)

   # write a command to lcd
   def lcd_write(self, cmd, RS=0):
      self.lcd_write_four_bits(RS | (cmd & 0xF0))
      self.lcd_write_four_bits(RS | ((cmd << 4) & 0xF0))

   def set_line(self,line,col=0):
      if line == 1:
         self.lcd_write(0x80+col)
      if line == 2:
         self.lcd_write(0xC0+col)
      if line == 3:
         self.lcd_write(0x94+col)
      if line == 4:
         self.lcd_write(0xD4+col)

   def lcd_print(self, string, line=0, col=0):
      self.set_line(line,col)
      i = 1
      for char in string:
         if ((i > Width) & (line < 4)):
            line = line + 1
            self.set_line(line,0)
            i = 1
         if ((i > Width) & (line == 4)):
             break
         self.lcd_write(ord(char),RS)
         i = i + 1

   def lcd_off(self):
      self.lcd_write(0x08 | 0x00)

   def lcd_on(self):
      self.lcd_write(0x08 | 0x04)

   def lcd_clear(self):
      self.lcd_write(0x01) #Clear Screen
      self.lcd_write(0x02) #Set Home

   def lcd_backlight(self, on):
      if on:
         self.BKLIGHT=0x08
      else:
         self.BKLIGHT=0x00
         
      self.lcd_write(0)

   def lcd_create_char(self, location, charmap):
      """
      Tworzy własny znak w CGRAM.
      location: 0-7 (8 dostępnych slotów)
      charmap: lista 8 bajtów (każdy bajt = 1 wiersz, 5 bitów = piksele)
      """
      location &= 0x7  # tylko 0-7
      self.lcd_write(0x40 | (location << 3))  # Set CGRAM address
      for byte in charmap:
         self.lcd_write(byte, RS)

   def lcd_print_char(self, location, line, col):
      """Wyświetla custom znak (0-7) na pozycji line, col"""
      self.set_line(line, col)
      self.lcd_write(location, RS)
      

