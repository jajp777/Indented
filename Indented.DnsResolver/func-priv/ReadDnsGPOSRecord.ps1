function ReadDnsGPOSRecord {
  # .SYNOPSIS
  #   Reads properties for an GPOS record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   LONGITUDE                   /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   LATITUDE                    /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   ALTITUDE                    /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-BinaryReader containing a byte array representing a DNS resource record.
  # .PARAMETER ResourceRecord
  #   An Indented.DnsResolver.Message.ResourceRecord object created by ReadDnsResourceRecord.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-BinaryReader
  # .OUTPUTS
  #   Indented.DnsResolver.Message.ResourceRecord.GPOS
  # .LINK
  #   http://www.ietf.org/rfc/rfc1712.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("Indented.DnsResolver.Message.ResourceRecord.GPOS")
  
  # Property: Longitude
  $ResourceRecord | Add-Member Longitude -MemberType NoteProperty -Value (ReadDnsCharacterString $BinaryReader)
  # Property: Latitude
  $ResourceRecord | Add-Member Latitude -MemberType NoteProperty -Value (ReadDnsCharacterString $BinaryReader)
  # Property: Altitude
  $ResourceRecord | Add-Member Altitude -MemberType NoteProperty -Value (ReadDnsCharacterString $BinaryReader)

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2}",
      $this.Longitude,
      $this.Latitude,
      $this.Altitude)
  }
  
  return $ResourceRecord
}




