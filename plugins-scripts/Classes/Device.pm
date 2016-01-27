package Classes::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP);
use strict;

sub classify {
  my $self = shift;
  if (! ($self->opts->hostname || $self->opts->snmpwalk)) {
    $self->add_unknown('either specify a hostname or a snmpwalk file');
  } else {
    $self->check_snmp_and_model();
    if (! $self->check_messages()) {
      if ($self->opts->verbose && $self->opts->verbose) {
        printf "I am a %s\n", $self->{productname};
      }
      if ($self->opts->mode =~ /^my-/) {
        $self->load_my_extension();
      } elsif ($self->get_snmp_object('PowerNet-MIB', 'atsIdentModelNumber') ||
          $self->get_snmp_object('PowerNet-MIB', 'atsIdentSerialNumber')) {
        bless $self, 'Classes::APC::Powermib::ATS';
        $self->debug('using Classes::APC::Powermib::ATS');
      } elsif ($self->get_snmp_object('PowerNet-MIB', 'upsBasicIdentModel') ||
          $self->get_snmp_object('PowerNet-MIB', 'upsBasicIdentName')) {
        # upsBasicIdentModel kann auch "" sein, upsBasicIdentName
        # theoretisch auch (da r/w), aber hoffentlich nicht beide zusammen
        bless $self, 'Classes::APC::Powermib::UPS';
        $self->debug('using Classes::APC::Powermib::UPS');
      } elsif ($self->{productname} =~ /APC /) {
        bless $self, 'Classes::APC';
        $self->debug('using Classes::APC');
      } elsif ($self->implements_mib('MG-SNMP-UPS-MIB')) {
        # like XPPC, that's why UPS is now last
        bless $self, 'Classes::MerlinGerin';
        $self->debug('using Classes::MerlinGerin');
      } elsif ($self->implements_mib('UPSV4-MIB')) {
        bless $self, 'Classes::V4';
        $self->debug('using Classes::V4');
      } elsif ($self->implements_mib('XPPC-MIB')) {
        # before UPS-MIB because i found a Intelligent MSII6000 which implemented
        # both XPPC and UPS, but the latter only partial
        bless $self, 'Classes::XPPC';
        $self->debug('using Classes::XPPC');
      } elsif ($self->implements_mib('XUPS-MIB')) {
        bless $self, 'Classes::XUPS';
        $self->debug('using Classes::XUPS');
      } elsif ($self->{productname} =~ /Net Vision v6/) {
        bless $self, 'Classes::Socomec';
        $self->debug('using Classes::Socomec');
      } elsif ($self->implements_mib('UPS-MIB')) {
        bless $self, 'Classes::UPS';
        $self->debug('using Classes::UPS');
      } else {
        if (my $class = $self->discover_suitable_class()) {
          bless $self, $class;
          $self->debug('using '.$class);
        } else {
          bless $self, 'Classes::Generic';
          $self->debug('using Classes::Generic');
        }
      }
    }
  }
  return $self;
}


package Classes::Generic;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /.*/) {
    bless $self, 'Monitoring::GLPlugin::SNMP';
    $self->no_such_mode();
  }
}

