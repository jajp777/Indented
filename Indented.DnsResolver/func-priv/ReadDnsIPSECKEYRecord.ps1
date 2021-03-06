function ReadDnsIPSECKEYRecord {
  # .SYNOPSIS
  #   Reads properties for an IPSECKEY record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |      PRECEDENCE       |      GATEWAYTYPE      |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       ALGORITHM       |                       /
  #    +--+--+--+--+--+--+--+--+                       /
  #    /                    GATEWAY                    /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   PUBLICKEY                   /
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
  #   Indented.DnsResolver.Message.ResourceRecord.IPSECKEY
  # .LINK
  #   http://www.ietf.org/rfc/rfc4025.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'Indented.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("Indented.DnsResolver.Message.ResourceRecord.IPSECKEY")
  
  # Property: Precedence
  $ResourceRecord | Add-Member Precedence -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: GatewayType
  $ResourceRecord | Add-Member GatewayType -MemberType NoteProperty -Value ([Indented.DnsResolver.IPSECGatewayType]$BinaryReader.ReadByte())
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([Indented.DnsResolver.IPSECAlgorithm]$BinaryReader.ReadByte())
  
  switch ($ResourceRecord.GatewayType) {
    ([Indented.DnsResolver.IPSECGatewayType]::NoGateway) {
      $Gateway = ""
      
      break
    }
    ([Indented.DnsResolver.IPSECGatewayType]::IPv4) {
      $Gateway = $BinaryReader.ReadIPv4Address()
      
      break
    }
    ([Indented.DnsResolver.IPSECGatewayType]::IPv6) {
      $Gateway = $BinaryReader.ReadIPv6Address()
      
      break
    }
    ([Indented.DnsResolver.IPSECGatewayType]::DomainName) {
      $Gateway = ConvertToDnsDomainName $BinaryReader
    
      break
    }
  }
  
  # Property: Gateway
  $ResourceRecord | Add-Member Gateway -MemberType NoteProperty -Value $Gateway
  # Property: PublicKey
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
  $Base64String = ConvertTo-String $Bytes -Base64
  $ResourceRecord | Add-Member PublicKey -MemberType NoteProperty -Value $Base64String

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format(" ( {0} {1} {2}`n" +
                     "    {3}`n" +
                     "    {4} )",
      $this.Precedence.ToString(),
      ([Byte]$this.GatewayType).ToString(),
      ([Byte]$this.Algorithm).ToString(),
      $this.Gateway,
      $this.PublicKey)
  }
  
  return $ResourceRecord
}




