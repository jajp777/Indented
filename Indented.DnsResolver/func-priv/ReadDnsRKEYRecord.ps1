function ReadDnsRKEYRecord {
  # .SYNOPSIS
  #   Reads properties for an RKEY record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     FLAGS                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |        PROTOCOL       |       ALGORITHM       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                  PUBLIC KEY                   /
  #    /                                               /
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
  #   Indented.DnsResolver.Message.ResourceRecord.RKEY
  # .LINK
  #   http://tools.ietf.org/html/draft-reid-dnsext-rkey-00
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("Indented.DnsResolver.Message.ResourceRecord.RKEY")

  # Property: Flags
  $ResourceRecord | Add-Member Flags -MemberType NoteProperty -Value ($BinaryReader.ReadBEUInt16())
  # Property: Protocol
  $ResourceRecord | Add-Member Protocol -MemberType NoteProperty -Value ([Indented.DnsResolver.KEYProtocol]$BinaryReader.ReadByte())
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([Indented.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
  
  # Property: PublicKey
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
  $Base64String = ConvertTo-String $Bytes -Base64
  $ResourceRecord | Add-Member PublicKey -MemberType NoteProperty -Value $Base64String

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} ( {3} )",
      $this.Flags,
      ([Byte]$this.Protocol).ToString(),
      ([Byte]$this.Algorithm).ToString(),
      $this.PublicKey)
  }
  
  return $ResourceRecord
}




