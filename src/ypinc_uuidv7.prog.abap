**********************************************************************
* UUID v7 generation in ABAP. (c) Pavel Niherysh 2024
**********************************************************************
* Benefits over version 1 and version 4 of the UUID:
* 1) Monotone over time: next generated UUID is always greater than previous
* 2) Non-guessable: having several UUIDs you cannot predict the next
* 3) Ability to estimate the creation time by given UUID
*
* Usage:
*   lv_uuid = lcl_uuidv7=>get( ). " drop-in replacement of the standard
*                                 " cl_system_uuid=>create_uuid_x16_static( ).
*
* UUID v7 structure layout as per
* https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-04.html#name-uuid-version-7
*
* For collision resolution when several GUIDs are generated within 1ms,
* the 12-bit counter scheme was choosen as per Section 6.2
* To avoid overflows, most significant bit of RAND_A part is intentionally left as 0
* This allows generating at least 2048 UUIDs per millisecond.

*0                   1                   2                   3
*0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
*+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*|                           unix_ts_ms                          |
*+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*|          unix_ts_ms           |  ver  |0   rand_a / counter   |
*+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*|var|                        rand_b                             |
*+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*|                            rand_b                             |
*+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*unix_ts_ms:  48 bit big-endian unsigned Unix epoch timestamp
*ver:          4 bit UUIDv7 version set (binary 0111)
*rand_a:      12 bits pseudo-random data, MSB is zero
*counter:     12 bits counter to support UUID generation within 1ms
*var:          2 bit variant (binary 10).
*rand_b:      62 bits of pseudo-random data

class lcl_uuidv7 definition.
  public section.
    types: uuidv7 type x length 16.
    class-methods: get returning value(rv_uid7) type uuidv7.
  private section.
    constants:
      mc_epoch_date type d value '19700101',
      mc_mask_ver type x value '07', " version mask, binary 00000111
      mc_bits_ver type x value '70', " version bits, binary 11100xxx
      mc_mask_var type x value '3F', " variant mask, binary 00111111
      mc_bits_var type x value '80'. " variant bits, binary 10xxxxxx
    class-data:
      mv_irnd type i,           " index in a random buffer (read)
      mv_last type x length 16, " last generated UUID to ensure monotony
      mv_xrnd type xstring.     " 80-bytes random buffer (10x64 or 8x80 bits)
endclass.

class lcl_uuidv7 implementation.
  method get.
    data: lv_tstl type timestampl,  " current timestamp
          lv_date type d,           " current date
          lv_time type t,           " current time
          lv_msec type int8.        " milliseconds from UNIX epoch (01.01.1970)

    if mv_irnd = 0. " if we already emptied our random buffer - let's fill it again
      call function 'GENERATE_SEC_RANDOM'
      exporting length               = 80 " must divide by 8 and 10, 40 has higher overhead
      importing random               = mv_xrnd
      exceptions others              = 4.
    endif.

    get time stamp field lv_tstl.
    convert time stamp lv_tstl time zone '      ' into date lv_date time lv_time.
    lv_date = lv_date - mc_epoch_date.   " days from the epoch
    lv_msec = lv_date * 86400 + lv_time. " seconds from the epoch
    lv_msec = lv_msec * 1000 + trunc( 1000 * frac( lv_tstl ) ). " append millisecs

    rv_uid7(6) = lv_msec.                " first 48 bits of the UUIDv7 is a timestamp
    rv_uid7+6(10) = mv_xrnd+mv_irnd(10). " fill next 80 bits from our random buffer

    rv_uid7+6(1) = rv_uid7+6(1) bit-and mc_mask_ver bit-or mc_bits_ver. " set version bits 01110xxx
    rv_uid7+8(1) = rv_uid7+8(1) bit-and mc_mask_var bit-or mc_bits_var. " set variant bits 10xxxxxx

    if rv_uid7 < mv_last. " if within the same ms and generated less - increment the counter
      rv_uid7+6(2) = mv_last+6(2) + 1. " we have at least 2048 entries to generate before overflow
    endif.
    assert rv_uid7 > mv_last.
    mv_last = rv_uid7. " save generated UID to check against it next time.
    mv_irnd = ( mv_irnd + 10 ) mod 80. " calculate new offset into the random buffer - 0,10,20,..70,0,10.. etc
  endmethod.
endclass.
