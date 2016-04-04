# This module is designed to provide an example to fulfill
# the PoC requirements of the client.
#
# Requirements:
# - ghoneycutt/dnsclient
# - puppetlabs/ntp
# - ghoneycutt/ssh
# - ghoneycutt/pam
# - saz/rsyslog
# - thias/postfix
#
class profile::base (
  $host_hash = hiera_hash(host_hash,''),
) {

# Handle DNS
  if $::kernelrelease == '5.11' {
    #handle dns on solaris 11
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
      source => 'puppet://modules/profile/solarislogin',
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
      ensure => present',
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
    warning('This module only supports password policies for Linux and Solaris')
  }
# Handle Syslog
  if $::kernel == 'SunOS' {
    # Which file is this supposed to manage?
  }
  elsif $::kernel == 'Linux' {
    include rsyslog
  }

# Handle Postfix
  if $::kernel == 'SunOS' {
    # Need to find package for Solaris
  }
  elsif $::kernel == 'Linux' {
    include postfix::server
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
