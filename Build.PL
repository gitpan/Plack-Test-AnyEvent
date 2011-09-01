
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "HTTP::Request::Common" => 0,
    "Module::Build" => "0.3601",
    "Test::Class" => 0,
    "Test::More" => 0,
    "parent" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Run Plack::Test on AnyEvent-based PSGI applications",
  "dist_author" => [
    "Rob Hoelz <rob\@hoelz.ro>"
  ],
  "dist_name" => "Plack-Test-AnyEvent",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Plack::Test::AnyEvent",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "Plack" => 0,
    "autodie" => 0,
    "perl" => "5.8.8"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
