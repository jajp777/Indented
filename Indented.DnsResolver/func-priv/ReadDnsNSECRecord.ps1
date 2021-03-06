function ReadDnsNSECRecord {
  # .SYNOPSIS
  #   Reads properties for an NSEC record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   DOMAINNAME                  /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   <BIT MAP>                   /
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
  #   Indented.DnsResolver.Message.ResourceRecord.NSEC
  # .LINK
  #   http://www.ietf.org/rfc/rfc3755.txt
  #   http://www.ietf.org/rfc/rfc4034.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("Indented.DnsResolver.Message.ResourceRecord.NSEC")
  
  # Property: DomainName
  $ResourceRecord | Add-Member DomainName -MemberType NoteProperty -Value (ConvertToDnsDomainName $BinaryReader)
  # Property: RRTypeBitMap
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
  $BinaryString = ConvertTo-String $Bytes -Binary
  $ResourceRecord | Add-Member RRTypeBitMap -MemberType NoteProperty -Value $BinaryString
  # Property: RRTypes
  $ResourceRecord | Add-Member RRTypes -MemberType ScriptProperty -Value {
    $RRTypes = @()
    [Enum]::GetNames([Indented.DnsResolver.RecordType]) |
      Where-Object { [UInt16][Indented.DnsResolver.RecordType]::$_ -lt $BinaryString.Length -and 
        $BinaryString[([UInt16][Indented.DnsResolver.RecordType]::$_)] -eq '1' } |
      ForEach-Object {
        $RRTypes += [Indented.DnsResolver.RecordType]::$_
      }
    $RRTypes
  }

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2}",
      $this.DomainName,
      "$($this.RRTypes)")
  }
  
  return $ResourceRecord
}




