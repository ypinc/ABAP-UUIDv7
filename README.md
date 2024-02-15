# ABAP-UUIDv7
UUIDv7 generation in ABAP

Based on the IETF Draft by Brad G. Peabody and Kyzer R. Davis
[New UUID Formats](https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-04.html)


This implementation uses 12-bit counter to resolve collisions according to Section 6.2, method 1
Single zero bit acts as a overflow safeguard, allowing to generate at least 2048 different UUIDs every millisecond

## Usage: 
Drop-in replacement of the standard cl_system_uuid=>create_uuid_x16_static( ):

`
include ypinc_uuidv7.
lv_guid = lcl_uuidv7=>get( ).
` 





