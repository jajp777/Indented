function NewDnsMessageHeader {
  # .SYNOPSIS
  #   Creates a new DNS message header.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      ID                       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    QDCOUNT                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    ANCOUNT                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    NSCOUNT                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    ARCOUNT                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .OUTPUTS
  #   Indented.DnsResolver.Message.Header

  [CmdLetBinding()]
  param( )

  $DnsMessageHeader = New-Object PsObject -Property ([Ordered]@{
    ID      = [UInt16](Get-Random -Maximum ([Int32]([UInt16]::MaxValue)));
    QR      = [Indented.DnsResolver.QR]::Query;
    OpCode  = [Indented.DnsResolver.OpCode]0;
    Flags   = [Indented.DnsResolver.Flags]::RD;
    RCode   = [Indented.DnsResolver.RCode]0;
    QDCount = [UInt16]1;
    ANCount = [UInt16]0;
    NSCount = [UInt16]0;
    ARCount = [UInt16]0;
  })
  $DnsMessageHeader.PsObject.TypeNames.Add("Indented.DnsResolver.Message.Header")

  # Method: ToByte
  $DnsMessageHeader | Add-Member ToByte -MemberType ScriptMethod -Value {
    $Bytes = @()

    $Bytes += ConvertTo-Byte $this.ID -BigEndian

    # The UInt16 value which comprises QR, OpCode, Flags (including Z) and RCode.
    $Flags = [UInt16]([UInt16]$this.QR + [UInt16]$this.OpCode + [UInt16]$this.Flags + [UInt16]$this.RCode)
    $Bytes += ConvertTo-Byte $Flags -BigEndian

    $Bytes += ConvertTo-Byte $this.QDCount -BigEndian
    $Bytes += ConvertTo-Byte $this.ANCount -BigEndian
    $Bytes += ConvertTo-Byte $this.NSCount -BigEndian
    $Bytes += ConvertTo-Byte $this.ARCount -BigEndian

    return [Byte[]]$Bytes
  }

  # Method: ToString
  $DnsMessageHeader | Add-Member ToString -MemberType ScriptMethod -Force -Value {
    return [String]::Format("ID: {0} QR: {1} OpCode: {2} RCode: {3} Flags: {4} Query: {5} Answer: {6} Authority: {7} Additional: {8}",
      $this.ID.ToString(),
      $this.QR.ToString().ToUpper(),
      $this.OpCode.ToString().ToUpper(),
      $this.RCode.ToString().ToUpper(),
      $this.Flags,
      $this.QDCount,
      $this.ANCount,
      $this.NSCount,
      $this.ARCount)
  }

  return $DnsMessageHeader
}




