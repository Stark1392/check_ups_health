package Classes::Liebert::Components::BatterySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects("LIEBERT-GP-SYSTEM-MIB", qw(
      lgpSysState
  ));
  $self->get_snmp_objects("LIEBERT-GP-POWER-MIB", qw(
      lgpPwrBatteryTimeRemaining lgpPwrBatteryCapacityStatus lgpPwrStateInverterState
      lgpPwrStateMaintBypassBrkrState lgpPwrStateUpsOutputSource
  ));
  $self->get_snmp_tables("LIEBERT-GP-POWER-MIB", [
    ["conditions", "lgpPwrMeasurementPointTable", "Classes::Liebert::Components::BatterySubsystem::Condition"],
  ]);
}

sub check {
  my ($self) = @_;
  if (exists $self->{lgpSysState}) {
    $self->add_info(sprintf 'system state is %s', $self->{lgpSysState});
    if ($self->{lgpSysState} eq 'startUp' ||
        $self->{lgpSysState} eq 'normalOperation') {
      $self->add_ok();
    } elsif ($self->{lgpSysState} eq 'normalWithWarning') {
      $self->add_warning();
    } else {
      $self->add_critical();
    }
  }
  if (! $self->implements_mib('UPS-MIB')) {
    $self->set_thresholds( metric => 'remaining_time', warning => '15:', critical => '10:');
    if ($self->{lgpPwrBatteryTimeRemaining} == 65535) {
      $self->add_info(sprintf 'system is not capable of providing the remaining battery run time (but is not operating on battery now)');
      $self->add_ok();
    } else {
      $self->add_info(sprintf 'remaining battery run time is %.2fmin', $self->{lgpPwrBatteryTimeRemaining});
      $self->add_message($self->check_thresholds(
          value => $self->{lgpPwrBatteryTimeRemaining}, metric => 'remaining_time')
      );
      $self->add_perfdata(
          label => 'remaining_time',
          value => $self->{lgpPwrBatteryTimeRemaining},
      );
    }
    $self->add_info(sprintf 'battery capacity status is %s', $self->{lgpPwrBatteryCapacityStatus});
    if ($self->{lgpPwrBatteryCapacityStatus} eq 'batteryLow') {
      $self->add_warning();
    } elsif ($self->{lgpPwrBatteryCapacityStatus} eq 'batteryDepleted') {
      $self->add_critical();
    }
  }
}


package Classes::Liebert::Components::BatterySubsystem::Condition;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
}
