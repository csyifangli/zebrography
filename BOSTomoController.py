import socket
import struct

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('10.248.51.130', 50000))
# Message: p (pins) or s (stripes) or r (rgb), width, spacing, offset, inverted
s.sendall(struct.pack('ciiii','A',1,16,0,1))
data = s.recv(32)
foo, bar, hi, bop, eoi = struct.unpack('ciiii',data)
s.close()
print 'Received', repr(foo), repr(bar), repr(hi), repr(bop), repr(eoi)
