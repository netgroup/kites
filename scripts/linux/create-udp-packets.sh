#!/bin/sh
if [ -d "/vagrant/ext/kites/pod-shared/pod1" ] 
then
    echo "Directory /vagrant/ext/kites/pod-shared/pod1 exists." 
    cd /vagrant/ext/kites/pod-shared/pod1
else
    echo "Error: Directory /vagrant/ext/kites/pod-shared/pod1 doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/pod1"
    mkdir -p /vagrant/ext/kites/pod-shared/pod1 && cd /vagrant/ext/kites/pod-shared/pod1    
fi
echo "Creating packets for Pod1..." 
# SAME POD 100 byte
echo "{
  ${MAC_ADDR_POD_1}
  ${MAC_ADDR_POD_1}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_1},
  ${IP_1},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}
"> samePod-100byte.cfg

# SAME POD 1000 byte
echo "{
  ${MAC_ADDR_POD_1}
  ${MAC_ADDR_POD_1}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_1},
  ${IP_1},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}"> samePod-1000byte.cfg

# POD DIFFERENT NODE 100 byte
echo "{
  ${MAC_ADDR_POD_2}
  ${MAC_ADDR_POD_1}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_1},
  ${IP_2},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}"> pod1ToPod2-100byte.cfg

# POD DIFFERENT NODE 1000 byte
echo "{
  ${MAC_ADDR_POD_2}
  ${MAC_ADDR_POD_1}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_1},
  ${IP_2},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > pod1ToPod2-1000byte.cfg

# POD DIFFERENT NODE 100 byte
echo "{
  ${MAC_ADDR_POD_3}
  ${MAC_ADDR_POD_1}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_1},
  ${IP_3},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}" > pod1ToPod3-100byte.cfg

# POD DIFFERENT NODE 1000 byte
echo "{
  ${MAC_ADDR_POD_3}
  ${MAC_ADDR_POD_1}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_1},
  ${IP_3},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > pod1ToPod3-1000byte.cfg

if [ -d "/vagrant/ext/kites/pod-shared/pod2" ] 
then
    echo "Directory /vagrant/ext/kites/pod-shared/pod2 exists." 
    cd /vagrant/ext/kites/pod-shared/pod2
else
    echo "Error: Directory /vagrant/ext/kites/pod-shared/pod2 doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/pod2"
    mkdir -p /vagrant/ext/kites/pod-shared/pod2 && cd /vagrant/ext/kites/pod-shared/pod2    
fi
echo "Creating packets for Pod2..." 
# SAME POD 100 byte
echo "{
  ${MAC_ADDR_POD_2}
  ${MAC_ADDR_POD_2}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_2},
  ${IP_2},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}" > samePod-100byte.cfg

# SAME POD 1000 byte
echo "{
  ${MAC_ADDR_POD_2}
  ${MAC_ADDR_POD_2}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_2},
  ${IP_2},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > samePod-1000byte.cfg
# POD DIFFERENT NODE 100 byte
echo "{
  ${MAC_ADDR_POD_1}
  ${MAC_ADDR_POD_2}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_2},
  ${IP_1},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}" > pod2ToPod1-100byte.cfg

# POD DIFFERENT NODE 1000 byte
echo "{
  ${MAC_ADDR_POD_1}
  ${MAC_ADDR_POD_2}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_2},
  ${IP_1},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > pod2ToPod1-1000byte.cfg

# POD DIFFERENT NODE 100 byte
echo "{
  ${MAC_ADDR_POD_3}
  ${MAC_ADDR_POD_2}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_2},
  ${IP_3},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}" > pod2ToPod3-100byte.cfg

# POD DIFFERENT NODE 1000 byte
echo "{
  ${MAC_ADDR_POD_3}
  ${MAC_ADDR_POD_2}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_2},
  ${IP_3},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > pod2ToPod3-1000byte.cfg

if [ -d "/vagrant/ext/kites/pod-shared/pod3" ] 
then
    echo "Directory /vagrant/ext/kites/pod-shared/pod3 exists." 
    cd /vagrant/ext/kites/pod-shared/pod3
else
    echo "Error: Directory /vagrant/ext/kites/pod-shared/pod3 doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/pod3"
    mkdir -p /vagrant/ext/kites/pod-shared/pod3 && cd /vagrant/ext/kites/pod-shared/pod3    
fi
echo "Creating packets for Pod3..." 
# SAME POD 100 byte
echo "{
  ${MAC_ADDR_POD_3}
  ${MAC_ADDR_POD_3}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_3},
  ${IP_3},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}" > samePod-100byte.cfg

# SAME POD 1000 byte
echo "{
  ${MAC_ADDR_POD_3}
  ${MAC_ADDR_POD_3}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_3},
  ${IP_3},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > samePod-1000byte.cfg
# POD DIFFERENT NODE 100 byte
echo "{
  ${MAC_ADDR_POD_1}
  ${MAC_ADDR_POD_3}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_3},
  ${IP_1},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}" > pod3ToPod1-100byte.cfg

# POD DIFFERENT NODE 1000 byte
echo "{
  ${MAC_ADDR_POD_1}
  ${MAC_ADDR_POD_3}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_3},
  ${IP_1},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > pod3ToPod1-1000byte.cfg

# POD DIFFERENT NODE 100 byte
echo "{
  ${MAC_ADDR_POD_2}
  ${MAC_ADDR_POD_3}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_3},
  ${IP_2},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 58),
}" > pod3ToPod2-100byte.cfg

# POD DIFFERENT NODE 1000 byte
echo "{
  ${MAC_ADDR_POD_2}
  ${MAC_ADDR_POD_3}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${IP_3},
  ${IP_2},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', 958),
}" > pod3ToPod2-1000byte.cfg
