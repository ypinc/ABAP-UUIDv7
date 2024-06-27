# ABAP-UUIDv7 RFC 9562
RFC9562 UUIDv7 generation in ABAP

Based on the RFC 9562 by Brad G. Peabody, Kyzer R. Davis and Paul J. Leach
[Universally Unique IDentifiers (UUIDs)](https://www.rfc-editor.org/rfc/rfc9562)


This implementation uses 12-bit counter to resolve collisions according to Section 6.2, method 1.

Single zero bit acts as an overflow safeguard, allowing to generate at least 2048 monotonically increased UUIDs every millisecond

## Usage: 
Drop-in replacement of the standard cl_system_uuid=>create_uuid_x16_static( ):

`
include ypinc_uuidv7.
lv_guid = lcl_uuidv7=>get( ).
` 





