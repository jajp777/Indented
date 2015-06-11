function ReadDnsTARecord {
  # .SYNOPSIS
  #   Reads properties for an DS record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    KEYTAG                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       ALGORITHM       |      DIGESTTYPE       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                    DIGEST                     /
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
  #   Indented.DnsResolver.Message.ResourceRecord.TA
  # .LINK
  #   http://tools.ietf.org/html/draft-lewis-dns-undocumented-types-01
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("Indented.DnsResolver.Message.ResourceRecord.TA")
  
  # Property: KeyTag
  $ResourceRecord | Add-Member KeyTag -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([Indented.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
  # Property: DigestType
  $ResourceRecord | Add-Member DigestType -MemberType NoteProperty -Value ([Indented.DnsResolver.DigestType]$BinaryReader.ReadByte())
  # Property: Digest
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - 4)
  $HexString = ConvertTo-String $Bytes -Hexadecimal
  $ResourceRecord | Add-Member Digest -MemberType NoteProperty -Value $HexString

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} {3}",
      $this.KeyTag.ToString(),
      ([Byte]$this.Algorithm).ToString(),
      ([Byte]$this.DigestType).ToString(),
      $this.Digest)
  }
  
  return $ResourceRecord
}




