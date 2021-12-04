import conf_sys

proc UART_putc(c: int8) # forward definition

when UART_INFO:
    {.compile:"xprintf.c".}
    # Use ChaN's xprintf()
    when defined(XPRINTF_FLOAT):
        let xfunc_output{.importc,used.} = UART_putc
    else:
        let xfunc_out{.importc,used.} = UART_putc

# UART functions
template TX_DATA():untyped = UDR0
template RX_DATA():untyped = UDR0

proc mBRate*(baud:uint32):uint16{.inline.} =
        (((F_CPU div 16'u32 ) div baud ) - 1'u32).uint16

template isUART0_TxRx_FIFO_empty():bool =
    (UCSR0A.v and (1 shl UDRE0)) != 0

template isUART0_Rx_complete(): bool =
    UCSR0A.bitIsSet [RXC0]

proc UART_putc(c: int8) =
    while not isUART0_TxRx_FIFO_empty():
        discard
    TX_DATA.v = c

proc UART_getc*(): uint8 =
    if isUART0_Rx_complete():
        RX_DATA.v
    else: 0'u8

proc initUart*( baudFactor :uint16 ){.inline.} =
    UBRR0H.v = baudFactor shr 8
    UBRR0L.v = baudFactor
    UCSR0B.v = (1 shl RXEN0) or (1 shl TXEN0) # enable TX,RX
    UCSR0C.v = (3 shl UCSZ00) or (0 shl USBS0) or (0 shl UPM00)



