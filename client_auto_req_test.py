from scapy.all import *
import random
import time

def rand_dst_ip():
  return "22.2.{}.{}".format(random.randint(0, 255), random.randint(0, 255))

if __name__ == "__main__":
  delay = 2
  in_intf = "veth11"
  while True:
    dst_ip = rand_dst_ip()
    p = Ether()/IP(dst=dst_ip)/UDP()
    sendp(p, iface=in_intf)
    time.sleep(delay)