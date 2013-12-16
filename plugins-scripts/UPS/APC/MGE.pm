package UPS::APC::MGE;
our @ISA = qw(UPS::APC);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my $self = shift;
  my %params = @_;
  if (! $self->check_messages()) {
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_environmental_subsystem();
      $self->check_environmental_subsystem();
    } elsif ($self->mode =~ /device::battery/) {
      $self->analyze_battery_subsystem();
      $self->check_battery_subsystem();
    } elsif ($self->mode =~ /device::power/) {
      $self->analyze_power_subsystem();
      $self->check_power_subsystem();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      UPS::APC::MGE::Components::EnvironmentalSubsystem->new();
}

sub analyze_battery_subsystem {
  my $self = shift;
  $self->{components}->{battery_subsystem} =
      UPS::APC::MGE::Components::BatterySubsystem->new();
}
