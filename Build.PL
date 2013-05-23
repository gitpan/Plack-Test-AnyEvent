
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Run Plack::Test on AnyEvent-based PSGI applications",
  "dist_author" => [
    "Rob Hoelz <rob\@hoelz.ro>"
  ],
  "dist_name" => "Plack-Test-AnyEvent",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Plack::Test::AnyEvent",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "Plack" => 0,
    "autodie" => 0,
    "perl" => "v5.8.8"
  },
  "script_files" => [],
  "test_requires" => {
    "HTTP::Request::Common" => 0,
    "Test::Class" => 0,
    "Test::More" => 0,
    "parent" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
