function ReadDnsAAAARecord {
  # .SYNOPSIS
  #   Reads properties for an AAAA record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    ADDRESS                    |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-BinaryReader containing a byte array representing a DNS resource record.
  # .PARAMETER ResourceRecord
  #   An Indented.DnsResolver.Message.ResourceRecord object created by ReadDnsResourceRecord.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-BinaryReader .
  # .OUTPUTS
  #   Indented.DnsResolver.Message.ResourceRecord.AAAA
  # .LINK
  #   http://www.ietf.org/rfc/rfc3596.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )
  
  $ResourceRecord.PsObject.TypeNames.Add("Indented.DnsResolver.Message.ResourceRecord.AAAA")

  # Property: IPAddress
  $ResourceRecord | Add-Member IPAddress -MemberType NoteProperty -Value $BinaryReader.ReadIPv6Address()

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    $this.IPAddress.ToString()
  }
  
  return $ResourceRecord
}




