from scapy.all import *
import random
import time

def rand_dst_ip():
  return "22.2.0.{}".format(random.randint(0, 255))

if __name__ == "__main__":
  delay = 2
  in_intf = "veth11"
  while True:
    dst_ip = rand_dst_ip()
    p = Ether(dst='aa:bb:cc:dd:ee:ff')/IP(dst=dst_ip)/UDP()
    # p = Ether(src='00:00:00:01:01:01', dst='00:00:00:02:02:02')
    sendp(p, iface=in_intf)
    time.sleep(delay)