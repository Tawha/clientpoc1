# This module is designed to provide an example to fulfill
# the PoC requirements of the client.
#
# Requirements:
# - puppetlabs/ntp
# - ghoneycutt/dnsclient
# - ghoneycutt/ssh
# - ghoneycutt/pam
# - kemra102/auditd
# - ppbrown/svcprop
# - saz/rsyslog
# - thias/postfix
#
class profile::base (
  $host_hash = hiera_hash(host_hash,''),
) {

# Handle DNS
  if $::kernelrelease == '5.11' {
    svcprop { 'Search Domain':
      fmri     => 'network/dns/client',
      property => 'config/search = astring',
      value    => 'i2cinc.com',
    }
    svcprop { 'Nameservers':
      fmri     => 'network/dns/client',
      property => 'config/nameserver = net_address',
      value    => '(8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220',
    }
  }
  else {  #possibly restrict this to just Linux and Solaris 10 and fail otherwise?
# This module handles DNS for Linux and Solaris 10
    include dnsclient
  }

# This module handles NTP for Linux, Solaris 10 and Solaris 11
  include ntp

# This module handles SSH hardening for Linux, Solaris 10 and Solaris 11
  include ssh

# Handle Password Policies
  if $::kernel == 'SunOS' {
    file { '/etc/default/passwd':
      ensure => file,
      source => 'puppet:///modules/profile/solarispasswd',
      mode   => '0644',
    }
    file { '/etc/default/login':
      ensure => file,
      source => 'puppet:///modules/profile/solarislogin',
      mode   => '0644'
    }
    file_line { 'TMOUT':
      ensure => present,
      path   => '/etc/profile',
      line   => 'TMOUT=900',
      match  => '^TMOUT',
    }
    file_line { 'UMASK':
      ensure => present,
      path   => '/etc/profile',
      line   => 'UMASK=022',
      match  => '^UMASK',
    }
    file_line { 'TCP_STRONG_ISS':
      ensure => present,
      path   => '/etc/default/inetinit',
      line   => 'TCP_STRONG_ISS=2',
      match  => '^TCP_STRONG_ISS',
    }
    file_line { 'ENABLE_NOBODY_KEYS':
      ensure => present,
      path   => '/etc/default/keyserv',
      line   => 'ENABLE_NOBODY_KEYS=NO',
      match  => '^ENABLE_NOBODY_KEYS',
    }
  }
# This module handles password policies for Linux
  elsif $::kernel == 'Linux' {
    include pam
    file { '/etc/login.defs':
      ensure => file,
      mode   => '0644',
      source => 'puppet:///modules/profile/login.defs'
    }
  }
  else {
    warning('This profile only supports password policies for Linux and Solaris')
  }
# Handle Syslog
  if $::kernel == 'SunOS' {
    file { '/etc/syslog':
      ensure => 'file',
      mode   => '0644',
      source => 'puppet:///modules/profile/solarissyslog',
      notify => Service['system-log'],
    }
    service { 'system-log':
      ensure => running,
      enable => true,
    }
  }
  elsif $::kernel == 'Linux' {
    include rsyslog
  }
  else {
    warning('This profile only supports syslog policies for Linux and Solaris')
  }

# Handle Postfix
  if $::kernel == 'SunOS' {
    # Need to find package for Solaris
  }
  elsif $::kernel == 'Linux' {
    include postfix::server
  }
  else {
    warning('This profile only supports postfix policies for Linux and Solaris')
  }

# Handle Auditing
  if $::kernel == 'SunOS' {
    # fix
  }
  elsif $::kernel == 'Linux' {
    class { 'auditd':
      space_left_action => 'syslog',
      action_mail_acct  => 'itops.apm@i2cinc.com',
    }
  }
  else {
    warning('This profile only supports audit policies for Linux and Solaris')
  }

# Handle host files
# This creates host entries for hosts listed in hiera yaml files
# in the following format:
# ---
# hiera_hash:
#   - example1.host.com: 1.2.3.4
  unless $host_hash == '' {
    create_resources(host, $host_hash)
  }
}
