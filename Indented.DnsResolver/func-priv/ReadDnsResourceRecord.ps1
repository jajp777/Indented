function ReadDnsResourceRecord {
  # .SYNOPSIS
  #   Reads common DNS resource record fields from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   Reads a byte array in the following format:
  #
  #                                   1  1  1  1  1  1
  #     0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                      NAME                     /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      TYPE                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     CLASS                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      TTL                      |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   RDLENGTH                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
  #    /                     RDATA                     /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-BinaryReader containing a byte array representing a DNS resource record.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-BinaryReader  
  # .OUTPUTS
  #   Indented.DnsResolver.Message.ResourceRecord
  # .LINK
  #   http://www.ietf.org/rfc/rfc1035.txt

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader
  )
  
  if ($Script:IndentedDnsTCEndFound) {
    # Return $null, cannot read past the end of a truncated packet.
    return 
  }
  
  $ResourceRecord = New-Object PsObject -Property ([Ordered]@{
    Name             = "";
    TTL              = [UInt32]0;
    RecordClass      = [Indented.DnsResolver.RecordClass]::IN;
    RecordType       = [Indented.DnsResolver.RecordType]::Empty;
    RecordDataLength = 0;
    RecordData       = "";
  })
  $ResourceRecord.PsObject.TypeNames.Add("Indented.DnsResolver.Message.ResourceRecord")
  
  # Property: Name
  $ResourceRecord.Name = ConvertToDnsDomainName $BinaryReader
  
  # Test whether or not the response is complete enough to read basic fields.
  if ($BinaryReader.BaseStream.Capacity -lt ($BinaryReader.BaseStream.Position + 10)) {
    # Set a variable to globally track the state of the packet read.
    $Script:IndentedDnsTCEndFound = $true
    # Return what we know.
    return $ResourceRecord    
  }
  
  # Property: RecordType
  $ResourceRecord.RecordType = $BinaryReader.ReadBEUInt16()
  if ([Enum]::IsDefined([Indented.DnsResolver.RecordType], $ResourceRecord.RecordType)) {
    $ResourceRecord.RecordType = [Indented.DnsResolver.RecordType]$ResourceRecord.RecordType
  } else {
    $ResourceRecord.RecordType = "UNKNOWN ($($ResourceRecord.RecordType))"
  }
  # Property: RecordClass
  if ($ResourceRecord.RecordType -eq [Indented.DnsResolver.RecordType]::OPT) {
    $ResourceRecord.RecordClass = $BinaryReader.ReadBEUInt16()
  } else {
    $ResourceRecord.RecordClass = [Indented.DnsResolver.RecordClass]$BinaryReader.ReadBEUInt16()
  }
  # Property: TTL
  $ResourceRecord.TTL = $BinaryReader.ReadBEUInt32()
  # Property: RecordDataLength
  $ResourceRecord.RecordDataLength = $BinaryReader.ReadBEUInt16()
  
  # Method: ToString
  $ResourceRecord | Add-Member ToString -MemberType ScriptMethod -Force -Value {
    return [String]::Format("{0} {1} {2} {3} {4}",
      $this.Name.PadRight(29, ' '),
      $this.TTL.ToString().PadRight(10, ' '),
      $this.RecordClass.ToString().PadRight(5, ' '),
      $this.RecordType.ToString().PadRight(5, ' '),
      $this.RecordData)
  }
  
  # Mark the beginning of the RecordData
  $BinaryReader.SetPositionMarker()
  
  $Params = @{BinaryReader = $BinaryReader; ResourceRecord = $ResourceRecord}
  
  if ($BinaryReader.BaseStream.Capacity -lt ($BinaryReader.BaseStream.Position + $ResourceRecord.RecordDataLength)) {
    # Set a variable to globally track the state of the packet read.
    $Script:DnsTCEndFound = $true
    # Return what we know.
    return $ResourceRecord
  }

  # Create appropriate properties for each record type  
  switch ($ResourceRecord.RecordType) {
    ([Indented.DnsResolver.RecordType]::A)           { $ResourceRecord = ReadDnsARecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NS)          { $ResourceRecord = ReadDnsNSRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::MD)          { $ResourceRecord = ReadDnsMDRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::MF)          { $ResourceRecord = ReadDnsMFRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::CNAME)       { $ResourceRecord = ReadDnsCNAMERecord @Params; break }
    ([Indented.DnsResolver.RecordType]::SOA)         { $ResourceRecord = ReadDnsSOARecord @Params; break }
    ([Indented.DnsResolver.RecordType]::MB)          { $ResourceRecord = ReadDnsMBRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::MG)          { $ResourceRecord = ReadDnsMGRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::MR)          { $ResourceRecord = ReadDnsMRRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NULL)        { $ResourceRecord = ReadDnsNULLRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::WKS)         { $ResourceRecord = ReadDnsWKSRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::PTR)         { $ResourceRecord = ReadDnsPTRRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::HINFO)       { $ResourceRecord = ReadDnsHINFORecord @Params; break }
    ([Indented.DnsResolver.RecordType]::MINFO)       { $ResourceRecord = ReadDnsMINFORecord @Params; break }
    ([Indented.DnsResolver.RecordType]::MX)          { $ResourceRecord = ReadDnsMXRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::TXT)         { $ResourceRecord = ReadDnsTXTRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::RP)          { $ResourceRecord = ReadDnsRPRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::AFSDB)       { $ResourceRecord = ReadDnsAFSDBRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::X25)         { $ResourceRecord = ReadDnsX25Record @Params; break }
    ([Indented.DnsResolver.RecordType]::ISDN)        { $ResourceRecord = ReadDnsISDNRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::RT)          { $ResourceRecord = ReadDnsRTRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NSAP)        { $ResourceRecord = ReadDnsNSAPRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NSAPPTR)     { $ResourceRecord = ReadDnsNSAPPTRRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::SIG)         { $ResourceRecord = ReadDnsSIGRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::KEY)         { $ResourceRecord = ReadDnsKEYRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::PX)          { $ResourceRecord = ReadDnsPXRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::GPOS)        { $ResourceRecord = ReadDnsGPOSRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::AAAA)        { $ResourceRecord = ReadDnsAAAARecord @Params; break }
    ([Indented.DnsResolver.RecordType]::LOC)         { $ResourceRecord = ReadDnsLOCRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NXT)         { $ResourceRecord = ReadDnsNXTRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::EID)         { $ResourceRecord = ReadDnsEIDRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NIMLOC)      { $ResourceRecord = ReadDnsNIMLOCRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::SRV)         { $ResourceRecord = ReadDnsSRVRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::ATMA)        { $ResourceRecord = ReadDnsATMARecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NAPTR)       { $ResourceRecord = ReadDnsNAPTRRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::KX)          { $ResourceRecord = ReadDnsKXRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::CERT)        { $ResourceRecord = ReadDnsCERTRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::A6)          { $ResourceRecord = ReadDnsA6Record @Params; break }
    ([Indented.DnsResolver.RecordType]::DNAME)       { $ResourceRecord = ReadDnsDNAMERecord @Params; break }
    ([Indented.DnsResolver.RecordType]::SINK)        { $ResourceRecord = ReadDnsSINKRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::OPT)         { $ResourceRecord = ReadDnsOPTRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::APL)         { $ResourceRecord = ReadDnsAPLRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::DS)          { $ResourceRecord = ReadDnsDSRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::SSHFP)       { $ResourceRecord = ReadDnsSSHFPRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::IPSECKEY)    { $ResourceRecord = ReadDnsIPSECKEYRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::RRSIG)       { $ResourceRecord = ReadDnsRRSIGRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NSEC)        { $ResourceRecord = ReadDnsNSECRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::DNSKEY)      { $ResourceRecord = ReadDnsDNSKEYRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::DHCID)       { $ResourceRecord = ReadDnsDHCIDRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NSEC3)       { $ResourceRecord = ReadDnsNSEC3Record @Params; break }
    ([Indented.DnsResolver.RecordType]::NSEC3PARAM)  { $ResourceRecord = ReadDnsNSEC3PARAMRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::HIP)         { $ResourceRecord = ReadDnsHIPRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::NINFO)       { $ResourceRecord = ReadDnsNINFORecord @Params; break }
    ([Indented.DnsResolver.RecordType]::RKEY)        { $ResourceRecord = ReadDnsRKEYRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::SPF)         { $ResourceRecord = ReadDnsSPFRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::TKEY)        { $ResourceRecord = ReadDnsTKEYRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::TSIG)        { $ResourceRecord = ReadDnsTSIGRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::TA)          { $ResourceRecord = ReadDnsTARecord @Params; break }
    ([Indented.DnsResolver.RecordType]::DLV)         { $ResourceRecord = ReadDnsDLVRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::WINS)        { $ResourceRecord = ReadDnsWINSRecord @Params; break }
    ([Indented.DnsResolver.RecordType]::WINSR)       { $ResourceRecord = ReadDnsWINSRRecord @Params; break }
    default                                         { ReadDnsUnknownRecord @Params }
  }
  
  return $ResourceRecord
}




